// The colour themes shared by the Reader's apps: the two inks (white on black, black on white),
// then the palettes of the Plume keyboard, in its order. The setting is the theme's name; the
// Android widget reads the same setting and holds the same values (Palettes.kt).
import 'package:flutter/material.dart';
import 'l10n.dart';

class Palette {
  final String name;
  final Color bg;
  final Color fg;
  /// Fills the inverted rows (the text colour itself in the two inks).
  final Color accent;
  final Color onAccent;
  /// A colour palette brings tiles: [tile] is the card every tappable row sits on, [tile2] a
  /// second, dimmer surface, [press] the tile while the finger is on it. The two inks have none
  /// ([tiles] false): text on the page.
  final Color tile;
  final Color tile2;
  final Color press;
  final bool tiles;
  const Palette(this.name, this.bg, this.fg, this.accent, this.onAccent, [Color? tile, Color? tile2, Color? press])
      : tile = tile ?? bg, tile2 = tile2 ?? bg, press = press ?? bg, tiles = tile != null;

  /// The status-bar icons and the system's brightness follow the background, not the name.
  bool get isDark => bg.computeLuminance() < 0.5;
}

const List<Palette> kPalettes = [
  Palette('dark', Color(0xFF000000), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFF000000)),
  Palette('light', Color(0xFFFFFFFF), Color(0xFF000000), Color(0xFF000000), Color(0xFFFFFFFF)),
  Palette('lavande', Color(0xFF1F1A2E), Color(0xFFF4EFFF), Color(0xFFB8A4FF), Color(0xFF1F1A2E), Color(0xFF3B3352), Color(0xFF2B2540), Color(0xFF5A4F78)),
  Palette('sauge', Color(0xFFD9E0D4), Color(0xFF1E2A21), Color(0xFF4C7A5B), Color(0xFFFFFFFF), Color(0xFFF7F9F4), Color(0xFFB5C2B2), Color(0xFFB5C2B2)),
  Palette('nordique', Color(0xFF2E3440), Color(0xFFECEFF4), Color(0xFF88C0D0), Color(0xFF2E3440), Color(0xFF3B4252), Color(0xFF353B4A), Color(0xFF4C566A)),
  Palette('terracotta', Color(0xFFE6D9CC), Color(0xFF2B211B), Color(0xFFC25E38), Color(0xFFFFFFFF), Color(0xFFFCF7F1), Color(0xFFC8B6A5), Color(0xFFC8B6A5)),
  Palette('coquette', Color(0xFFF3D9DC), Color(0xFF4A1F2B), Color(0xFFD2455E), Color(0xFFFFFFFF), Color(0xFFFFF7F5), Color(0xFFE7BFC6), Color(0xFFE7BFC6)),
  Palette('militante', Color(0xFFF2EEE4), Color(0xFF121212), Color(0xFFE8412E), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFD8D3C6), Color(0xFFD8D3C6)),
  Palette('torride', Color(0xFF1E0D13), Color(0xFFF8E9E6), Color(0xFFE02A50), Color(0xFFFFF4F2), Color(0xFF561A2C), Color(0xFF34121D), Color(0xFF7A2A42)),
  Palette('nature', Color(0xFF2B2A24), Color(0xFFF2EFE4), Color(0xFFD19A4E), Color(0xFF2B2A24), Color(0xFF3A4733), Color(0xFF2F3A2B), Color(0xFF566650)),
];

/// The app's default: black on white, as before the themes.
const String kDefaultTheme = 'light';

bool isTheme(String name) => kPalettes.any((p) => p.name == name);

/// The palette of a theme name; an unknown name gives the default.
Palette paletteOf(String name) => kPalettes.firstWhere((p) => p.name == name, orElse: () => paletteOf(kDefaultTheme));

/// The theme after this one, round and round: the inks first, then the palettes.
String nextThemeAfter(String name) => kPalettes[(kPalettes.indexWhere((p) => p.name == name) + 1) % kPalettes.length].name;

/// The name of a theme, as the settings row and the menu show it.
String themeName(String name) => t(const {
      'dark': 'white on black', 'light': 'black on white', 'lavande': 'lavender', 'sauge': 'sage', 'nordique': 'nordic',
      'terracotta': 'terracotta', 'coquette': 'coquette', 'militante': 'activist', 'torride': 'sultry', 'nature': 'nature',
    }[name] ?? name);
