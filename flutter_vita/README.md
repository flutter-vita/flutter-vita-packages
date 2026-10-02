# flutter_vita

One call at start-up. After it, a Flutter app behaves like a console app on
the PlayStation Vita.

```dart
import 'package:flutter_vita/flutter_vita.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterVita.configure(
    pad: PadMode.focus,
    rearTouch: RearTouch.scroll,
    pixelRatio: 1.5,
    fallbacks: {Fallback.share, Fallback.urlLauncher, Fallback.imagePicker},
  );
  runApp(const MyApp());
}
```

Each argument is optional. Each call is a delta: a later
`configure(pad: PadMode.cursor)` changes the pad and nothing else. On a
desktop or a phone, each call does nothing. The same `main` runs there.

The package talks to the embedder on the channel `vita/config`. The tool
compiles the package's C half (`vita/pad.c`) into the app. No app code
registers it.

## What you can set

| Argument | Values | Effect |
|---|---|---|
| `debugStrip` | `shortcut` (default), `always`, `hidden` | The engine's debug strip in a debug build. `shortcut`: hidden until L+R+SELECT. A release build never draws it. |
| `keepAwake` | `true` (default), `false` | Stop the console's screen dimmer and sleep while the app runs. |
| `watchdog` | `true` (default), `false` | The stall watchdog that hands the console to the bridge after a long stall. |
| `pixelRatio` | 0.5 to 3.0, default 1.0 | Flutter's device pixel ratio. 960x544 physical pixels stay. At 1.5 the app lays out for 640x362 logical pixels, and text and buttons become larger. |
| `pad` | `none` (default), `focus`, `cursor` | `focus`: the D-pad and the left stick move Flutter's focus, X activates, O dismisses or goes back. `cursor`: the left stick moves an arrow and X presses. The embedder draws the arrow. |
| `rearTouch` | `none` (default), `scroll` | `scroll`: a finger on the rear panel scrolls the widget under the last front touch, or under the cursor. |
| `cpuClock` | `normal` (default), `high` | `high`: 444 MHz CPU, with the bus and the GPU raised to match. More frames, less battery. |
| `onExit` | `auto` (default), `handoff`, `exit`, `ignore` | What `SystemNavigator.pop()` and `System.exitApplication` do. `auto` is `handoff` in a debug build and `exit` in a release build. `handoff` gives the console to the bridge. `exit` goes to the LiveArea. |
| `psButton` | `system` (default), `locked` | `locked`: the PS button does nothing while the app runs. The lock ends with the process. |
| `fallbacks` | a set of `share`, `urlLauncher`, `imagePicker` | Answers for phone plugins that have no Vita side. See below. |

## Fallbacks

Some plugins do things a console cannot do. With a fallback on, the plugin's
Dart API works and the console does the nearest thing:

| Fallback | Plugin | What the console does |
|---|---|---|
| `share` | `share_plus` | Writes the text or the files to `ux0:data/<title id>/shared/` and shows a toast. The plugin gets its success result. |
| `urlLauncher` | `url_launcher` | `http` and `https` open the console's browser. `mailto`, `tel` and `sms` show the address with a Copy button. |
| `imagePicker` | `image_picker` | Opens the file browser of `vita_file_browser` at `ux0:picture/` or `ux0:video/`. The camera source returns null. |

A fallback answers only when the app has no Vita implementation of that
plugin. If the app depends on `url_launcher_vita`, that package answers and
the fallback does nothing.

## Info and log

```dart
final info = await FlutterVita.info();   // null off the console
print(info?.armMhz);                     // 333 or 444
await FlutterVita.log('level loaded');   // "app: info level loaded" in flutter-vita logs
```

`VitaInfo` has: `titleId`, `engineRevision`, `flutterVersion`,
`embedderVersion`, `release`, `backend`, `pixelRatio`, `batteryPercent`,
`charging`, `freeMemoryK`, `freeCdramK`, `armMhz`, `gpuMhz`.

## The pad from app code

`VitaPad` is the controller behind `pad: focus`. An app can read it directly:

```dart
final state = await VitaPad.read();           // buttons and both sticks
VitaPad.chord(VitaButtons.l | VitaButtons.r | VitaButtons.triangle)
    .listen((_) => toggleMenu());             // every press of the chord
```

A `chord` or `nav` stream parks one thread on the console. A Dart timer
does not poll the channel.

## What is not here

A build decides these, not a call: the title id, the LiveArea assets, the
heap size, and `--release` (no dev server, no debug strip). They are in the
pubspec's `vita:` block and in the `flutter-vita build` flags. See the tool's
[release-app.md](https://github.com/flutter-vita/flutter-vita/blob/main/docs/release-app.md).

## Requirements

Flutter 3.44 built with the [flutter-vita](https://github.com/flutter-vita/flutter-vita)
tool, embedder 0.2.0 or later. An app built with an older embedder gets no
answer on `vita/config`; the package then does nothing.
