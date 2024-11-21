import 'package:flutter/material.dart';
import 'package:authentification/theme/dark_mode.dart';
import 'package:authentification/theme/light_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themePreferenceKey = 'theme_preference';

  // Initially light mode
  ThemeData _themeData = lightMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  // get theme
  ThemeData get themeData => _themeData;

  // is dark mode
  bool get isDarkMode => _themeData == darkMode;

  // set theme
  set themeData(ThemeData themeData) {
    _themeData = themeData;

    // update UI
    notifyListeners();

    // save theme preference
    _saveThemePreference();
  }

  // toggle theme
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkModeEnabled = prefs.getBool(_themePreferenceKey) ?? false;

    if (isDarkModeEnabled) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDarkMode);
  }
}
