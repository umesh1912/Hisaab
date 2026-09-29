# How every app in this repo is built

Each app lives in `apps/<name>/` and is built into an APK by `.github/workflows/build.yml`
(flutter create → patch manifest → pub get → analyze → **test** → launcher icons → build apk → GitHub Release).
**`apps/hisaab/` is the reference implementation. Read it first and copy its patterns.**

Nobody can run Flutter locally (no SDK; pub.dev is blocked). The code is compiled and tested only in CI,
so write conservative, well-typed Dart that compiles first time.

## Required files
```
apps/<name>/
  app_label.txt          # display name, e.g. Lenden (one line, no spaces ideally)
  pubspec.yaml           # copy hisaab's; change name/description/icon background colour only
  analysis_options.yaml  # copy hisaab's
  assets/icon.png, assets/icon_fg.png   # python3 tools/make_icon.py apps/<name> "#HEX" "G"
  lib/main.dart          # theme, StoreScope, Gate (onboarding vs shell), Shell with NavigationBar
  lib/logic.dart         # models with toJson/fromJson + pure functions (no Flutter imports)
  lib/store.dart         # <App>Store extends ChangeNotifier; load/save JSON in SharedPreferences; sampleData()
  lib/ui.dart            # StoreScope (InheritedNotifier), shared widgets, showAppSheet, toast
  lib/screens/*.dart, lib/sheets/*.dart
  test/logic_test.dart   # unit tests for the pure logic
  test/widget_test.dart  # smoke test at phone size (see below)
```

## Rules
- Package name == folder name (lowercase). Imports: `package:<name>/...` in tests, relative inside lib.
- Dependencies allowed: `shared_preferences`, `url_launcher` (already in hisaab's pubspec). Do NOT add others.
  No Firebase, no network, no images from the internet, no custom fonts. Offline-first, data on device.
- Material 3, `ColorScheme.fromSeed(seedColor: <brand>)`, light + dark themes, like hisaab `buildTheme`.
- Use `CardThemeData` (not CardTheme). Do not use `withOpacity` or `Color.withValues`; use colorScheme container colours.
  `DropdownButtonFormField` uses `initialValue:` (not `value:`).
- Everything must fit a 360 x 800 dp phone: never put several buttons in a `Row` without `Expanded`/`Flexible`;
  prefer `Wrap` for button groups and chips; long text in rows needs `Expanded` + `overflow: TextOverflow.ellipsis`;
  fixed-height boxes (charts) must leave room for labels (use FittedBox for numbers).
- Lazy lists: bottom sheets use `showAppSheet` (scrollable, keyboard-safe) from hisaab's ui.dart.
- When a sheet can outlive the data it shows (delete / reset), guard for null instead of using `!`.
- Onboarding screen offers real setup AND "Explore with sample data". Sample data dates are relative to today.
- Store data as JSON under one SharedPreferences key `<name>_data_v1`. Wrap load in try/catch.
- Money in integer paise; format with Indian grouping (copy `inr` from hisaab logic.dart if needed).
- External actions (WhatsApp share `https://wa.me/?text=`, `tel:`, UPI `upi://pay?...`, maps
  `https://www.google.com/maps/search/?api=1&query=`) go through `launchUrl(..., mode: LaunchMode.externalApplication)`.
- Local notifications / background work / camera / location are NOT available (no plugins). Where the prototype
  has those, substitute honest in-app equivalents (a "Due today" list, manual entry, a "Share" button).

## Widget test (must pass)
Copy the structure of `apps/hisaab/test/widget_test.dart`: set `tester.view.physicalSize = Size(1080, 2400)`,
`devicePixelRatio = 3`, `SharedPreferences.setMockInitialValues({})`, load the store, pump the app,
`scrollUntilVisible` to the sample-data button, tap it, visit EVERY NavigationBar tab with `pumpAndSettle`,
open the main add/create sheet(s), and finally `expect(tester.takeException(), isNull)`.
A RenderFlex overflow anywhere fails the build, so this test is how layout bugs get caught.
Be careful that the texts you `find.text(...)` are unique on screen (a FAB label and a sheet title
with the same words gives 2 matches) — prefer `find.byType(FloatingActionButton)`, `find.byTooltip`, or keys.
Avoid anything that animates forever (e.g. an indeterminate progress indicator on a loaded screen) — `pumpAndSettle` would time out.
