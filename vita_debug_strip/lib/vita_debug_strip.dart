/// The strip of live console numbers above the gallery's tabs, as a widget
/// any app can carry, and a button chord that shows and hides it.
///
/// Three pieces:
///
///   [VitaStrip]         the two-row table: fps, UI and raster time, GPU
///                       busy, the cores, memory, heap, battery
///   [VitaDebugOverlay]  the strip over an app, toggled by L + R + TRIANGLE
///
/// The numbers come from the embedder's `vita/stats` channel, which every
/// app has; the chord from `flutter_vita`'s `VitaPad` (its C half,
/// compiled into the app because the package is in the pubspec, ADR-0020).
/// `flutter_vita` also sets the engine's own strip to start hidden, so the
/// two never overlap; L + R + SELECT brings the engine's back.
///
/// What this strip adds over the engine's is what only Dart can see, the
/// UI thread's build time per frame, and a place in the app's own layout.
library;

export 'package:flutter_vita/flutter_vita.dart' show VitaButtons, VitaPad;

export 'src/overlay.dart';
export 'src/stats.dart';
export 'src/strip.dart';
