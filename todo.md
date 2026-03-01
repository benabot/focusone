# FocusOne TODO

## Install issues (simulator)
- Run `Product > Clean Build Folder` in Xcode.
- If install still fails: quit app on Simulator, then `Simulator > Erase All Content and Settings`.
- Verify app target settings:
- `TARGETS > FocusOne > Build Settings > Packaging > Generate Info.plist File = Yes`.
- `TARGETS > FocusOne > Build Settings > Packaging > Info.plist File` should be empty for the app target.
- Verify generated app Info keys in Build Settings:
- `Product Bundle Identifier` non vide.
- `Info.plist` contains valid `CFBundleExecutable` and `CFBundleIdentifier` in built product.

## Fix Missing bundle ID
- [x] App target (`FocusOne`) Bundle Identifier set to `com.benoit.focusone`.
- [x] Widget target (`FocusOneWidget`) Bundle Identifier set to `com.benoit.focusone.widget`.
- [x] Debug + Release have explicit `PRODUCT_BUNDLE_IDENTIFIER` for both targets.
- [x] `Info.plist` app + widget include `CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)`.
- Verify in Xcode: `TARGETS > FocusOne > Signing & Capabilities > Bundle Identifier`.
- Verify in Xcode: `TARGETS > FocusOneWidget > Signing & Capabilities > Bundle Identifier`.
- Verify in Xcode: `TARGETS > Build Settings > Packaging > Product Bundle Identifier`.
- Cleanup after config change: `Product > Clean Build Folder`, delete DerivedData for `FocusOne`, then `Simulator > Erase All Content and Settings` if install still fails.

## Fix widget install error
- [x] Widget `Info.plist` cleaned from forbidden key `NSExtensionMainStoryboard` (must not exist).
- [x] Widget `Info.plist` cleaned from forbidden key `NSExtensionPrincipalClass` for `com.apple.widgetkit-extension`.
- [x] Widget `Info.plist` keeps required key `NSExtensionPointIdentifier = com.apple.widgetkit-extension`.
- File to check: `FocusOneWidget/Resources/Info.plist`.
- Xcode path to verify: `TARGETS > FocusOneWidget > Build Settings > Packaging > Info.plist File`.
- Recovery steps in order: `Product > Clean Build Folder` -> delete DerivedData for `FocusOne` -> `Simulator > Erase All Content and Settings` -> run `FocusOne` (`⌘R`).

## WidgetKit plist rules
- For `com.apple.widgetkit-extension`, do not include `NSExtensionMainStoryboard`.
- For `com.apple.widgetkit-extension`, do not include `NSExtensionPrincipalClass`.
- Keep only `NSExtensionPointIdentifier = com.apple.widgetkit-extension` plus widget attributes.
- If app install must be unblocked quickly, temporarily disable widget embed:
- `TARGETS > FocusOne > Build Phases > Embed Foundation Extensions` and remove `FocusOneWidget.appex`.
- After widget plist is validated, re-enable embed by adding `FocusOneWidget.appex` back in the same phase.

## Manual Xcode checks (Signing & Capabilities)
- Open `FocusOne.xcodeproj`.
- Select target `FocusOne` > `Signing & Capabilities`.
- Set Team and confirm Bundle Identifier `com.benoit.focusone`.
- Ensure capability `iCloud` is enabled with CloudKit and container `iCloud.com.benoit.focusone`.
- Ensure capability `App Groups` is enabled with `group.com.benoit.focusone`.
- Select target `FocusOneWidget` > `Signing & Capabilities`.
- Ensure `App Groups` is enabled with `group.com.benoit.focusone`.
- If IDs differ, update `FocusOne/App/AppConfig.swift`.

## UI polish (Headspace-like)
- Validate spacing and corner radii across screens (16/20/24 tokens).
- Validate dark mode contrast on Onboarding/Home/Stats/Settings/Paywall.
- Validate micro-animations: `DoneToggleButton` pulse and Home progress transition.

## Widgets
- Verify `systemSmall` widget on Home Screen.
- Verify `accessoryRectangular` and `accessoryCircular` on Lock Screen.
- Verify snapshot strategy: app writes JSON to App Group, widget reads from App Group.
- Validate widget fallback behavior if App Group is missing.

## Widget App Groups (manual if needed)
- Open `FocusOne.xcodeproj`.
- Select target `FocusOne` -> `Signing & Capabilities` -> `+ Capability` -> `App Groups`.
- Enable and check `group.com.benoit.focusone`.
- Select target `FocusOneWidget` -> `Signing & Capabilities` -> `+ Capability` -> `App Groups`.
- Enable and check `group.com.benoit.focusone`.
- Verify entitlements paths:
- `FocusOne/Resources/FocusOne.entitlements`
- `FocusOneWidget/FocusOneWidget.entitlements`
- Clean with `Product > Clean Build Folder`, erase simulator content if needed, then run `FocusOne`.

## iCloud sync
- Run with same Apple ID on 2 devices or 2 simulators.
- Create/toggle habit on device A and confirm sync on device B.
- Validate CloudKit sync for `HabitEntity`, `CompletionEntity`, `CycleEntity`.

## Localization FR + EN
- Validate all app screens in English and French.
- Validate widget localized strings in English and French.
- Validate pluralization for streak (`1 day` / `2 days`, `1 jour` / `2 jours`).

## Notifications
- Test permission prompt on first onboarding.
- Test 0/1/2 reminders scheduling.
- Note: local notifications are more reliable on real device than simulator.

## Fixed
- [x] App apparaît 2x sur l'écran d'accueil : bundle ID Debug aligné sur Release (`com.benoit.focusone`). Widget idem.
- [x] AppRouter refactorisé : routing simplifié, plus de double setState en `onAppear`.
- [x] HomeView redesign : streak card avec gradient + blobs, meta pills, reminder chip, topBar icône.
- [x] DoneToggleButton : animation press + sparkle + shadow dynamique + état outlined/filled.
- [x] StatsView : streak cards colorées par thème, grille calendrier avec jours de la semaine, couleur preset.
- [x] StatsViewModel : expose `themeHex` pour que StatsView adapte les couleurs.
- [x] L10n : ajout `streakUnit`, `home.streak.label`, `home.streak.keep_going` EN + FR.

## Later
- Keep `PremiumGate` as feature-flag layer and add StoreKit purchase flow.
