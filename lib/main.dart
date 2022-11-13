import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:todo_client/components/main_core.dart';
import 'package:todo_client/state/mainStore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

final Future<SharedPreferences> prefs = SharedPreferences.getInstance();
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  prefs.then((prefsInstance) {
    String? pickPrimaryColorIndex =
        prefsInstance.getString(pickPrimaryColorIndexKey);
    bool? openNightMode = prefsInstance.getBool(openNightModeKey);

    runApp(ChangeNotifierProvider(
      create: (context) => MainStore(
          pickPrimaryColorIndex: pickPrimaryColorIndex != null
              ? int.parse(pickPrimaryColorIndex)
              : null,
          customColor: pickPrimaryColorIndex != null
              ? getMaterialColorValue(int.parse(pickPrimaryColorIndex))
              : prefsInstance.getInt(customColorKey),
          openNightMode: openNightMode ?? false),
      child: const MyApp(),
    ));
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(800, 700);
      win.minSize = initialSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = "todo list";
      win.show();
    });
  });
}

const borderColor = Color(0xFF805306);

// 通过navigatorKey的方式 保存全局的context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var primaryColor = context.watch<MainStore>().primaryColor;
    MaterialStateProperty<Color?> fillColor =
        MaterialStateProperty.all(context.watch<MainStore>().primaryColor);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      theme: ThemeData(
          primarySwatch: primaryColor,
          brightness: context.watch<MainStore>().brightness,
          checkboxTheme: CheckboxThemeData(
            fillColor: fillColor,
          ),
          radioTheme: RadioThemeData(fillColor: fillColor)),
      navigatorKey: navigatorKey, // set property
      home: Scaffold(
        body: WindowBorder(
          color: borderColor,
          width: 1,
          child: Column(
            children: [
              const TopBar(),
              Expanded(
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints boxConstraints) {
                  return SizedBox(
                    width: boxConstraints.maxWidth,
                    height: boxConstraints.maxHeight,
                    child: const MainCore(),
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool openNightMode = context.watch<MainStore>().openNightMode;
    return LayoutBuilder(
        builder: ((BuildContext context, BoxConstraints boxConstraints) {
      return Container(
        width: boxConstraints.maxWidth,
        height: 60,
        color: Theme.of(context).primaryColor,
        padding: const EdgeInsets.all(20),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: MoveWindow(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Todo list',
                style: TextStyle(fontSize: 18),
              ),
              Row(
                children: [
                  TextButton(
                      child: const FaIcon(
                        FontAwesomeIcons.shirt,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return const PickerThemeDialog();
                          },
                        );
                      }),
                  TextButton(
                    child: AnimatedSwitcher(
                      child: Icon(
                        openNightMode
                            ? Icons.nightlight_outlined
                            : Icons.light_mode_outlined,
                        color: Colors.white,
                        size: 16,
                        key: ValueKey<bool>(openNightMode),
                      ),
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        //执行缩放动画
                        return ScaleTransition(child: child, scale: animation);
                      },
                    ),
                    onPressed: () {
                      context.read<MainStore>().toggleTheme();
                    },
                  ),
                  const WindowButtons(),
                ],
              )
            ],
          )),
        ),
      );
    }));
  }
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  _WindowButtonsState createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.translate(
          offset: const Offset(0, -8),
          child: SizedBox(
            width: 40,
            child: TextButton(
              child: const Icon(
                Icons.minimize,
                color: Colors.white,
              ),
              onPressed: () => appWindow.minimize(),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: TextButton(
            child: Icon(
              appWindow.isMaximized
                  ? Icons.close_fullscreen
                  : Icons.check_box_outline_blank,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => maximizeOrRestore(),
          ),
        ),
        SizedBox(
          width: 40,
          child: TextButton(
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => appWindow.close(),
          ),
        ),
      ],
    );
  }
}

class PickerThemeDialog extends StatefulWidget {
  const PickerThemeDialog({Key? key})
      : super(
          key: key,
        );

  @override
  State<PickerThemeDialog> createState() => _PickerThemeDialogState();
}

class _PickerThemeDialogState extends State<PickerThemeDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color pickerColor = context.read<MainStore>().primaryColor;
  int _tabIndex = 0;
  final Duration _tabBarDuration = const Duration(milliseconds: 300);
  final List<Widget> _tabs = [
    const Tab(
      text: 'Custom',
    ),
    const Tab(
      text: 'Basic color',
    ),
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        animationDuration: _tabBarDuration,
        vsync: this,
        length: _tabs.length,
        initialIndex: _tabIndex);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void handleTabOnTap(index) async {
    _tabController.index = _tabController.previousIndex;
    if (index == 1) {
      _tabController.animateTo(1);
      await Future.delayed(_tabBarDuration);
      setState(() => _tabIndex = 1);
    } else {
      setState(() => _tabIndex = 0);
      await Future.delayed(_tabBarDuration);
      _tabController.animateTo(0);
    }
  }

  double checkBoxSize = 24;
  double itemSize = 50;

  @override
  Widget build(BuildContext context) {
    Offset checkBoxOffset = Offset(
        itemSize - checkBoxSize + checkBoxSize * 0.8 / 2,
        itemSize - checkBoxSize + checkBoxSize * 0.8 / 2);
    var pickerIndex = context.watch<MainStore>().pickPrimaryColorIndex;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      contentPadding: const EdgeInsets.all(10),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      content: AnimatedContainer(
        duration: _tabBarDuration,
        curve: Curves.ease,
        width: screenWidth * 0.45,
        height: _tabIndex == 0 ? screenHeight * 0.307 : screenHeight * 0.4,
        child: Column(
          children: [
            const SizedBox(
              width: double.infinity,
              child: Text(
                'Picker theme color',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: TabBar(
                tabs: _tabs,
                onTap: handleTabOnTap,
                controller: _tabController,
                unselectedLabelColor: context.watch<MainStore>().textColor,
                labelColor: context.watch<MainStore>().primaryColor,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
                child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    LayoutBuilder(builder: (context, constrainedBox) {
                      return Transform.translate(
                        offset: const Offset(0, 15),
                        child: ColorPicker(
                          pickerColor: pickerColor,
                          pickerAreaHeightPercent: 0,
                          displayThumbColor: true,
                          colorPickerWidth: constrainedBox.maxWidth * 0.95,
                          paletteType: PaletteType.hslWithHue,
                          portraitOnly: true,
                          hexInputBar: false,
                          labelTypes: const [],
                          onColorChanged: (Color color) {
                            pickerColor = color;
                            context
                                .read<MainStore>()
                                .changeCustomColor(color.value);
                          },
                        ),
                      );
                    })
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children:
                      materialColorList.asMap().keys.toList().map((index) {
                    return Stack(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() => pickerColor =
                                Color(materialColorList[index].value));
                            context
                                .read<MainStore>()
                                .changePrickerPrimaryColorIndex(index);
                          },
                          child: Container(
                            width: itemSize,
                            height: itemSize,
                            decoration: BoxDecoration(
                                color: materialColorList[index],
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5))),
                          ),
                        ),
                        if (pickerIndex == index)
                          Transform.translate(
                              offset: checkBoxOffset,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30))),
                                  child: SizedBox(
                                    width: checkBoxSize,
                                    height: checkBoxSize,
                                    child: Checkbox(
                                        value: true,
                                        shape: const CircleBorder(),
                                        onChanged: (_) {}),
                                  ),
                                ),
                              ))
                      ],
                    );
                  }).toList(),
                ),
              ],
            ))
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('confirm'))
      ],
    );
  }
}
