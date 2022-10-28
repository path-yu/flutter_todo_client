import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:todo_client/components/main_core.dart';
import 'package:todo_client/state/mainStore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _prefs.then((prefs) {
    String? pickPrimaryColorIndex = prefs.getString(pickPrimaryColorIndexKey);
    bool? openNightMode = prefs.getBool(openNightModeKey);
    runApp(ChangeNotifierProvider(
      create: (context) => MainStore(
          pickPrimaryColorIndex: pickPrimaryColorIndex != null
              ? int.parse(pickPrimaryColorIndex)
              : 5,
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          offset: const Offset(0, -5),
          child: SizedBox(
            width: 40,
            child: TextButton(
              child: const Icon(
                Icons.minimize,
                color: Colors.white,
                size: 16,
              ),
              onPressed: () => appWindow.minimize(),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: TextButton(
            child: Icon(
              appWindow.isMaximized ? Icons.close_fullscreen : Icons.fullscreen,
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
  const PickerThemeDialog({Key? key}) : super(key: key);

  @override
  State<PickerThemeDialog> createState() => _PickerThemeDialogState();
}

class _PickerThemeDialogState extends State<PickerThemeDialog> {
  @override
  void initState() {
    super.initState();
  }

  double checkBoxSize = 24;
  double itemSize = 50;

  @override
  Widget build(BuildContext context) {
    Offset checkBoxOffset = Offset(
        itemSize - checkBoxSize + checkBoxSize * 0.8 / 2,
        itemSize - checkBoxSize + checkBoxSize * 0.8 / 2);
    var pickerIndex = context.watch<MainStore>().pickPrimaryColorIndex;
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Picker theme color',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: materialColorList.asMap().keys.toList().map((index) {
                return Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        context
                            .read<MainStore>()
                            .changePrickerPrimaryColorIndex(index);
                        _prefs.then((value) {
                          value.setString(
                              pickPrimaryColorIndexKey, (index).toString());
                        });
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
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
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
            )
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
