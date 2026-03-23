# AGENTS.md

## 1. Project Summary

FocusOne is a minimal iOS habit app for tracking one micro-habit at a time. The core value is speed: create a habit quickly, check it off in one tap, see immediate feedback, leave.

Do not turn this into a broad productivity system. Avoid multi-habit dashboards, backend work, or monetization that blocks the free core loop.

## 2. Product Philosophy

- One habit at a time.
- Minimal friction.
- Native iOS feel over novelty.
- Low cognitive load.
- Simple stats over analytics overload.
- Premium should feel contextual, not aggressive.

## 3. Current Premium Model

- 10-day free trial
- EUR14.99/year
- EUR39.99 lifetime

Premium framing currently used in the app:

- advanced stats
- advanced widgets
- full history
- cycles / archives
- extra customization
- premium icons
- commitment duration

Important nuance: paid entitlement is StoreKit-backed, but the current 10-day trial still starts from a local app date. Treat that as an implementation detail under validation, not settled product truth.

Current implementation truth:

- Free users keep the core one-routine loop, reminders, and basic stats.
- Trial and premium users get advanced stats, full history, advanced widgets, archives, next routine, the extended theme palette, premium icons, and commitment duration.
- When premium access expires, premium-only stats and premium-only theme colors must lock again while the free core remains intact.
- Settings and onboarding now share a single theme picker component. Treat that component and `Theme` as the source of truth for palette lock behavior.
- `HabitIcon` is the source of truth for free vs premium symbols.
- Commitment duration is lightweight routine metadata, not a planner system.

## 4. Core User Flow

- Onboarding
  - User creates one active habit with name, icon, theme, reminders, day-start hour, and optional commitment duration.
  - Premium icons are visible in the icon picker and open the paywall when locked.
  - Creating the first active habit currently starts the local premium trial clock.
- Daily usage
  - User lands on Home.
  - User toggles today’s completion.
  - Streak and widget snapshot refresh immediately.
- Stats
  - Free users keep current streak, best streak, 7-day completion, and 30-day completion.
  - Advanced stats, full history, and the monthly / rolling metrics are gated.
- Settings
  - User manages reminders, day boundary, theme, iCloud info, and premium entry points.
  - Archives, upcoming routines, and extra themes are gated.
- Premium upgrade flow
  - Paywall opens only from gated actions or lifecycle prompts.
  - Locked premium icons and commitment-duration chips should route to the paywall instead of pretending to select.
  - Yearly is the primary plan.
  - Lifetime is secondary but visible.
  - Paywall copy should stay calm, credible, and product-focused.

## 5. Architecture Overview

- App entry points
  - `FocusOne/App/FocusOneApp.swift`
  - `FocusOne/App/AppRouter.swift`
  - `FocusOne/App/AppConfig.swift`
- Major views
  - `FocusOne/Features/Onboarding`
  - `FocusOne/Features/Home`
  - `FocusOne/Features/Stats`
  - `FocusOne/Features/Settings`
  - `FocusOne/Features/Paywall`
- Models and domain logic
  - `FocusOne/Domain/Models`
  - `FocusOne/Domain/Services/StreakEngine.swift`
  - `FocusOne/Domain/Services/PremiumGate.swift`
  - `FocusOne/Domain/Services/NotificationsService.swift`
  - `FocusOne/Domain/Services/Localization.swift`
- Persistence
  - `FocusOne/Persistence/PersistenceController.swift`
  - `FocusOne/Persistence/Repositories/HabitRepository.swift`
  - `FocusOne/Persistence/Model.xcdatamodeld`
- StoreKit-related files
  - `FocusOne/Domain/Services/PremiumGate.swift`
    - contains `StoreKitService`, premium gate logic, prompt timing, trial helpers
  - `FocusOne/Features/Paywall/PaywallView.swift`
  - `FocusOne.storekit`
  - shared schemes in `FocusOne.xcodeproj/xcshareddata/xcschemes/`
- Widget-related files
  - `Widgets/WidgetDataStore.swift`
  - `Widgets/FocusOneWidget.swift`
  - `FocusOneWidget/Resources/Info.plist`
  - `FocusOneWidget/*.entitlements`
- iCloud-related files
  - `FocusOne/Persistence/PersistenceController.swift`
  - `FocusOne/Resources/FocusOne.entitlements`
  - `Config/*.xcconfig`

## 6. Important Files and Folders

- `README.md`
- `TODO.md`
- `AGENTS.md`
- `project.yml`
- `Config/Base.xcconfig`
- `Config/Debug.xcconfig`
- `Config/Release.xcconfig`
- `Config/Widget.Debug.xcconfig`
- `Config/Widget.Release.xcconfig`
- `FocusOne/App/AppConfig.swift`
- `FocusOne/App/AppRouter.swift`
- `FocusOne/App/FocusOneApp.swift`
- `FocusOne/Domain/Services/PremiumGate.swift`
- `FocusOne/Features/Paywall/PaywallView.swift`
- `FocusOne/Features/Stats/StatsView.swift`
- `FocusOne/Features/Settings/SettingsView.swift`
- `FocusOne/Features/Onboarding/OnboardingViewModel.swift`
- `FocusOne/Persistence/PersistenceController.swift`
- `Widgets/WidgetDataStore.swift`
- `Widgets/FocusOneWidget.swift`
- `FocusOne.storekit`

## 7. State of Implementation

Exists and is actively used:

- Onboarding
- Home check-in flow
- Basic stats
- Settings
- Widget snapshots and widget extension
- FR/EN localization
- Premium gating surfaces
- StoreKit-backed paywall UI
- Purchase and restore plumbing

Partial:

- Archives and upcoming routines exist in Settings, but premium positioning is still intentionally lightweight.
- Widget premium support is implemented as free small/accessory plus premium medium/large.
- Premium icons and commitment duration are implemented as lightweight extensions to routine setup and the commitment-completion banner on Home.

Missing or unstable:

- Real StoreKit sandbox verification is still needed after the branch merge.
- Local StoreKit runtime is still returning zero products in Xcode despite matching IDs and the attached `.storekit` file.
- Trial state still mixes local clock logic with StoreKit-paid entitlement logic.
- Release capability validation still needs a fully entitled signing setup.

## 8. Documentation Trust Rules

- Code in the checked-out branch wins over stale docs.
- `main` and `dev` have diverged before. If premium/docs history looks inconsistent, inspect both branches before editing.
- `CLAUDE.md` exists on `main` only. Treat it as a useful reference, not as the live source of truth in `dev`.
- `README.md`, `TODO.md`, and `AGENTS.md` are meant to reflect the merged audited state, but verify the code before changing behavior.

## 9. Rules Before Editing

- Inspect before changing.
- Prefer targeted fixes over broad rewrites.
- Preserve the one-habit product shape.
- Keep onboarding fast.
- Keep Home frictionless.
- Do not add backend requirements.
- Do not make the paywall more aggressive than the current contextual triggers.
- Reuse the shared theme palette picker and shared theme helpers instead of reintroducing per-screen palette definitions.

## 10. Coding Conventions

- SwiftUI-first architecture.
- Root feature views commonly use `@StateObject` view models initialized with `NSManagedObjectContext`.
- Shared services and cross-feature state are injected via environment where already established, for example `StoreKitService`.
- Keep business logic in view models/services, not in long view bodies.
- Use the existing theme system: `Theme`, `AppSpacing`, `AppTypography`, `AppSurface`, shared gradients/surfaces.
- Use `L10n.text(...)` and the other `L10n` helpers for user-facing strings.
- Update widget snapshots whenever habit state or premium/widget access changes.
- Respect the 04:00 default day boundary unless a feature explicitly changes it.

## 11. UX Constraints

- Minimal UI.
- Fast action loop.
- No dashboard bloat.
- No intrusive monetization.
- Paywall only when justified by a gated action or lifecycle prompt.
- Keep yearly primary and lifetime secondary on the paywall.
- Do not block onboarding or Home behind premium.

## 12. Localization Rules

- Localization exists in:
  - `FocusOne/Localization/en.lproj/Localizable.strings`
  - `FocusOne/Localization/fr.lproj/Localizable.strings`
  - both matching `.stringsdict` files
- Add or update both English and French together.
- Prefer `L10n` helpers over hardcoded production strings.
- If you change pricing copy in lifecycle prompts, update both languages manually. Those strings are currently hardcoded, not generated from StoreKit.

## 13. StoreKit / Paywall Rules

Product IDs currently wired:

- `com.benoit.focusone.premium.yearly`
- `com.benoit.focusone.lifetime`

Current structure:

- yearly subscription with 10-day trial messaging
- lifetime non-consumable
- premium icons and commitment duration are part of the Premium feature surface, not separate StoreKit products

Current implementation facts:

- `StoreKitService` loads products, purchases, listens for transaction updates, and restores via `AppStore.sync()`.
- Paid entitlement state is stored as `.active` or `.none`.
- The paywall uses dedicated yearly and lifetime cards.
- Yearly is highlighted, especially from lifecycle prompts.
- Restore button is available in the paywall footer.
- The current local StoreKit runtime still needs validation: product IDs match the `.storekit` file, but the simulator runtime has been returning zero products and falling back to the unavailable-products state.

Current paywall triggers:

- `StatsView`: full history tap when not entitled
- `SettingsView`: archives, upcoming routines, locked premium themes
- `AppRouter`: lifecycle prompts for mid-trial, last-day, and expired local trial states
- routine setup: locked premium icons and commitment duration chips should open the paywall instead of pretending to select

Current validation requirement:

- Confirm sandbox purchases, restores, cancellation, pending transactions, and prompt behavior after the branch merge.
- Confirm whether the 10-day trial should remain local or move to StoreKit intro-offer state only.

## 14. Widgets / iCloud / Entitlement Caveats

- Release-capable identifiers use:
  - app: `fr.beabot.FocusOne`
  - widget: `fr.beabot.FocusOne.widget`
  - app group: `group.fr.beabot.FocusOne`
  - iCloud container: `iCloud.fr.beabot.FocusOne`
- Debug entitlements are intentionally empty to keep Personal Team development workable.
- Personal Team blocks Push Notifications, CloudKit, and App Groups in practice.
- `PersistenceController` disables CloudKit in Debug and can fall back to in-memory persistence after store errors.
- `AppGroupStorage` falls back to standard defaults if the App Group is unavailable.
- Small and lock-screen widgets remain free.
- Medium and large widgets are premium-only based on `advancedWidgetsEnabled` in the shared widget snapshot.
- Premium theme colors must fall back to a free preset if entitlement is lost.

## 15. Testing Checklist

- Onboarding
  - Create a first habit.
  - Verify reminders, theme, icon, commitment duration, and day-start persistence.
  - Verify the local premium trial starts only after creating an active habit.
  - Verify locked premium themes open the paywall instead of looking selectable when Premium is unavailable.
  - Verify locked premium icons and commitment-duration chips open the paywall instead of selecting.
- Home
  - Toggle done/undone for today.
  - Verify streak refresh.
  - Verify widget snapshot updates.
- Stats
  - Verify current/best/7-day/30-day stats.
  - Verify the advanced stats insight banner reads naturally in both languages.
  - Verify free users hit the paywall from full history.
  - Verify entitled users can open full history.
- Settings
  - Verify reminders, day boundary, and theme persistence.
  - Verify premium-only themes show locks and open the paywall.
  - Verify archives and upcoming routines gate correctly.
  - Verify the selected theme falls back to a free preset after premium loss.
- Paywall
  - Verify products load from `FocusOne.storekit`.
  - Verify yearly is visually primary.
  - Verify 10-day trial messaging is obvious.
  - Verify the body copy mentions premium icons and commitment duration.
  - Verify lifetime remains visible but secondary.
- If StoreKit still returns zero products, inspect the runtime logs before changing product IDs or the `.storekit` file.
- Purchase flow
  - Buy yearly in StoreKit sandbox.
  - Buy lifetime in StoreKit sandbox.
  - Verify dismissal and entitlement refresh.
- Restore purchases
  - Use restore from the paywall.
  - Verify Premium reactivates if eligible.
- Trial / expiration
  - Use the DEBUG premium-state helpers in Settings.
  - Verify mid-trial, ending-soon, and expired lifecycle prompts.
- Widgets
  - Verify small and accessory widgets stay available for free.
  - Verify medium and large widgets show locked state without premium and unlock after entitlement.
- iCloud / App Groups
  - Only treat this as valid once testing with proper entitlements outside the stripped Debug setup.

## 16. Definition of Done

A feature is done when:

- it builds cleanly,
- it preserves the app’s minimal product shape,
- it does not add friction to onboarding or Home,
- premium gating is coherent across app + widgets if relevant,
- EN and FR strings are updated,
- manual validation steps are documented or completed,
- docs are updated when behavior changes materially.

## 17. Current Priorities

1. Validate the paywall end to end in StoreKit sandbox.
2. Resolve the local-trial versus StoreKit-entitlement split.
3. Keep the docs and code aligned if future premium changes land.
4. Keep commitment duration and premium icons lightweight if they change again later.

## 18. Known Risks / Pitfalls

- `main` and `dev` have drifted in the past. Premium work may exist on one branch only.
- `project.yml` and the committed Xcode project can drift; scheme-level StoreKit config is easy to lose on regeneration.
- Bundle IDs and entitlements in stale docs may still refer to older values; the live repo now uses `fr.beabot.FocusOne` identifiers.
- Debug fallback behavior can hide real App Group or CloudKit issues.
- The paywall copy and prompt cadence currently assume fixed prices in strings.
- `FocusOne.xcodeproj/project.pbxproj` had pre-existing user changes during this audit. Do not casually overwrite unrelated project-file edits.
