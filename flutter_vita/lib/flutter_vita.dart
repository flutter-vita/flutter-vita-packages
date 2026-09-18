/// Set up a Flutter app for the PlayStation Vita from one call.
///
/// `FlutterVita.configure(...)` before `runApp`: the pad as focus or as a
/// cursor, the rear panel as a trackpad, the layout density, the debug strip,
/// the clocks, what leaving means, and Dart fallbacks for plugins the console
/// has no side for. Every argument is optional; on any other platform the
/// call does nothing.
library;

export 'src/config.dart';
export 'src/pad.dart';
