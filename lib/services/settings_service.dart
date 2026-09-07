import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kFontSize = 'reader_font_size';
  static const _kFontSizeSet = 'reader_font_size_set';

  // ── font size ──────────────────────────────────────────────

  Future<double?> getSavedFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final isSet = prefs.getBool(_kFontSizeSet) ?? false;
    if (!isSet) return null;
    return prefs.getDouble(_kFontSize);
  }

  Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSize, value);
    await prefs.setBool(_kFontSizeSet, true);
  }

  Future<void> resetFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFontSize);
    await prefs.setBool(_kFontSizeSet, false);
  }

  /// The Reader's rule: the shortest side in dp over 20, kept between 17 and 24.
  static double autoFor(double shortestSideDp) => (shortestSideDp / 20).clamp(17.0, 24.0).roundToDouble();

  static double computeAdaptiveFontSize(BuildContext context) => autoFor(MediaQuery.sizeOf(context).shortestSide);

  Future<bool> getBool(String key, bool fallback) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? fallback;
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
