import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_format/date_format.dart';
import 'package:todo_client/main.dart';
import 'package:todo_client/state/mainStore.dart';

class MainCore extends StatefulWidget {
  const MainCore({Key? key}) : super(key: key);

  @override
  State<MainCore> createState() => _MainCoreState();
}

class TodoItem {
  late String title;
  late String description;
  late String updateTime;
  late bool checked;
  TodoItem({
    required this.title,
    required this.description,
    required this.updateTime,
    this.checked = true,
  });

  //将json 序列化为model对象
  TodoItem.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    description = json['description'];
    updateTime = json['updateTime'];
    checked = json['checked'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['description'] = description;
    data['updateTime'] = updateTime;
    data['checked'] = checked;
    return data;
  }
}

enum TodoItemFilterType { all, active, compete }

Map<int, TodoItemFilterType> todoItemFilterTypeIndexMap = {
  0: TodoItemFilterType.all,
  1: TodoItemFilterType.active,
  2: TodoItemFilterType.compete,
};

class _MainCoreState extends State<MainCore> {
  String title = '';
  String description = '';
  List<TodoItem> todoList = [];
  TodoItemFilterType filterType = TodoItemFilterType.all;
  List<TodoItem> get completeTodoList =>
      todoList.where((element) => element.checked).toList();
  List<TodoItem> get activeTodoList =>
      todoList.where((element) => !element.checked).toList();
  final TextEditingController _tittleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void handleAddClick() {
    TodoItem item = TodoItem(
      title: title,
      description: description,
      updateTime: getCurrentTime(),
    );
    setState(() {
      todoList.add(item);
      title = "";
      description = "";
    });
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
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? items = prefs.getStringList('todoList');
    if (items != null) {
      setState(() {
        todoList =
            items.map((item) => TodoItem.fromJson(json.decode(item))).toList();
      });
    }
    // handleEditPressed(3);
  }

  void setPrefsTodoList() async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('todoList',
          todoList.map((item) => json.encode(item.toJson())).toList());
    });
  }

  void handleEditPressed(int index, List<TodoItem> list) {
    TodoItem current = list[index];
    String editTitle = current.title, editDescription = current.description;
    var titleDecoration =
        _titleInputDecoration.copyWith(border: const UnderlineInputBorder());
    var descriptionDecoration = _descriptionInputDecoration.copyWith(
        border: const UnderlineInputBorder());
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
              TextFormField(
                initialValue: editDescription,
                onChanged: (value) => editDescription = value,
                decoration: descriptionDecoration,
              )
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
                todoList[index].description = editDescription;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget space = const SizedBox(
    height: 15,
  );
  final InputDecoration _titleInputDecoration = const InputDecoration(
      labelText: "Title", hintText: "Todo title", border: OutlineInputBorder());
  final InputDecoration _descriptionInputDecoration = const InputDecoration(
      labelText: "Description",
      hintText: "Todo Description",
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
    Color actionBackgroundColor = context.watch<MainStore>().openNightMode
        ? Theme.of(context).cardColor
        : Colors.white;
    return Container(
      child: Column(children: [
        const Text(
          'What needs to be done?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        space,
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
        TextField(
            controller: _descriptionController,
            decoration: _descriptionInputDecoration,
            onChanged: (value) => setState(() => description = value)),
        space,
        ElevatedButton(
          onPressed: title.isNotEmpty ? handleAddClick : null,
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 50)),
          child: const Text(
            'Add',
            style: TextStyle(fontSize: 18),
          ),
        ),
        space,
        Expanded(
          child: renderTodoList.isNotEmpty
              ? SlidableAutoCloseBehavior(
                  child: ReorderableListView.builder(
                    proxyDecorator: proxyDecorator,
                    buildDefaultDragHandles: false,
                    itemBuilder: (BuildContext context, int index) {
                      bool checked = renderTodoList[index].checked;
                      String title = renderTodoList[index].title;
                      String description = renderTodoList[index].description;
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
                              icon: Icons.close_outlined,
                              backgroundColor: actionBackgroundColor,
                              onPressed: (BuildContext context) async {
                                if (await baseDeleteConfirmDialog['show']!() !=
                                    null) {
                                  setState(() {
                                    todoList.removeAt(index);
                                  });
                                  setPrefsTodoList();
                                }
                              },
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5)),
                            ),
                            SlidableAction(
                              icon: Icons.edit,
                              backgroundColor: actionBackgroundColor,
                              onPressed: (_) =>
                                  handleEditPressed(index, renderTodoList),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5)),
                            ),
                          ],
                        ),
                        child: Card(
                          child: AnimatedOpacity(
                            opacity: checked ? 0.6 : 1,
                            duration: const Duration(milliseconds: 300),
                            child: ListTile(
                              title: Text(title,
                                  style: TextStyle(
                                    decoration: decoration,
                                  )),
                              subtitle: description.isEmpty
                                  ? null
                                  : Text(description,
                                      style: TextStyle(
                                        decoration: decoration,
                                      )),
                              leading: Checkbox(
                                value: checked,
                                onChanged: (value) {
                                  setState(() {
                                    todoList[index].checked = value!;
                                  });
                                  setPrefsTodoList();
                                },
                              ),
                              trailing: Wrap(
                                spacing: 5,
                                children: [
                                  Text(renderTodoList[index].updateTime),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle_sharp),
                                  )
                                ],
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
                minWidth: 80.0,
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
          ],
        ),
      ]),
      padding: const EdgeInsets.all(20),
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
