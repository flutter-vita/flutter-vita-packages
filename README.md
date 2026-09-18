# flutter-vita packages

Pub packages of the [flutter-vita](https://github.com/flutter-vita/flutter-vita)
project with an API of their own, one directory each. The Vita
*implementations* of upstream plugins (`path_provider_vita`,
`audioplayers_vita` and the rest) are not here; they live in the tool's
[`plugins/`](https://github.com/flutter-vita/flutter-vita/tree/master/plugins).

| Package | What it is |
|---|---|
| `flutter_vita` | One call in `main()` sets the app up for the console: pad navigation or a cursor, the rear panel as a trackpad, the pixel ratio, the debug strip, the clocks, what exit does, and Dart fallbacks for `share_plus`, `url_launcher` and `image_picker`. Its C half is the controller channel `vita/pad`. |
| `vita_debug_strip` | The strip of live console numbers as a widget, for an app that wants the UI thread's time on screen beside the engine's own strip. It depends on `flutter_vita`, whose C half starts the engine's strip hidden so the two do not overlap; L+R+SELECT brings the engine's back. |
| `vita_file_browser` | A file browser drawn in Flutter, for a console with no file-chooser dialog. `file_picker_vita` and `file_selector_vita` open it. |

## Using one

Path dependencies today; publishing to pub.dev is planned and the names
stay. The tool carries this repository as a git submodule at `packages/`,
so from an app inside the tool's tree:

```yaml
dependencies:
  vita_debug_strip:
    path: ../../packages/vita_debug_strip
```

From anywhere else, a git dependency:

```yaml
  vita_debug_strip:
    git:
      url: https://github.com/flutter-vita/flutter-vita-packages.git
      path: vita_debug_strip
```

## Versions

Plain semver per package, `0.1.0` today, and `flutter: ">=3.44.0"`. A
package's tag, when it is published, is `<name>-v<version>`.

## Licence

BSD 3-Clause, see [LICENSE](LICENSE).
