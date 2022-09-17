import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_client/state/mainStore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1050, 700);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Custom window with Flutter";
    win.show();
  });
}

const borderColor = Color(0xFF805306);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MainStore(),
      child: BlocBuilder<MainStore, MainState>(builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: state.currentTheme,
          home: Scaffold(
            body: WindowBorder(
              color: borderColor,
              width: 1,
              child: Column(
                children: [
                  const TopBar(),
                  Text(state.theme.toString()),
                  ElevatedButton(
                      onPressed: () {
                        context
                            .read<MainStore>()
                            .changeTheme(BaseThemeMode.blue);
                      },
                      child: const Text('change theme')),
                  IconButton(
                    padding: const EdgeInsets.all(0),
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 15,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      }),
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
        child: MoveWindow(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'todoList',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(
                        width: 100,
                      ),
                      CupertinoButton(
                          child: const Icon(Icons.arrow_back_ios,
                              size: 15, color: Colors.white),
                          onPressed: () {}),
                      CupertinoButton(
                          padding: const EdgeInsets.all(0),
                          child: const Icon(Icons.arrow_forward_ios,
                              size: 15, color: Colors.white),
                          onPressed: () {})
                    ],
                  ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MinimizeWindowButton(colors: buttonColors),
        appWindow.isMaximized
            ? RestoreWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              )
            : MaximizeWindowButton(
                colors: buttonColors,
                onPressed: maximizeOrRestore,
              ),
        CloseWindowButton(colors: buttonColors),
      ],
    );
  }
}
