import 'package:flutter/material.dart';

List<MaterialColor> materialColorList = Colors.primaries;

class MainStore with ChangeNotifier {
  int pickPrimaryColorIndex;
  bool openNightMode;
  MainStore({required this.pickPrimaryColorIndex, required this.openNightMode});

  MaterialColor get primaryColor => materialColorList[pickPrimaryColorIndex];
  Brightness get brightness =>
      openNightMode ? Brightness.dark : Brightness.light;

  changePrickerPrimaryColorIndex(int index) {
    pickPrimaryColorIndex = index;
    notifyListeners();
  }

  toggleTheme() {
    openNightMode = !openNightMode;
    notifyListeners();
  }

  changeTheme(Brightness brightness) {
    openNightMode = brightness == Brightness.dark;
    notifyListeners();
  }
}

const pickPrimaryColorIndexKey = 'pickPrimaryColorIndex';
const openNightModeKey = 'openNightModeKey';
