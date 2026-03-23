# FocusOne TODO

This backlog reflects the merged `main` + `dev` state as of 2026-03-23.

## Done

- [x] Audited both branches before changing docs or premium code.
- [x] Renamed `todo.md` to `TODO.md`.
- [x] Aligned the app, widget, app group, and iCloud identifiers to `fr.beabot.FocusOne`, `fr.beabot.FocusOne.widget`, `group.fr.beabot.FocusOne`, and `iCloud.fr.beabot.FocusOne`.
- [x] Updated `README.md` to reflect the real repo state and Personal Team constraints.
- [x] Added `AGENTS.md` for future coding agents.
- [x] Preserved local StoreKit testing with `FocusOne.storekit`.
- [x] Kept the current `dev` UI structure while merging the more advanced paywall and StoreKit path from `main`.
- [x] Kept Debug entitlements empty so Personal Team development can run without claiming blocked capabilities.
- [x] Verified the merged app builds with `xcodebuild -project FocusOne.xcodeproj -scheme FocusOne -destination 'generic/platform=iOS Simulator' build`.
- [x] Implemented real premium-gated advanced stats in Stats.
- [x] Implemented a real free/premium theme palette split with safe fallback to a free theme after premium loss.
- [x] Added a shared theme palette picker so Settings and onboarding use the same theme source of truth and lock behavior.
- [x] Implemented premium icons with locked access and paywall upsell in routine setup.
- [x] Implemented optional premium commitment duration support for 7 / 10 / 15 / 30-day routine commitments.
- [x] Aligned premium copy to the real feature set: advanced stats, full history, advanced widgets, archives, next routine, extra customization, premium icons, and commitment duration.
- [x] Fixed the duplicate-ID SwiftUI warning in the stats month grid.

## In Progress

- [ ] Investigate why local StoreKit runtime still returns zero products in Xcode even though the identifiers and scheme attachment are correct.
- [ ] Run StoreKit sandbox validation for yearly trial, lifetime purchase, cancellation, pending, and restore.
- [ ] Verify lifecycle paywall prompts after real purchase state changes, not only debug state changes.
- [ ] Confirm widget refresh behavior after entitlement changes on a simulator or device.

## Next

- [ ] Make paywall validation the immediate product step.
- [ ] Decide whether the current 10-day trial should remain app-local or move fully to StoreKit intro-offer state.
- [ ] Validate the yearly-first presentation after real sandbox testing.
- [ ] Confirm that exact bundle IDs and entitlement files survive future project regeneration.
- [ ] Re-check the paywall once StoreKit returns products so the real plan cards render instead of the unavailable-products fallback.

## Later

- [ ] Expand premium value beyond gating copy where the product already promises it:
  - more explicit archive and cycle UX
  - broader premium customization
- [ ] Review and remove obsolete premium and paywall localization keys once the current copy is stable.
- [ ] Add focused automated coverage where it is practical for streak logic, premium gates, and widget snapshot encoding.

## Tech Debt / Validation Needed

- Current premium access is split:
  - paid entitlement comes from StoreKit 2
  - the 10-day free trial still starts locally on first active habit creation
- The local StoreKit runtime issue is still unresolved: the app loads products with matching identifiers, but Xcode runtime currently returns zero products and falls back to the unavailable-products message.
- Archived routines and best streaks remain routine-local by design; the app does not aggregate streaks across cycles.
- Lifecycle prompt prices are hardcoded in localized strings. If pricing changes, those strings must be updated manually.
- Debug entitlements intentionally disable CloudKit, App Groups, and push. Debug behavior is useful for development, but it is not equivalent to a fully entitled Release setup.
- `AppGroupStorage` falls back to `UserDefaults.standard` when the App Group is unavailable. This keeps Debug builds usable, but it can hide real extension-sharing issues.
- `project.yml` and the checked-in Xcode project must stay in sync. Manual scheme or target edits can be lost if the project is regenerated.
- `CLAUDE.md` exists on `main`, not on `dev`. Use `AGENTS.md`, `README.md`, and the checked-out code first; inspect `main` when premium/docs history looks inconsistent.
