# vita_debug_strip

A strip of live console numbers as a widget, for a Flutter app on the
PlayStation Vita. The strip shows what the console does this second: fps,
the UI thread's time, the raster time, GPU busy, the four cores, RAM,
CDRAM, the heap, the battery.

The engine has a strip of its own (L+R+SELECT). This one adds the number
only Dart can see, the UI thread's time per frame, and a place in the
app's own layout.

## Use

Over any app, shown and hidden with L+R+TRIANGLE:

```dart
runApp(VitaDebugOverlay(child: MyApp()));
```

Inside the app's theme, or as a title bar:

```dart
MaterialApp(builder: (context, child) => VitaDebugOverlay(child: child!))

Column(children: [const VitaStrip(), Expanded(child: body)])
```

`VitaDebugOverlay(inset: true)` lays the app out under the strip instead
of over its top 34 px. `VitaStrip(frozen: true)` draws the strip and
stops its tick, for a benchmark.

The numbers come from the embedder's `vita/stats` channel twice a second.
`VitaStatsChannel.read()` gives them to app code as a `VitaStats`.

## Cost

The tick costs a frame twice a second. The gallery measured it through
its benchmark scenes: 23 stalled scenes with the strip, 16 with it frozen.
Freeze it or hide it while you measure.

## Requirements

Flutter 3.44 built with the [flutter-vita](https://github.com/flutter-vita/flutter-vita)
tool. The package depends on `flutter_vita`, whose C half reads the button
chord and starts the engine's own strip hidden, so the two do not overlap.
