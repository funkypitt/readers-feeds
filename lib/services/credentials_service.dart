// The Reader's credentials file: one JSON shared by the Reader's apps (phone and desktop), a
// section per app. Reader's Feeds keeps its paid Substack sign-ins in `readers-feeds.substack`:
// each publication with its substack.sid cookie, since a cookie means nothing without its feed.
import 'dart:convert';
import '../models/source.dart';

const credentialsFormat = 'readers-credentials';
const credentialsSection = 'readers-feeds';

class CredentialsError implements Exception {
  /// 'foreign' (not a credentials file) or 'missing' (no section for this app).
  final String kind;
  CredentialsError(this.kind);
  @override
  String toString() => 'CredentialsError($kind)';
}

/// The file content for this app: format, version and its section (paid Substacks only).
/// Returns null when there is nothing to export.
String? buildCredentials(List<Source> sources) {
  final substacks = [
    for (final s in sources)
      if (s.cookie != null && s.cookie!.isNotEmpty)
        {
          if (s.name.isNotEmpty) 'name': s.name,
          if (s.url.isNotEmpty) 'url': s.url,
          'rss': s.rss,
          'cookie': s.cookie!,
        }
  ];
  if (substacks.isEmpty) return null;
  return const JsonEncoder.withIndent('  ').convert({
    'format': credentialsFormat,
    'version': 1,
    credentialsSection: {'substack': substacks},
  });
}

/// The paid Substacks held by a credentials file, as sources. Only this app's section and only
/// the keys it knows are read; other apps' sections (a desktop file holding several) are ignored.
List<Source> readCredentials(String text) {
  Object? data;
  try {
    data = jsonDecode(text);
  } catch (_) {
    throw CredentialsError('foreign');
  }
  if (data is! Map || data['format'] != credentialsFormat) throw CredentialsError('foreign');
  final section = data[credentialsSection];
  if (section is! Map || section['substack'] is! List || (section['substack'] as List).isEmpty) {
    throw CredentialsError('missing');
  }
  final out = <Source>[];
  for (final e in section['substack'] as List) {
    if (e is! Map) continue;
    final rss = e['rss'], cookie = e['cookie'];
    if (rss is! String || rss.isEmpty || cookie is! String || cookie.isEmpty) continue;
    final url = e['url'] is String && (e['url'] as String).isNotEmpty ? e['url'] as String : rss;
    final name = e['name'] is String && (e['name'] as String).isNotEmpty
        ? e['name'] as String
        : (Uri.tryParse(url)?.host.replaceAll('.substack.com', '').replaceAll('www.', '') ?? url);
    out.add(Source(
      id: 'substack_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
      name: name, url: url, rss: rss, category: 'substack', lang: 'EN', tag: 'paid', isDefault: false, cookie: cookie,
    ));
  }
  if (out.isEmpty) throw CredentialsError('missing');
  return out;
}
