# Reader's Feeds

A black-and-white, text-only RSS and Atom reader for Android, in the family of
[Reader's Launcher](https://github.com/funkypitt/readers-launcher),
[Reader's Tasks](https://github.com/funkypitt/readers-tasks-android) and
[Reader's Calendar](https://github.com/funkypitt/readers-calendar). Born from
[Pluralis](https://github.com/funkypitt/pluralis), whose fetching, extraction and
pagination it keeps; everything you see was redrawn.

One list: the latest articles of your sources, title in black, source and age in grey.
Tap to read the article as pages, extracted from the web page and cut at whole lines: the
right half of the screen turns forward, the left half back. Long-press an article to save
it for later, open it in the browser or share it. The ⋯ menu leads to the sources, the saved
articles, the settings, and flips white on black. No icons, no colours, no cards.

## Sources

Any RSS or Atom feed. Paid Substack publications work after signing in (the cookie stays on
the device). OPML import and export, and a CSV of your Substacks with their cookies, so the
list travels between devices. Tap the box to enable or disable a source, its name to see its
own articles, long-press for the rest.

## E-ink

Everything is two colours and no animation. In the settings, "pages" makes the lists turn
pages instead of scrolling. The reading face can be serif. The text size starts from the
screen size and can be pushed in either direction from the settings or the reader's menu.

## Home-screen widget

The latest titles as a plain list, source under each; tap one to open it.

## Install

From the [F-Droid repo](https://funkypitt.github.io/fdroid-repo/) or the APK attached to a
release. Build: `flutter pub get && flutter build apk --release`.

## Licence

GPL-3.0, as Pluralis.
