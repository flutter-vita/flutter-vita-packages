# vita_file_browser

A helper package for PS Vita support in a Flutter app: a file browser for
the PlayStation Vita. It works with
[flutter-vita](https://github.com/flutter-vita/flutter-vita), the tool that
builds Flutter apps for the console.

The console has no file-chooser dialog: no Intent, no document picker, no
portal. This package pushes a browser route onto the app's own Navigator,
in the app's theme, and returns paths. `flutter_vita`, `file_picker_vita`
and `file_selector_vita` open it.

## Use

```dart
import 'package:vita_file_browser/vita_file_browser.dart';

final paths = await browseForPaths(
  mode: FileBrowserMode.openFile,
  allowedExtensions: ['jpg', 'png'],
  allowMultiple: true,
  initialDirectory: 'ux0:picture/',
);
// null when the user closes the browser
```

| Mode | Returns |
|---|---|
| `FileBrowserMode.openFile` | One file, or many with `allowMultiple: true` |
| `FileBrowserMode.pickDirectory` | One directory |
| `FileBrowserMode.saveInDirectory` | The directory to write `saveFileName` into. The caller names the file. |

No `BuildContext` is needed. The browser finds the root Navigator itself
(`findRootNavigator()`), because the plugin interfaces it serves have no
context to pass.

`VitaPaths.candidates` lists the mounts a console can have (`ux0:`,
`ur0:`, `uma0:`, `imc0:`, `xmc0:`) and `VitaPaths.isVita` says whether
the app runs on a console.

## Who uses it

`file_picker_vita` and `file_selector_vita` in the
[flutter-vita](https://github.com/flutter-vita/flutter-vita) tool translate
their plugin interfaces into `browseForPaths`. `flutter_vita`'s
`image_picker` fallback opens it over `ux0:picture/` and `ux0:video/`.

## Requirements

Flutter 3.44 built with the flutter-vita tool. The package has no C half.
