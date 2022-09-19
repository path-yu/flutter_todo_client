import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_client/state/theme_data.dart';

enum BaseThemeMode { dark, red, pink, blue, green, orange }

class MainStore extends Cubit<MainState> {
  MainStore() : super(MainState());

  void changeTheme(BaseThemeMode theme) {
    state.theme = theme;
    emit(state);
  }
}

class MainState {
  BaseThemeMode theme = BaseThemeMode.red;

  ThemeData get currentTheme => baseThemeData[theme.toString()] as ThemeData;
}
