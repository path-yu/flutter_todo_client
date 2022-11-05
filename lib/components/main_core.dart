import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';
import 'package:todo_client/common/buildScaleAnimatedSwitcher.dart';
import 'package:todo_client/main.dart';
import 'package:todo_client/state/mainStore.dart';

class MainCore extends StatefulWidget {
  const MainCore({Key? key}) : super(key: key);

  @override
  State<MainCore> createState() => _MainCoreState();
}

enum TodoType { urgent, important, normal }

String urgentStr = getEnumTwoString(TodoType.urgent);
String importantStr = getEnumTwoString(TodoType.important);
String normalStr = getEnumTwoString(TodoType.normal);
String getEnumTwoString(TodoType type) {
  return type.toString().split('.')[1];
}

class TodoItem {
  late String title;
  late String updateTime;
  late bool checked;
  late String type;
  late bool selected;
  late AnimationController controller;
  late Animation<double> animation;
  TodoItem({
    required this.title,
    required this.updateTime,
    required this.type,
    required this.selected,
    required this.controller,
    required this.animation,
    this.checked = true,
  });

  //将json 序列化为model对象
  TodoItem.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    updateTime = json['updateTime'];
    checked = json['checked'];
    selected = json['selected'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['updateTime'] = updateTime;
    data['checked'] = checked;
    data['type'] = type;
    data['selected'] = selected;
    return data;
  }
}

enum TodoItemFilterType { all, active, compete }

Map<int, TodoItemFilterType> todoItemFilterTypeIndexMap = {
  0: TodoItemFilterType.all,
  1: TodoItemFilterType.active,
  2: TodoItemFilterType.compete,
};

class _MainCoreState extends State<MainCore> with TickerProviderStateMixin {
  String title = '';
  List<TodoItem> todoList = [];
  List<TodoItem> selectTodoListList = [];
  TodoType? inputTodoType = TodoType.normal;
  TodoType? tabTodoType = TodoType.normal;
  TodoItemFilterType filterType = TodoItemFilterType.all;
  late TabController _tabController;

  late final AnimationController _controller = AnimationController(
    duration: _duration,
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.linear,
  );
  // 是否多选
  bool showMultiple = false;
  // 多选菜单CheckBox
  bool multipleChecked = false;
  final Duration _duration = const Duration(milliseconds: 300);
  List<TodoItem> get completeTodoList =>
      todoList.where((element) => element.checked).toList();
  List<TodoItem> get activeTodoList =>
      todoList.where((element) => !element.checked).toList();
  final TextEditingController _tittleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  static const List<Tab> typeTabs = <Tab>[
    Tab(text: 'normal'),
    Tab(text: 'important'),
    Tab(text: 'urgent'),
    Tab(text: 'all'),
  ];
  Map<int, TodoType> tabIndexTypeMap = {
    0: TodoType.normal,
    1: TodoType.important,
    2: TodoType.urgent,
  };
  void handleAddClick() {
    if (title.isEmpty) return;
    var controller = _createAnimationController();
    TodoItem item = TodoItem(
        title: title,
        updateTime: getCurrentTime(),
        checked: false,
        selected: false,
        controller: controller,
        animation: _createAnimation(controller),
        type: inputTodoType.toString());
    setState(() {
      todoList.add(item);
      title = "";
    });
    item.controller.reset();
    item.controller.forward();
    _tittleController.clear();
    _descriptionController.clear();
    setPrefsTodoList();
  }

  String getCurrentTime() {
    DateTime now = DateTime.now();
    // 储存当前时间并格式化
    return formatDate(now, [yyyy, '-', mm, '-', dd]);
  }

  @override
  void initState() {
    super.initState();
    init();
    final window = WidgetsBinding.instance.window;
    window.onPlatformBrightnessChanged = () {
      context.read<MainStore>().changeTheme(window.platformBrightness);
    };
    _tabController =
        TabController(vsync: this, length: typeTabs.length, initialIndex: 0);
    _tabController.addListener(handleListenerTabsController);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    for (var element in todoList) {
      element.controller.dispose();
    }
    _controller.dispose();
  }

  AnimationController _createAnimationController() {
    return AnimationController(
      duration: _duration,
      vsync: this,
    );
  }

  Animation<double> _createAnimation(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  void handleListenerTabsController() {
    setState(() {
      tabTodoType = tabIndexTypeMap[_tabController.index];
    });
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? items = prefs.getStringList('todoList');
    if (items != null) {
      setState(() {
        todoList =
            items.map((item) => TodoItem.fromJson(json.decode(item))).toList();
        for (var element in todoList) {
          var controller = _createAnimationController();
          element.controller = controller;
          element.animation = _createAnimation(controller);
        }
        for (var element in todoList) {
          element.controller.forward();
        }
      });
    }
  }

  void setPrefsTodoList() async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('todoList',
          todoList.map((item) => json.encode(item.toJson())).toList());
    });
  }

  int getTodoItemIndex(TodoItem item) {
    return todoList.indexOf(item);
  }

  void handleEditPressed(int index, List<TodoItem> list) {
    TodoItem current = list[index];
    String editTitle = current.title;
    var titleDecoration =
        _titleInputDecoration.copyWith(border: const UnderlineInputBorder());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change todo'),
        content: Form(
          autovalidateMode: AutovalidateMode.always,
          child: Wrap(
            spacing: 10,
            children: [
              TextFormField(
                initialValue: editTitle,
                onChanged: (value) => editTitle = value,
                decoration: titleDecoration,
                // decoration: titleDecoration,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'OK');
              setState(() {
                int index = todoList.indexOf(current);
                todoList[index].title = editTitle;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void handleAddPressClick() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add todo'),
            IconButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                icon: const Opacity(
                  opacity: 0.5,
                  child: Icon(
                    Icons.close,
                  ),
                ))
          ],
        ),
        content: StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _tittleController,
                  decoration: _titleInputDecoration,
                  onChanged: (value) => setState(() => title = value),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      handleAddClick();
                    }
                  },
                ),
                space,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio(
                            value: TodoType.normal,
                            groupValue: inputTodoType,
                            onChanged: (TodoType? value) {
                              setState(() {
                                inputTodoType = value;
                              });
                            }),
                        const Text('normal'),
                        Radio(
                            value: TodoType.important,
                            groupValue: inputTodoType,
                            onChanged: (TodoType? value) {
                              setState(() {
                                inputTodoType = value;
                              });
                            }),
                        const Text('important'),
                        Radio(
                            value: TodoType.urgent,
                            groupValue: inputTodoType,
                            onChanged: (TodoType? value) {
                              setState(() {
                                inputTodoType = value;
                              });
                            }),
                        const Text('urgent'),
                      ],
                    ),
                    const SizedBox(
                      width: 25,
                    ),
                    ElevatedButton(
                      onPressed: title.isNotEmpty ? handleAddClick : null,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 50)),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                space,
              ],
            );
          },
        ),
      ),
    );
  }

  void handleTodoCheckedChange(TodoItem item, bool? value) {
    setState(() {
      int originIndex = todoList.indexOf(item);
      todoList[originIndex].checked = value!;
    });
    setPrefsTodoList();
  }

  void showMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        width: 200,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        content: Text('not empty!'),
      ),
    );
  }

  void openOrCloseBottomSheet(List<TodoItem> renderTodoList) {
    if (showMultiple) {
      Scaffold.of(context).showBottomSheet((BuildContext context) {
        return StatefulBuilder(
            builder: ((context, setInnerState) => SizedBox(
                  height: 60,
                  child: Card(
                    margin: const EdgeInsets.all(0),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: () async {
                                if (selectTodoListList.isEmpty) {
                                  return showMessage();
                                }
                                if (await baseDeleteConfirmDialog['show']!() !=
                                    null) {
                                  for (TodoItem element in selectTodoListList) {
                                    await element.controller
                                        .reverse()
                                        .then((value) {
                                      element.controller.dispose();
                                      setState(() => todoList.remove(element));
                                    });
                                  }
                                  setPrefsTodoList();
                                  selectTodoListList.clear();
                                  if (todoList.isEmpty) {
                                    showMultiple = false;
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                              child: const Text('delete')),
                          TextButton(
                              onPressed: () {
                                if (selectTodoListList.isEmpty) {
                                  return showMessage();
                                }
                                setState(() {
                                  multipleChecked = !multipleChecked;
                                  for (TodoItem element in selectTodoListList) {
                                    todoList[getTodoItemIndex(element)]
                                        .checked = multipleChecked;
                                  }
                                });
                                setPrefsTodoList();
                              },
                              child: Row(
                                children: const [Text('toggle todo active')],
                              ))
                        ],
                      ),
                    ),
                  ),
                )));
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void handleTodoSelectCheckBoxChange(TodoItem item, bool? value) {
    setState(() {
      todoList[getTodoItemIndex(item)].selected = value!;
      changeSelectTodoList(value, item);
    });
  }

  void changeSelectTodoList(bool value, TodoItem item) {
    if (value) {
      selectTodoListList.add(item);
    } else {
      selectTodoListList.remove(item);
    }
  }

  void resetMultipleState() {
    setState(() {
      selectTodoListList.clear();
      for (var element in todoList) {
        element.selected = false;
      }
    });
    toggleMultipleShow(false);
    Navigator.of(context).pop();
  }

  void toggleMultipleShow(bool show) {
    setState(() => showMultiple = show);
    if (showMultiple) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget space = const SizedBox(
    height: 15,
  );
  final InputDecoration _titleInputDecoration = const InputDecoration(
      labelText: "What needs to be done?",
      hintText: "Todo title",
      border: OutlineInputBorder());

  var baseDeleteConfirmDialog = createDeleteConfirmDialog();
  final List<bool> _selectedListType = <bool>[true, false, false];
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color draggableItemColor = colorScheme.secondary;

    Widget proxyDecorator(
        Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return Material(
            shadowColor: draggableItemColor,
            child: child,
          );
        },
        child: child,
      );
    }

    List<TodoItem> renderTodoList = filterType == TodoItemFilterType.all
        ? todoList
        : filterType == TodoItemFilterType.active
            ? activeTodoList
            : completeTodoList;
    if (_tabController.index != typeTabs.length - 1) {
      renderTodoList = renderTodoList
          .where((element) => element.type == tabTodoType.toString())
          .toList();
    }
    bool isSelectAll = renderTodoList.length == selectTodoListList.length;
    Widget multipleMessage = SizeTransition(
      sizeFactor: _animation,
      axis: Axis.vertical,
      child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.scale(
                scale: 0.7,
                child: IconButton(
                  onPressed: resetMultipleState,
                  icon: const Icon(Icons.close),
                ),
              ),
              Text(
                'selected ${selectTodoListList.length} item',
                style: const TextStyle(fontSize: 16),
              ),
              Transform.scale(
                scale: 0.7,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      for (TodoItem todoItem in renderTodoList) {
                        todoList[getTodoItemIndex(todoItem)].selected =
                            !isSelectAll;
                      }
                      if (isSelectAll) {
                        selectTodoListList.clear();
                      } else {
                        selectTodoListList = [...renderTodoList];
                      }
                    });
                  },
                  icon: Icon(
                    isSelectAll
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank_sharp,
                  ),
                ),
              ),
            ],
          )),
    );
    return GestureDetector(
      onSecondaryTap: () {
        if (showMultiple) {
          resetMultipleState();
        }
      },
      child: Container(
        child: Column(children: [
          TabBar(
            controller: _tabController,
            unselectedLabelColor: context.watch<MainStore>().textColor,
            labelColor: context.watch<MainStore>().primaryColor,
            indicatorColor: context.watch<MainStore>().primaryColor,
            tabs: typeTabs,
            labelStyle: const TextStyle(fontSize: 16),
          ),
          const SizedBox(
            height: 5,
          ),
          multipleMessage,
          Expanded(
            child: renderTodoList.isNotEmpty
                ? SlidableAutoCloseBehavior(
                    child: ReorderableListView.builder(
                      proxyDecorator: proxyDecorator,
                      buildDefaultDragHandles: false,
                      itemBuilder: (BuildContext context, int index) {
                        bool checked = renderTodoList[index].checked;
                        String title = renderTodoList[index].title;
                        String? type = renderTodoList[index].type;
                        bool todoSelected = renderTodoList[index].selected;
                        TodoItem item = renderTodoList[index];
                        TextDecoration decoration = checked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none;
                        return Slidable(
                          groupTag: '0',
                          key: Key('$index'),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.2,
                            children: [
                              SlidableAction(
                                icon: Icons.clear,
                                backgroundColor: Colors.transparent,
                                foregroundColor:
                                    context.watch<MainStore>().textColor,
                                onPressed: (BuildContext context) async {
                                  if (await baseDeleteConfirmDialog[
                                          'show']!() !=
                                      null) {
                                    item.controller.reverse().then((value) {
                                      setState(() {
                                        todoList.removeAt(index);
                                      });
                                      if (todoList.isEmpty) {
                                        resetMultipleState();
                                      }
                                      setPrefsTodoList();
                                      item.controller.dispose();
                                    });
                                  }
                                },
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                              ),
                              SlidableAction(
                                icon: Icons.edit,
                                foregroundColor:
                                    context.watch<MainStore>().textColor,
                                backgroundColor: Colors.transparent,
                                onPressed: (_) =>
                                    handleEditPressed(index, renderTodoList),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5)),
                              ),
                            ],
                          ),
                          child: SizeTransition(
                            sizeFactor: item.animation,
                            axis: Axis.vertical,
                            child: Card(
                              child: AnimatedOpacity(
                                opacity: checked ? 0.4 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: ListTile(
                                  onLongPress: () {
                                    setState(() {
                                      if (!showMultiple) {
                                        todoList[getTodoItemIndex(item)]
                                            .selected = true;
                                        selectTodoListList.add(item);
                                      } else {
                                        for (var element in todoList) {
                                          element.selected = false;
                                        }
                                        selectTodoListList.clear();
                                      }
                                      toggleMultipleShow(!showMultiple);
                                    });
                                    openOrCloseBottomSheet(renderTodoList);
                                  },
                                  selected: todoSelected,
                                  title: Text(title,
                                      style: TextStyle(
                                        decoration: decoration,
                                      )),
                                  leading: buildScaleAnimatedSwitcher(
                                    SizedBox(
                                      width: 30,
                                      height: 30,
                                      key: ValueKey(showMultiple),
                                      child: showMultiple
                                          ? ReorderableDragStartListener(
                                              index: index,
                                              child: const Icon(
                                                Icons.drag_handle_outlined,
                                              ),
                                            )
                                          : Checkbox(
                                              value: checked,
                                              shape: const CircleBorder(),
                                              onChanged: (value) {
                                                handleTodoCheckedChange(
                                                    renderTodoList[index],
                                                    value);
                                              },
                                            ),
                                    ),
                                  ),
                                  trailing: Wrap(
                                    spacing: 5,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(renderTodoList[index].updateTime),
                                      buildScaleAnimatedSwitcher(
                                        SizedBox(
                                            width: 30,
                                            height: 30,
                                            key: ValueKey(showMultiple),
                                            child: showMultiple
                                                ? Checkbox(
                                                    value: todoSelected,
                                                    onChanged: (value) {
                                                      handleTodoSelectCheckBoxChange(
                                                          item, value);
                                                    },
                                                  )
                                                : ReorderableDragStartListener(
                                                    index: index,
                                                    child: const Icon(
                                                      Icons.drag_handle_sharp,
                                                    ),
                                                  )),
                                      )
                                    ],
                                  ),
                                  subtitle: Text(type.split('.')[1]),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: renderTodoList.length,
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          TodoItem item = todoList.removeAt(oldIndex);
                          todoList.insert(newIndex, item);
                        });
                        setPrefsTodoList();
                      },
                    ),
                  )
                : const Center(
                    child: Text(
                      'list is empty!',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
          ),
          space,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${activeTodoList.length} item left',
                style: const TextStyle(fontSize: 16),
              ),
              ToggleButtons(
                constraints: const BoxConstraints(
                  minHeight: 40.0,
                  minWidth: 70.0,
                ),
                children: const <Widget>[
                  Text('All'),
                  Text('Active'),
                  Text('Complete')
                ],
                onPressed: (int index) {
                  setState(() {
                    for (int buttonIndex = 0;
                        buttonIndex < _selectedListType.length;
                        buttonIndex++) {
                      if (buttonIndex == index) {
                        _selectedListType[buttonIndex] =
                            !_selectedListType[buttonIndex];
                      } else {
                        _selectedListType[buttonIndex] = false;
                      }
                    }
                    filterType = todoItemFilterTypeIndexMap[index]!;
                  });
                },
                isSelected: _selectedListType,
                renderBorder: false,
                fillColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              TextButton(
                child: const Text('Clear complete'),
                onPressed: () {
                  setState(() {
                    todoList = todoList
                        .where((element) => element.checked == false)
                        .toList();
                    setPrefsTodoList();
                  });
                },
              ),
              showMultiple
                  ? Container()
                  : FloatingActionButton(
                      onPressed: handleAddPressClick,
                      backgroundColor: context.watch<MainStore>().primaryColor,
                      child: const Icon(Icons.add),
                    )
            ],
          ),
        ]),
        padding: const EdgeInsets.all(20),
      ),
    );
  }
}

Map<String, Function> createDeleteConfirmDialog(
    {bool showNotTipsCheckBox = true}) {
  bool _checkboxValue = false;
  BuildContext context = navigatorKey.currentState!.context;
  Widget baseAlertDialog = AlertDialog(
    title: const Text(
      "Tips",
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "Confirm delete?",
        ),
        if (showNotTipsCheckBox)
          Row(
            children: <Widget>[
              const Text("Not tips?"),
              StatefulBuilder(builder: (context, setState) {
                return Checkbox(
                  value: _checkboxValue,
                  shape: const CircleBorder(),
                  onChanged: (bool? value) {
                    setState(() => _checkboxValue = !_checkboxValue);
                  },
                );
              }),
            ],
          ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        child: const Text("Cancel"),
        onPressed: () => Navigator.of(context).pop(),
      ),
      TextButton(
        child: const Text("Delete"),
        onPressed: () {
          // 执行删除操作
          Navigator.of(context).pop(true);
        },
      ),
    ],
  );
  wrapShowDialog() => showDialog<bool>(
        context: context,
        builder: (context) {
          return baseAlertDialog;
        },
      );
  return {
    'show': () {
      if (!showNotTipsCheckBox) {
        return wrapShowDialog();
      }
      if (!_checkboxValue) {
        return wrapShowDialog();
      } else {
        return true;
      }
    }
  };
}
