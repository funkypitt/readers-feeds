import 'package:flutter/widgets.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  double fontSize = 17.0;
  bool _fontSizeIsAuto = true;
  bool dark = false;      // white on black
  bool serif = false;     // reading face
  bool pagedList = false; // lists turn pages instead of scrolling (e-ink)

  final SettingsService _service = SettingsService();

  bool get fontSizeIsAuto => _fontSizeIsAuto;

  Future<void> load() async {
    final saved = await _service.getSavedFontSize();
    if (saved != null) {
      fontSize = saved;
      _fontSizeIsAuto = false;
    }
    dark = await _service.getBool('dark', false);
    serif = await _service.getBool('serif', false);
    pagedList = await _service.getBool('paged_list', false);
    notifyListeners();
  }

  Future<void> toggleDark() async { dark = !dark; await _service.setBool('dark', dark); notifyListeners(); }
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
