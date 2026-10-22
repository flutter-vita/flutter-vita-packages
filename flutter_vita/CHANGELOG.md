## 0.1.1

- The README and the package description say first that the package adds
  PS Vita support, with a link to the flutter-vita tool.

## 0.1.0

- First version: `FlutterVita.configure` with the debug strip, keep-awake,
  the watchdog, the pixel ratio, the pad as focus or as a cursor, the rear
  panel as a trackpad, the clocks, the exit behaviour, the PS button, and
  Dart fallbacks for `share_plus`, `url_launcher` and `image_picker`.
- `FlutterVita.info` and `FlutterVita.log`.
- `FlutterVita.isPSVita`: true on the console, where `Platform.isLinux` is
  true too.
- `VitaPad` and `VitaButtons`, moved here from `vita_debug_strip`.
