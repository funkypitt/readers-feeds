import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../services/settings_service.dart';
import '../ui/palettes.dart';

class SettingsProvider extends ChangeNotifier {
  double fontSize = 17.0;
  bool _fontSizeIsAuto = true;
  String theme = kDefaultTheme; // the colour theme's name, see palettes.dart
  bool serif = false;     // reading face
  bool pagedList = false; // lists turn pages instead of scrolling (e-ink)

  final SettingsService _service = SettingsService();

  bool get fontSizeIsAuto => _fontSizeIsAuto;
  Palette get palette => paletteOf(theme);

  static const _widgetChannel = MethodChannel('com.freedomfighter.readersfeeds/widget');

  Future<void> load() async {
    final saved = await _service.getSavedFontSize();
    if (saved != null) {
      fontSize = saved;
      _fontSizeIsAuto = false;
    }
    // Before 1.4.0 the setting was a flag, "dark": true meant white on black.
    final stored = await _service.getString('theme') ?? (await _service.getBool('dark', false) ? 'dark' : 'light');
    theme = isTheme(stored) ? stored : kDefaultTheme;
    serif = await _service.getBool('serif', false);
    pagedList = await _service.getBool('paged_list', false);
    notifyListeners();
  }

  /// One tap: the next theme, round and round; the home-screen widget follows.
  Future<void> nextTheme() async {
    theme = nextThemeAfter(theme);
    await _service.setString('theme', theme);
    notifyListeners();
    try { await _widgetChannel.invokeMethod('updateWidget'); } catch (_) {}
  }
  Future<void> toggleSerif() async { serif = !serif; await _service.setBool('serif', serif); notifyListeners(); }
  Future<void> togglePagedList() async { pagedList = !pagedList; await _service.setBool('paged_list', pagedList); notifyListeners(); }

  /// Called from the home screen's build once the window has a size: the first frame on
  /// Android can report a zero size, so the value is re-checked until it settles.
  void applyAuto(double shortestSideDp) {
    if (!_fontSizeIsAuto || shortestSideDp <= 0) return;
    final auto = SettingsService.autoFor(shortestSideDp);
    if (auto == fontSize) return;
    fontSize = auto;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  Future<void> increaseFontSize() async {
    if (fontSize >= 30) return;
    fontSize = (fontSize + 1).clamp(13.0, 30.0);
    _fontSizeIsAuto = false;
    await _service.setFontSize(fontSize);
    notifyListeners();
  }

  Future<void> decreaseFontSize() async {
    if (fontSize <= 13) return;
    fontSize = (fontSize - 1).clamp(13.0, 30.0);
    _fontSizeIsAuto = false;
    await _service.setFontSize(fontSize);
    notifyListeners();
  }

  Future<void> resetFontSize(BuildContext context) async {
    final adaptive = SettingsService.computeAdaptiveFontSize(context);
    await _service.resetFontSize();
    _fontSizeIsAuto = true;
    fontSize = adaptive;
    notifyListeners();
  }

}
