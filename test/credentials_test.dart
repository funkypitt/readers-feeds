import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:readers_feeds/models/source.dart';
import 'package:readers_feeds/services/credentials_service.dart';

Source src(String name, {String? cookie}) => Source(id: name, name: name, url: 'https://$name.substack.com', rss: 'https://$name.substack.com/feed', category: 'substack', lang: 'EN', isDefault: false, cookie: cookie);

void main() {
  test('build: format, version, only signed-in Substacks, no other section', () {
    final text = buildCredentials([src('paid', cookie: 's%3Aabc'), src('free'), src('empty', cookie: '')])!;
    final d = jsonDecode(text) as Map;
    expect(d['format'], 'readers-credentials');
    expect(d['version'], 1);
    expect(d.keys.toSet(), {'format', 'version', 'readers-feeds'});
    final list = d['readers-feeds']['substack'] as List;
    expect(list.length, 1);
    expect(list.first, {'name': 'paid', 'url': 'https://paid.substack.com', 'rss': 'https://paid.substack.com/feed', 'cookie': 's%3Aabc'});
  });
  test('build: nothing to export', () {
    expect(buildCredentials([src('free')]), isNull);
  });
  test('read: round trip', () {
    final back = readCredentials(buildCredentials([src('paid', cookie: 'c1')])!);
    expect(back.single.rss, 'https://paid.substack.com/feed');
    expect(back.single.cookie, 'c1');
    expect(back.single.tag, 'paid');
    expect(back.single.id, 'substack_paid');
  });
  test('read: other sections and unknown keys are ignored', () {
    final text = jsonEncode({
      'format': 'readers-credentials', 'version': 1,
      'readers-notes': {'server': 'https://x', 'username': 'u', 'password': 'p'},
      'readers-calendar': {'google': {'tokens': {'refresh_token': 'r'}}},
      'readers-feeds': {'substack': [{'rss': 'https://a.substack.com/feed', 'cookie': 'k', 'colour': 'red'}, {'rss': '', 'cookie': 'x'}, 'junk'], 'future_key': 42},
    });
    final got = readCredentials(text);
    expect(got.length, 1);
    expect(got.single.name, 'a');
    expect(got.single.url, 'https://a.substack.com/feed');
  });
  test('read: refuses a foreign file', () {
    for (final text in ['not json', '[1,2]', '{"hello": 1}', '{"format": "something-else", "readers-feeds": {"substack": []}}']) {
      expect(() => readCredentials(text), throwsA(isA<CredentialsError>().having((e) => e.kind, 'kind', 'foreign')), reason: text);
    }
  });
  test('read: a credentials file without this app is "missing"', () {
    for (final section in [null, {}, {'substack': []}, {'substack': [{'rss': 'x'}]}]) {
      final text = jsonEncode({'format': 'readers-credentials', 'version': 1, 'readers-notes': {'server': 's'}, if (section != null) 'readers-feeds': section});
      expect(() => readCredentials(text), throwsA(isA<CredentialsError>().having((e) => e.kind, 'kind', 'missing')), reason: '$section');
    }
  });
}
