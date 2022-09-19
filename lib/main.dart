import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:todo_client/components/main_core.dart';

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(800, 700);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "todo list";
    win.show();
  });
}

const borderColor = Color(0xFF805306);
// 通过navigatorKey的方式 保存全局的context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
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
    return LayoutBuilder(
        builder: ((BuildContext context, BoxConstraints boxConstraints) {
      return Container(
        width: boxConstraints.maxWidth,
        height: 60,
        color: Theme.of(context).primaryColor,
        padding: const EdgeInsets.all(20),
        child: MoveWindow(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'Todo list',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(
                      width: 50,
                    ),
                  ],
                )),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: CupertinoButton(
                      padding: const EdgeInsets.all(0),
                      child: const FaIcon(
                        FontAwesomeIcons.shirt,
                        color: Colors.white,
                        size: 14,
                      ),
                      onPressed: () {}),
                ),
                const SizedBox(
                  width: 20,
                ),
                const WindowButtons(),
              ],
            )
          ],
        )),
      );
    }));
  }
}

final buttonColors = WindowButtonColors(
  iconNormal: Colors.white,
  mouseOver: Colors.transparent,
  mouseDown: Colors.transparent,
);

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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 20,
      children: [
        GestureDetector(
          onTap: () => appWindow.minimize(),
          child: Transform.translate(
            offset: const Offset(0, -7),
            child: const FaIcon(
              FontAwesomeIcons.windowMinimize,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        GestureDetector(
          child: Icon(
            appWindow.isMaximized ? Icons.close_fullscreen : Icons.fullscreen,
            color: Colors.white,
            size: 16,
          ),
          onTap: () => maximizeOrRestore(),
        ),
        GestureDetector(
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
          onTap: () => appWindow.close(),
        ),
      ],
    );
  }
}
