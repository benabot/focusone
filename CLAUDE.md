# CLAUDE.md

## Project Overview

**FocusOne** is a minimalist iOS habit-tracking app built with **SwiftUI**.
Its core principle is simple: **the user tracks one micro-habit at a time with one tap per day**.
The product philosophy is **"less is more"**: low friction, fast interaction, no backend, no unnecessary complexity.

The app is designed for:
- one active habit in the free tier,
- a very fast daily check-in flow,
- visible streak motivation,
- local reminders,
- iCloud sync with CloudKit,
- iOS widgets (Home Screen + Lock Screen),
- full French/English localization.

Target platform:
- **iOS 17+**
- **Xcode 15+**
- **SwiftUI-first architecture**

---

## Product Intent

The app should feel:
- immediate,
- calm,
- lightweight,
- native to iOS,
- visually polished but not overloaded.

A user should be able to:
1. open the app,
2. tap "Done",
3. see the updated streak,
4. leave the app,

in roughly **one second**.

This constraint matters. Any code change that adds friction, extra steps, modal overload, or configuration complexity should be treated skeptically.

---

## Core Functional Scope

### MVP
- One active habit in Free.
- One-tap daily completion.
- Streak engine.
- Basic stats.
- Local notifications.
- Core Data persistence.
- CloudKit sync.
- WidgetKit support.
- FR/EN localization.

### Premium direction
The premium model has evolved from the original draft.
Current intended premium offer:
- **10-day free trial**
- **€14.99/year**
- **€39.99 lifetime**

Premium features (in order of conversion value):
- **streak protection** — recover 1 missed day per month without breaking the streak,
- full history (beyond 30 days),
- streak widget (Home Screen),
- cycles / archives,
- advanced stats,
- extra customization.

Premium access should be granted only when:
- yearly subscription is active,
- or lifetime purchase is owned,
- or the free trial is still valid through StoreKit entitlements.

Do **not** implement premium access using a local date counter alone.
Use StoreKit entitlement state as the source of truth.

---

## Product Rules

### Habit model
A habit contains at least:
- `id`
- `name`
- `icon`
- `color`
- `startDate`
- `dayStartHour` (default: `4`)
- `reminderTimes[]`
- `isActive`

### Completion model
A completion contains at least:
- `habitId`
- `dayKey` normalized using `dayStartHour`
- `timestamp`

### Cycle model (premium)
A cycle contains at least:
- `habitId`
- `cycleStart`
- `cycleEnd`
- `status` (`anchored`, `abandoned`, etc.)

### Day boundary
A day is **not** midnight-based by default.
It starts at **04:00**.
This avoids streak breakage for users who check in after midnight.
All streak and completion logic must respect this rule.

### Streak rules
- A day counts as complete if there is at least one check-in in that day window.
- Same-day toggle should be allowed to undo mistakes.
- If today is complete and yesterday was complete, streak increments.
- If today is complete and yesterday was not, streak becomes `1`.
- If a full day passes incomplete, the streak is broken.

---

## UX Principles

When modifying the app, preserve these constraints:

- **Minimal cognitive load**.
- **No heavy data-entry flows**.
- **No unnecessary modal stacks**.
- **No decorative complexity that slows the main action**.
- **Animations should be subtle and purposeful**.
- **The Home screen is the priority surface**.

The app should resemble a polished native iOS utility, not a dashboard-heavy productivity suite.

---

## Screens

### Onboarding
Purpose: configure the habit in under 30 seconds.

Expected elements:
- habit name,
- icon,
- color theme,
- daily frequency,
- 0/1/2 reminder times,
- day start setting,
- start CTA.

### Home
Purpose: immediate action + visible feedback.

Expected elements:
- habit identity (name/icon/color),
- Done toggle,
- current streak,
- next reminder,
- today status,
- quick access to Stats / Settings.

### Stats
Purpose: clear visualization without complexity.

Expected elements:
- monthly calendar,
- completion rate over 7 / 30 days,
- best streak.

Premium advanced stats can extend this with:
- longer history,
- trends,
- detailed consistency metrics,
- richer visual breakdowns.

### Settings
Purpose: minimal control surface.

Expected elements:
- notifications,
- reminder times,
- day start hour,
- theme,
- iCloud sync status,
- help / feedback,
- premium access.

### Paywall
Should be shown when the user attempts to access premium-only features.
It should not make the free experience unusable.

Layout order (top to bottom):
1. Header (badge PREMIUM + title + subtitle)
2. Product cards — yearly highlighted with trial badge + monthly equivalent, lifetime secondary with glass card style
3. Benefits section header ("Ce que tu débloques :")
4. 4 benefit rows in priority order: streak protection, full history, streak widget, cycles
5. Footer: "Plus tard" + "Restaurer les achats"

Yearly card specifics:
- Shows annual price + computed monthly equivalent (price / 12)
- "10 JOURS GRATUITS" trial badge
- CTA: "Commencer l'essai gratuit" (not "Acheter")
- Accent-colored background

Lifetime card specifics:
- Price + "Paiement unique, à vie" subtitle
- Glass card style (secondary emphasis)

The paywall uses two dedicated card views (`YearlyProductCard`, `LifetimeProductCard`) instead of a single generic card, for clarity.

Paywall copywriting rules:
- Title uses loss aversion framing ("Ne perds plus ton streak"), not feature listing
- Subtitle is one sentence about the concrete outcome, not a feature recap
- Benefits speak to the user's goal (keeping their streak, seeing their history), not technical capabilities
- No jargon, no "advanced" — write for someone trying to hold a habit
- Dead keys removed: `paywall.note`, `paywall.cta`, `paywall.cta.upgrade`, `paywall.cta.waitlist`, `paywall.alert.*`

### Premium Lifecycle Sheets
Three auto-triggered sheets in `AppRouter` (`premiumPromptContent(for:)`), each with a distinct emotional angle:

| Sheet | Trigger | Angle | CTA pattern |
|-------|---------|-------|-------------|
| **Mid-trial** | Day 6 of 10 | Discovery — celebrate streak, show what they'd lose | "Continuer à 14,99 €/an" |
| **End of trial** | Last day | Soft urgency — concrete loss tomorrow | "Garder l'accès — 14,99 €/an" |
| **Expired** | After trial | Loss + reopening — data is safe but locked | "Débloquer — 14,99 €/an" |

Copywriting rules for these sheets:
- One idea per field, no feature lists in body
- Price visible in CTA or secondary, never hidden behind paywall
- Body focuses on one concrete loss (history beyond 30 days), not a feature catalog
- `trial.body` uses `%@` for the trial end date
- `trial.secondary.format` uses two `%@`: first is `daysRemainingText()` (e.g. "4 jours restants"), second is `trialEndDateString()` — rendered as "4 jours restants · Jusqu'au 22 mars"
- Both formatted via `localizedStringWithFormat` in AppRouter
- Prices are hardcoded in strings (not dynamic from StoreKit) — update strings if prices change in App Store Connect

---

## Technical Architecture

Based on the current documentation, the project structure is:

- `FocusOne/`
  - App
  - Features
  - Domain
  - Persistence
  - SharedUI
- `Widgets/`
- `FocusOneWidget/Resources`

Current technical stack:
- **SwiftUI** for UI
- **Core Data + CloudKit** for persistence and sync
- **WidgetKit** for Home / Lock Screen widgets
- **Local notifications**
- **FR/EN localization**, including pluralization

The architecture should stay modular and pragmatic.
Prefer small focused types over over-engineered abstraction.

---

## Known Implementation Notes

From the existing codebase:
- `PremiumGate` is in `FocusOne/Domain/Services/PremiumGate.swift`.
  - `hasPaidEntitlement` reads from `storeKitEntitlementState: PremiumEntitlementState?` (injected).
  - Fallback to `UserDefaults.bool(forKey: AppStorageKeys.isPremium)` for debug overrides only.
  - Trial logic (10 days) computed from `UserDefaults` date; StoreKit trial configured in `FocusOne.storekit`.
- `StoreKitService` is in `FocusOne/Domain/Services/StoreKitService.swift`.
  - `@Published var entitlementState: PremiumEntitlementState` — source of truth for premium access.
  - Injected as `@StateObject` in `FocusOneApp`, passed via `environmentObject` to all views.
  - Product IDs: `com.benoit.focusone.premium.yearly` (AutoRenewable) and `com.benoit.focusone.lifetime` (NonConsumable).
- `FocusOne.storekit` at project root — sandbox config for simulator testing.
  - Activate via: `Edit Scheme > Run > Options > StoreKit Configuration`.
  - Manage sandbox transactions via: `Xcode > Debug > StoreKit > Manage Transactions`.
- `AppConfig.swift` holds bundle ID, iCloud container ID, App Group ID.
- Widgets use an **App Group snapshot strategy**: app writes JSON to shared container, widget reads from it.
- Streak labels are localized and pluralized.
- UI polish completed on: `DoneToggleButton`, `HomeView`, `StatsView`, `StatsViewModel`, `AppRouter`.
- `SettingsView` has a `#if DEBUG` section (bottom of screen) to simulate all premium states:
  - Buttons: trial actif jour 1 / mi-trial jour 6 / fin de trial jour 9 / trial expiré / reset.
  - Writes to `UserDefaults` then calls `viewModel.refreshPremiumState()`.
  - **Never visible in release builds.**
- `onChange` modifiers use the iOS 17+ two-parameter signature `{ _, newValue in }` throughout.

When changing code, preserve the current product direction rather than introducing a different app concept.

---

## Current Signing / Capability Constraints

The current local Xcode project shows provisioning issues tied to Apple Personal Team limitations.
Errors indicate that the current personal development team does not support:
- **iCloud capability**,
- **App Groups capability**,
- related entitlements for CloudKit and shared widget containers.

This means:
- local simulator/device development may require temporarily disabling iCloud/App Groups,
- or using a paid Apple Developer account with proper provisioning,
- or isolating those capabilities behind fallbacks for local development.

Do not assume provisioning is correctly set up.
If you touch capabilities-dependent code, be careful not to make the app impossible to run in a constrained local environment.

---

## How Claude Should Help

When asked to modify this project, follow these rules:

1. **Preserve the minimalist product identity.**
2. **Prefer direct, production-ready SwiftUI code.**
3. **Do not replace simple architecture with unnecessary complexity.**
4. **Respect the one-habit-first philosophy.**
5. **Keep all premium gating explicit and centralized.**
6. **Keep strings localizable.**
7. **Avoid pseudo-code unless explicitly requested.**
8. **When changing UI, maintain a polished native iOS style.**
9. **When changing streak/stat logic, respect the custom day boundary.**
10. **When touching sync/widgets, account for App Groups / iCloud capability constraints.**

---

## Recommended Claude Prompt

Use the following prompt to brief Claude on the project:

```text
You are working on FocusOne, a SwiftUI iOS app for tracking exactly one micro-habit at a time with one tap per day.

Project intent:
- minimalist, calm, native iOS product
- “less is more” philosophy
- main user loop must stay extremely fast: open app → tap Done → see streak → leave
- avoid feature bloat and dashboard-heavy UX

Tech stack:
- SwiftUI
- iOS 17+
- Xcode 15+
- Core Data + CloudKit
- WidgetKit
- local notifications
- FR/EN localization

Current structure:
- FocusOne/
  - App
  - Features
  - Domain
  - Persistence
  - SharedUI
- Widgets/
- FocusOneWidget/Resources

Core product rules:
- free tier = one active habit
- default day boundary is 04:00, not midnight
- one completion per day window is enough
- same-day toggle should allow undo
- streak logic must respect the custom day boundary

Key screens:
- Onboarding: configure habit quickly
- Home: immediate daily action
- Stats: simple visual feedback
- Settings: minimal control
- Paywall: only when needed, without breaking free usability

Premium direction:
- 10-day free trial
- €14.99/year
- €39.99 lifetime
- premium features (by conversion value): streak protection (1 missed day/month recovery), full history, streak widget, cycles/archives, advanced stats, extra customization

Premium access logic:
- use centralized entitlement logic such as hasPremiumAccess
- true if yearly subscription active OR lifetime owned OR trial still active
- use StoreKit entitlements as source of truth
- do not rely only on local dates for trial expiration

Important implementation notes:
- there is a PremiumGate layer and a StoreKitService for entitlement management
- PaywallView uses dedicated YearlyProductCard / LifetimeProductCard with price cards above benefits
- widgets rely on App Group shared data
- AppConfig.swift may contain capability identifiers
- localization matters in both app and widgets
- keep UI elegant, restrained, and native

Important environment constraint:
- local Xcode project currently has provisioning issues with iCloud and App Groups because the active team is a Personal Team
- do not assume CloudKit/App Groups are available in the current local environment
- if needed, preserve fallbacks or avoid making the project impossible to build locally

How to respond:
- give production-ready SwiftUI code when asked for implementation
- keep changes pragmatic and local to the existing architecture
- avoid rewriting the app around a new architecture unless strictly necessary
- preserve the minimalist product direction
- keep text localizable
- explain tradeoffs briefly and clearly
```

---

## Working Assumptions

If the codebase does not fully match the documentation, prioritize:
1. the product intent,
2. the current documented architecture,
3. the existing SwiftUI implementation style,
4. pragmatic incremental change.

Do not redesign the app into a generic habit tracker with many simultaneous habits unless explicitly requested.
