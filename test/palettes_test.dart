import 'package:flutter_test/flutter_test.dart';
import 'package:readers_feeds/ui/palettes.dart';

void main() {
  test('the cycle: the inks first, then the Plume palettes, round and round', () {
    final seen = <String>[];
    var name = 'dark';
    do { seen.add(name); name = nextThemeAfter(name); } while (name != 'dark');
    expect(seen, ['dark', 'light', 'lavande', 'sauge', 'nordique', 'terracotta', 'coquette', 'militante', 'torride', 'nature']);
  });
  test('the two inks keep the accent as the text colour, every palette has a readable accent', () {
    expect(paletteOf('dark').accent, paletteOf('dark').fg);
    expect(paletteOf('light').accent, paletteOf('light').fg);
    for (final p in kPalettes) {
      expect(p.isDark, p.bg.computeLuminance() < 0.5);
      expect((p.accent.computeLuminance() - p.onAccent.computeLuminance()).abs() > 0.3, isTrue, reason: p.name);
    }
  });
  test('the two inks are text on the page, every palette brings tiles', () {
    expect(paletteOf('dark').tiles, isFalse);
    expect(paletteOf('light').tiles, isFalse);
    for (final p in kPalettes.where((p) => p.tiles)) {
      expect(p.tile, isNot(p.bg), reason: p.name);
      expect(p.press, isNot(p.tile), reason: p.name);
      expect((p.tile.computeLuminance() - p.fg.computeLuminance()).abs() > 0.3, isTrue, reason: p.name);
    }
  });
  test('an unknown name falls back to the default, and never breaks the cycle', () {
    expect(paletteOf('bogus').name, kDefaultTheme);
    expect(isTheme('bogus'), isFalse);
    expect(nextThemeAfter('bogus'), 'dark');
  });
  test('the names shown are the English keys of the l10n table', () {
    expect(themeName('dark'), 'white on black');
    expect(themeName('light'), 'black on white');
    expect(themeName('militante'), 'activist');
    expect(themeName('torride'), 'sultry');
  });
}
