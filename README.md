# FocusOne

FocusOne is a minimal SwiftUI iOS habit app built around one micro-habit at a time. The app is intentionally narrow: one active habit, one-tap daily check-in, simple feedback, and contextual premium access only when the user needs more depth.

## What It Is

- One active habit at a time.
- Fast daily loop: open app, tap done, leave.
- Native-feeling iOS UI over dashboard complexity.
- Premium is contextual, not intrusive.

## Tech Stack

- SwiftUI
- Core Data
- CloudKit wiring in code, but blocked on Personal Team provisioning
- WidgetKit
- UserNotifications
- StoreKit 2
- FR/EN localization with `.strings` and `.stringsdict`
- No backend
- No third-party package dependencies

## Project Structure

- `FocusOne/App`: app entry point, routing, app config
- `FocusOne/Features/Onboarding`: habit creation and edit flow
- `FocusOne/Features/Home`: daily check-in flow
- `FocusOne/Features/Stats`: streaks, monthly calendar, full-history entry point
- `FocusOne/Features/Settings`: reminders, day boundary, themes, iCloud info, premium access
- `FocusOne/Features/Paywall`: StoreKit-backed yearly/lifetime paywall
- `FocusOne/Domain`: models and services such as `PremiumGate`, `StreakEngine`, `NotificationsService`
- `FocusOne/Persistence`: Core Data entities, repository, persistence controller
- `FocusOne/SharedUI`: shared theme and layout primitives
- `Widgets`: widget extension code and shared widget snapshot storage
- `FocusOneWidget/Resources`: widget `Info.plist`
- `Config`: app and widget xcconfigs
- `FocusOne.storekit`: local StoreKit test configuration
- `project.yml`: project source of truth for regeneration

## Run

1. Open `FocusOne.xcodeproj` in Xcode.
2. Select the shared `FocusOne` scheme.
3. Build and run on iOS 17+.

CLI build used during this audit:

```sh
xcodebuild -project FocusOne.xcodeproj -scheme FocusOne -destination 'generic/platform=iOS Simulator' build
```

The shared schemes reference `FocusOne.storekit`, so local StoreKit testing works without extra setup.

## Exact Identifiers

- App bundle ID: `fr.beabot.FocusOne`
- Widget bundle ID: `fr.beabot.FocusOne.widget`
- App Group: `group.fr.beabot.FocusOne`
- iCloud container: `iCloud.fr.beabot.FocusOne`

These exact identifiers are used in code, entitlements, project settings, widget configuration, and docs.

## Personal Team Limits

This repo is being developed with a Personal Team, not a paid Apple Developer account.

Blocked or not fully supported here:

- Push Notifications
- iCloud / CloudKit provisioning
- App Groups provisioning

Supported locally:

- Local notifications
- Local StoreKit testing
- Widget compilation and Debug fallback behavior

Implementation behavior:

- Debug entitlements are intentionally empty so local development does not claim unsupported capabilities.
- Release entitlements keep the real identifiers for future paid-team use.
- `PersistenceController` disables CloudKit in Debug and falls back safely when it cannot load a persistent store.
- `AppGroupStorage` falls back to `UserDefaults.standard` when the App Group container is unavailable, which keeps Debug runs working but does not represent real shared storage.

## Current Status

Working in the current tree:

- Onboarding, Home, Stats, and Settings flows
- Premium gating for full history, advanced stats, archives, upcoming routines, customization, advanced widgets, premium icons, and commitment duration
- StoreKit-backed paywall with yearly and lifetime options
- 10-day free trial messaging
- Widget snapshot sharing with premium lock handling for medium and large widgets
- FR/EN localization

Still needs validation:

- StoreKit sandbox purchase and restore flow
- Local StoreKit runtime currently returns zero products in Xcode despite matching IDs and an attached `.storekit` config; the app now logs the requested IDs, bundle context, and zero-product fallback path for diagnosis
- Lifecycle paywall prompts after real entitlement changes
- Widget refresh after entitlement changes
- Release signing on a paid Apple Developer account
- Real iCloud and App Group behavior on a paid Apple Developer account

Known split:

- Paid entitlement is StoreKit-backed.
- The 10-day free trial still starts from a local app date on first active habit creation.
- That split is documented and still needs a product decision plus sandbox verification.

## Premium

Products currently wired:

- `com.benoit.focusone.premium.yearly`
- `com.benoit.focusone.lifetime`

Current offer:

- 10-day free trial
- EUR14.99/year
- EUR39.99 lifetime

Paywall entry points:

- Stats full history and advanced stats
- Settings archives
- Settings upcoming routines
- Locked premium themes
- Lifecycle prompts from `AppRouter`

The paywall stays contextual and should not block the core free experience.

Premium also now covers:

- extended theme palette
- premium icons
- optional 7/10/15/30-day commitment duration

Free keeps the one-habit loop, reminders, basic stats, and the base palette.

## Next Priorities

1. Validate the paywall in StoreKit sandbox end to end.
2. Decide whether the 10-day trial should remain app-local or move fully to StoreKit intro-offer state.
3. Verify release capabilities on a properly entitled team before treating iCloud, App Groups, or push as supported.
4. Clean up any obsolete premium localization keys once the paywall copy settles.
