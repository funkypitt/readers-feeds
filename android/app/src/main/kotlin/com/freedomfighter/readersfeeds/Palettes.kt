package com.freedomfighter.readersfeeds

import android.content.Context

/**
 * The colour themes of the app, the same values as lib/ui/palettes.dart: the home-screen widget
 * reads the theme setting Flutter stores and paints itself with the theme's background and text.
 */
data class Palette(val name: String, val bg: Int, val fg: Int, val accent: Int, val onAccent: Int)

object Palettes {
    val ALL = listOf(
        Palette("dark", 0xFF000000.toInt(), 0xFFFFFFFF.toInt(), 0xFFFFFFFF.toInt(), 0xFF000000.toInt()),
        Palette("light", 0xFFFFFFFF.toInt(), 0xFF000000.toInt(), 0xFF000000.toInt(), 0xFFFFFFFF.toInt()),
        Palette("lavande", 0xFF1F1A2E.toInt(), 0xFFF4EFFF.toInt(), 0xFFB8A4FF.toInt(), 0xFF1F1A2E.toInt()),
        Palette("sauge", 0xFFD9E0D4.toInt(), 0xFF1E2A21.toInt(), 0xFF4C7A5B.toInt(), 0xFFFFFFFF.toInt()),
        Palette("nordique", 0xFF2E3440.toInt(), 0xFFECEFF4.toInt(), 0xFF88C0D0.toInt(), 0xFF2E3440.toInt()),
        Palette("terracotta", 0xFFE6D9CC.toInt(), 0xFF2B211B.toInt(), 0xFFC25E38.toInt(), 0xFFFFFFFF.toInt()),
        Palette("coquette", 0xFFF3D9DC.toInt(), 0xFF4A1F2B.toInt(), 0xFFD2455E.toInt(), 0xFFFFFFFF.toInt()),
        Palette("militante", 0xFFF2EEE4.toInt(), 0xFF121212.toInt(), 0xFFE8412E.toInt(), 0xFFFFFFFF.toInt()),
        Palette("torride", 0xFF1E0D13.toInt(), 0xFFF8E9E6.toInt(), 0xFFE02A50.toInt(), 0xFFFFF4F2.toInt()),
        Palette("nature", 0xFF2B2A24.toInt(), 0xFFF2EFE4.toInt(), 0xFFD19A4E.toInt(), 0xFF2B2A24.toInt()),
    )

    /** An unknown name gives the app's default, black on white. */
    fun of(name: String?): Palette = ALL.firstOrNull { it.name == name } ?: ALL[1]

    /**
     * The theme chosen in the app. Flutter's shared_preferences keeps it in "FlutterSharedPreferences"
     * under "flutter.theme"; before 1.4.0 it was the flag "flutter.dark".
     */
    fun current(context: Context): Palette {
        val sp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val name = runCatching { sp.getString("flutter.theme", null) }.getOrNull()
            ?: if (runCatching { sp.getBoolean("flutter.dark", false) }.getOrDefault(false)) "dark" else "light"
        return of(name)
    }

    /** The text colour at the opacity of the secondary lines. */
    fun dim(fg: Int): Int = (fg and 0x00FFFFFF) or (0x8C shl 24)

    /** The text colour at the opacity of the hairlines between rows. */
    fun rule(fg: Int): Int = (fg and 0x00FFFFFF) or (0x40 shl 24)
}
