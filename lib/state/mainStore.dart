import 'package:flutter/material.dart';

import '../main.dart';

List<MaterialColor> materialColorList = Colors.primaries;
const int colorRedHex = 0xfff44336;
const pickPrimaryColorIndexKey = 'pickPrimaryColorIndex';
const openNightModeKey = 'openNightModeKey';
const customColorKey = 'customColor';

class MainStore with ChangeNotifier {
  int? pickPrimaryColorIndex;
  int? customColor;
  bool openNightMode;
  MainStore(
      {required this.pickPrimaryColorIndex,
      required this.openNightMode,
      this.customColor = colorRedHex});

  MaterialColor get primaryColor => pickPrimaryColorIndex != null
      ? materialColorList[pickPrimaryColorIndex!]
      : customColor != null
          ? createMaterialColor(Color(customColor!))
          : Colors.blue;
  Brightness get brightness =>
      openNightMode ? Brightness.dark : Brightness.light;

  Color get textColor => openNightMode ? Colors.white : Colors.black;
  changePrickerPrimaryColorIndex(int index) {
    pickPrimaryColorIndex = index;
    customColor = colorRedHex;
    prefs.then((that) {
      that.setString(pickPrimaryColorIndexKey, index.toString());
      that.setInt(customColorKey, materialColorList[index].value);
    });
    notifyListeners();
  }

  changeCustomColor(int value) {
    pickPrimaryColorIndex = null;
    customColor = value;
    prefs.then((that) {
      that.remove(pickPrimaryColorIndexKey);
      that.setInt(customColorKey, value);
    });
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

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

int getMaterialColorValue(int index) {
  return materialColorList[index].value;
}
