# FocusOne
FocusOne is a SwiftUI iOS app to track one micro-habit with one tap per day.

## Features
- One active habit (Free), streak engine with custom day boundary (default 04:00).
- Core Data + CloudKit sync, local notifications, and WidgetKit (Home + Lock Screen).
- Full FR/EN localization (including widget) with pluralized streak labels.

## Run
1. Open `FocusOne.xcodeproj` in Xcode 15+.
2. Check signing/capabilities in `todo.md`.
3. Build and run on iOS 17+.

## Structure
`FocusOne/` (App, Features, Domain, Persistence, SharedUI) + `Widgets/` + `FocusOneWidget/Resources`.
