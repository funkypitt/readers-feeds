import 'package:flutter/foundation.dart';
import '../models/source.dart';
import '../services/source_service.dart';

class SourceProvider extends ChangeNotifier {
  List<Source> _sources = [];
  List<Source> get sources => _sources;
  List<Source> get activeSources => _sources.where((s) => s.active).toList();

  final SourceService _service = SourceService();

  Future<void> load() async {
    _sources = await _service.loadSources();
    notifyListeners();
  }

  Future<void> toggleSource(String id) async {
    final i = _sources.indexWhere((s) => s.id == id);
    if (i >= 0) {
      _sources[i].active = !_sources[i].active;
      await _service.saveSources(_sources);
      notifyListeners();
    }
  }

  Future<void> addSource(Source source) async {
    await _service.addCustomSource(source);
    await load();
  }

  Future<void> removeSource(String id) async {
    await _service.removeSource(id);
    await load();
  }

  Future<void> updateSourceCookie(String id, String? cookie) async {
    final i = _sources.indexWhere((s) => s.id == id);
    if (i >= 0) {
      _sources[i].cookie = cookie;
      await _service.saveSources(_sources);
      notifyListeners();
    }
  }

  /// Paid Substacks from a credentials file: a publication already here takes the cookie, a new
  /// one is added. Returns how many sign-ins were applied.
  Future<int> applySubstackSignIns(List<Source> incoming) async {
    var n = 0;
    for (final s in incoming) {
      final i = _sources.indexWhere((x) => x.rss == s.rss || x.id == s.id);
      if (i >= 0) {
        _sources[i].cookie = s.cookie;
      } else {
        _sources.add(s);
      }
      n++;
    }
    await _service.saveSources(_sources);
    await load();
    return n;
  }

  /// Add multiple sources at once (used by OPML/CSV import)
  Future<void> addSources(List<Source> newSources) async {
    final existingIds = _sources.map((s) => s.id).toSet();
    final toAdd = newSources.where((s) => !existingIds.contains(s.id)).toList();
    if (toAdd.isEmpty) return;
    for (final s in toAdd) {
      await _service.addCustomSource(s);
    }
    await load();
  }
}
