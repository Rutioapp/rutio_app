# Rutio App Icon And Native Launch Branding

## Source Asset

- Provided file: `D:\Downloads\Nuego logo rutio Sin fondo.png`
- Copied source: `assets/branding/rutio_logo_source_1254.png`
- Actual provided dimensions: `1254x1254`
- Canonical master used for generated app assets: `assets/branding/rutio_logo_master_1024.png`
- Canonical master dimensions: `1024x1024`
- The provided source was preserved without downscaling or overwriting.

## Generated Assets

- `assets/branding/rutio_logo_master_1024.png`: canonical transparent 1024 asset.
- `assets/branding/generated/rutio_logo_512.png`: 512 derivative for lightweight review or future tooling needs.
- `assets/branding/generated/rutio_logo_android_icon_1024.png`: opaque Android legacy launcher source.
- `assets/branding/generated/rutio_logo_ios_icon_1024.png`: opaque iOS AppIcon source.
- `assets/branding/generated/rutio_logo_adaptive_foreground_1024.png`: transparent Android adaptive foreground source.
- `assets/branding/generated/branding_metrics.json`: source and master bounding box metrics.
- `android/app/src/main/res/drawable-*/splash_logo.png`: Android 11 and lower native launch bitmap.
- `android/app/src/main/res/drawable-*/splash_logo_icon.png`: Android 12+ safe splash icon.
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png`: iOS native launch images.

## Centering Strategy

The input PNG has uneven transparent padding around the visible icon. The generator crops the alpha bounding box, scales the visible logo without distortion, and composites it into square canvases with balanced padding.

Measured input alpha bbox:

- Source size: `1254x1254`
- Source bbox: `(371, 346, 881, 893)`
- Source margins: left `371`, top `346`, right `373`, bottom `361`

Canonical master alpha bbox:

- Master size: `1024x1024`
- Master bbox: `(120, 92, 903, 932)`
- Master margins: left `120`, top `92`, right `121`, bottom `92`

Adaptive foreground alpha bbox:

- Size: `1024x1024`
- Bbox: `(158, 132, 867, 892)`
- Margins: left `158`, top `132`, right `157`, bottom `132`

## Android Configuration

The project uses `flutter_launcher_icons` for app launcher icons and manual native Android launch screen resources.

`pubspec.yaml` config:

- `android: true`
- `ios: true`
- `image_path_android: assets/branding/generated/rutio_logo_android_icon_1024.png`
- `image_path_ios: assets/branding/generated/rutio_logo_ios_icon_1024.png`
- `adaptive_icon_background: "#CFA683"`
- `adaptive_icon_foreground: assets/branding/generated/rutio_logo_adaptive_foreground_1024.png`
- `adaptive_icon_foreground_inset: 8`
- `remove_alpha_ios: true`

Adaptive icon:

- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- Background: `@color/ic_launcher_background` (`#CFA683`)
- Foreground: `@drawable/ic_launcher_foreground` with `8%` inset.

Android 12+ native launch:

- `android/app/src/main/res/values-v31/styles.xml`
- `android/app/src/main/res/values-night-v31/styles.xml`
- Background: `@color/launch_splash_background` (`#CFE4F2`)
- Animated icon: `@drawable/splash_logo_icon`
- Icon background: transparent `@color/launch_splash_icon_background`
- Normal theme remains connected through Flutter's `io.flutter.embedding.android.NormalTheme` manifest metadata.

Android 11 and lower native launch:

- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- Uses uniform Rutio blue (`#CFE4F2`) and centered `@drawable/splash_logo`.
- `values-night` uses the same light launch appearance to avoid a black launch screen in dark mode.

## iOS Configuration

AppIcon:

- `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- All referenced `Contents.json` icon files were regenerated from the opaque 1024 iOS icon source.
- No manual corner radius or circular mask was applied.
- The icons are opaque to avoid App Store alpha issues.

LaunchScreen:

- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- Uses `LaunchImage` centered with `scaleAspectFit`.
- Image view constraints: `168x168`.
- Background color: `#CFA683`.
- Launch images generated at `168x168`, `336x336`, and `504x504`.

## Post Manual QA Adjustment

Manual testing showed two issues: the native launch logo block felt visibly cut against the sky background, and the launcher icon read too small on the Home Screen.

Changes applied:

- Native launch background changed from sky blue `#CFE4F2` and Android pre-12 sky gradient to uniform camel `#CFA683`, matching the logo block color.
- Android 12+ `windowSplashScreenBackground` now resolves to `#CFA683`.
- Android 11 and lower `launch_background.xml` and `drawable-v21/launch_background.xml` now use a solid camel fill instead of the sky gradient.
- iOS LaunchScreen background changed from `#CFE4F2` to `#CFA683`.
- Launcher icon visible source scale changed from `900/1024` to `980/1024`.
- Adaptive icon foreground visible scale changed from `620/1024` to `760/1024`.
- Adaptive icon XML inset changed from `16%` to `8%`.

Expected visual result:

- On native launch, the logo block blends into the camel background so only the white Rutio mark has strong visual contrast.
- On Android and iOS launchers, the R has more presence while still retaining safe padding for rounded and circular masks.
- The visual center is preserved by alpha-bbox cropping and balanced square recomposition.

## Android Native Launch Mask Adjustment

Manual Android 12+ testing showed that the system splash mask could visually cut the camel block when the splash logo occupied too much of the icon viewport. The app launcher icon and iOS assets were intentionally left unchanged for this adjustment.

Changes applied:

- Current camel splash background before this correction: `#CFA481`.
- Previous Android splash blue recovered from this document's earlier branding history: `#CFE4F2`.
- Android 12+ `windowSplashScreenBackground` restored to `#CFE4F2`.
- Android 11 and lower `launch_background.xml` and `drawable-v21/launch_background.xml` restored to a solid `#CFE4F2` fill.
- Android dark-mode variants use the same `LaunchTheme`, `NormalTheme`, `launch_splash_background`, and `launch_background` resources, so they also resolve to `#CFE4F2`.
- `splash_logo_icon.png` visible occupancy changed from about `63.89%` to about `60.07%`.
- `splash_logo.png` visible occupancy changed from about `89.29%` to about `60.71%`.
- The Android splash resources are generated from `assets/branding/rutio_logo_master_1024.png` with transparent square canvases, alpha-bbox centering, and no distortion.

Final Android splash bounding boxes:

- `drawable-mdpi/splash_logo_icon.png`: canvas `288x288`, bbox `(64, 58, 225, 231)`, margins left `64`, top `58`, right `63`, bottom `57`.
- `drawable-mdpi/splash_logo.png`: canvas `168x168`, bbox `(36, 33, 131, 135)`, margins left `36`, top `33`, right `37`, bottom `33`.

The launcher icon keeps its separate adaptive foreground and icon-generation path so desktop icon appearance is not coupled to Android's system splash mask constraints.

## Launcher Label And Optical Centering Adjustment

Manual launcher review showed the Android app label as lowercase `rutio` and the Rutio mark felt slightly off-center inside the launcher mask.

Name changes:

- Android previous launcher label: `rutio`, defined directly in `android/app/src/main/AndroidManifest.xml`.
- Android new launcher label: `Rutio`.
- iOS was already configured as `Rutio` in both `CFBundleDisplayName` and `CFBundleName`.

Icon diagnosis:

- No real rotation was found in the source block. Edge fitting on the visible camel block measured approximately `0.006` degrees or less from horizontal/vertical.
- The perceived tilt came from the stylized R shape and its diagonal leg, not from a rotated bitmap.
- The visible white R mass was optically low and left in the generated launcher icons.

Launcher source before adjustment:

- File: `assets/branding/generated/rutio_logo_android_icon_1024.png`
- White R bbox: `(275, 232, 773, 837)`
- White R margins: left `275`, top `232`, right `251`, bottom `187`
- White R centroid offset from canvas center: `(-10.09, 7.54)`

Launcher source after adjustment:

- File: `assets/branding/generated/rutio_logo_android_icon_1024.png`
- White R bbox: `(285, 224, 783, 829)`
- White R margins: left `285`, top `224`, right `241`, bottom `195`
- White R centroid offset from canvas center: `(-0.09, -0.46)`

Adaptive foreground before adjustment:

- White R bbox: `(328, 295, 715, 764)`
- White R margins: left `328`, top `295`, right `309`, bottom `260`

Adaptive foreground after adjustment:

- White R bbox: `(338, 287, 725, 756)`
- White R margins: left `338`, top `287`, right `299`, bottom `268`

Applied correction:

- `tool/generate_branding_assets.py` now applies a launcher-only optical offset of `(10, -8)` pixels on the 1024 source canvases.
- This shifts the icon composition slightly right and up for Android launcher, Android adaptive foreground, and iOS AppIcon sources.
- No rotation correction was applied because the source was already geometrically straight.
- The app launcher path remains separate from Android native splash assets, iOS LaunchScreen assets, and Flutter splash.

## Commands

Generation commands:

```powershell
python tool\generate_branding_assets.py
dart run flutter_launcher_icons
```

Validation commands:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter build apk --debug --dart-define-from-file=dart_defines/dev.json
```

## Manual QA

Android pending manual checks:

- Clean uninstall and reinstall.
- Open from launcher icon.
- Verify launcher icon in light and dark mode.
- Verify native launch screen in light and dark mode.
- Verify circular and rounded launcher masks where the device launcher allows it.

iOS pending manual checks:

- Build and install from macOS/Xcode.
- Verify Home Screen icon.
- Verify Launch Screen on multiple iPhone sizes.
- Verify iPad if supported.
- Verify light and dark mode.
- Verify transition from iOS Launch Screen to Flutter splash.

## Windows Limitation

This work was done on Windows. Android can be built locally here, but `flutter build ios --no-codesign` requires macOS/Xcode. iOS validation in this environment is limited to asset, `Contents.json`, and storyboard inspection.
