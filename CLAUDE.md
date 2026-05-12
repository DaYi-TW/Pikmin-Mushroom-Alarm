# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Status

SwiftUI source for an iOS app authored on Windows, built on Mac. There is **no `.xcodeproj` in this repo** — the user creates the Xcode project on the Mac and drags these files in. See `SETUP_MAC.md` for the exact steps.

Layout:

- `proposal.md` — product spec (source of truth for product decisions)
- `pikmin_alarm_mockup.jsx` — original React mockup; the SwiftUI views below intentionally mirror its structure
- `PikminMushroomAlarm/` — main app target source
- `ShareExtension/` — Share Extension target source
- `PikminWidgets/` — Widget Extension target (Home Screen Widget + Live Activity + Dynamic Island)
- `SETUP_MAC.md` — Mac/Xcode setup instructions

## Build & run

There is no build command runnable on Windows — Swift can't compile here. Iterate on Windows, build on Mac in Xcode. Minimum iOS 17 (uses SwiftData + Observation). Don't attempt to run `xcodebuild` or `swift build` from this side; just write the code and ask the user to build on Mac.

## Cross-target file membership

Target membership (top-of-file comments label this on every shared file — keep them accurate when adding files):

- **Main app + Share Extension + Widget**: `Mushroom.swift`, `NotificationOffset.swift`, `AppGroup.swift`, `MushroomActivityAttributes.swift`
- **Main app + Share Extension only**: `OCRService.swift`, `NotificationScheduler.swift`, `MushroomStore.swift`
- **Main app only**: `LiveActivityManager.swift`, everything in `Views/`, `TimeFormatting.swift`
- **Widget only**: everything in `PikminWidgets/`

ActivityKit's API limits where Live Activities can be started: **only the foreground main app**, never the Share Extension. The Share Extension writes mushrooms to the shared store and calls `WidgetCenter.shared.reloadAllTimelines()`; the main app's `reconcileLiveActivities()` in `PikminMushroomAlarmApp.swift` catches up missing activities on next launch / foregrounding. Don't try to `import ActivityKit` from the Share Extension target — it will compile but `Activity.request` silently does nothing.

The three targets share data through a SwiftData store written into an App Group container (see `AppGroup.swift`). The App Group identifier (`group.com.yourname.pikminmushroomalarm`) appears in **four** places — `AppGroup.swift`, `PikminMushroomAlarm.entitlements`, `ShareExtension.entitlements`, `PikminWidgets.entitlements` — and **must match byte-for-byte**, otherwise targets silently write to separate sandboxes.

## Product invariants

These are decisions from `proposal.md`; do not change them without user direction:

- **SwiftUI only** — no React Native / Flutter.
- **No backend.** No auth, no cloud sync, no server. Everything local.
- **Vision Framework for OCR.** Don't reach for GPT/Gemini Vision unless the user reopens that decision.
- **Notification cadence is fixed**: T+0, T+3:00, T+4:00, T+4:30, T+4:50, T+5:00 (encoded in `NotificationOffset`). The respawn-time invariant is also `finish + 5 minutes` — used by `OCRResult.respawnDate` and `NotificationScheduler`.
- **zh-TW strings** in the UI. The OCR regex `剩下\s*(\d+)\s*小時\s*(\d+)\s*分\s*(\d+)\s*秒` lives in `OCRService.parseRemainingSeconds` and is the contract with Pikmin Bloom's zh-TW localization. If Pikmin Bloom's text format changes, that single function is the place to add a new parser branch — keep it pure so it stays unit-testable from synthetic strings.

## Widget / Live Activity ticking

Both the widget and the Live Activity use `Text(timerInterval: now...target, countsDown: true)` for per-second updates. **Don't replace this with manual state pushes** — ActivityKit rate-limits updates aggressively, and WidgetKit doesn't refresh more than a few times an hour. The interval-based Text view ticks for free on the system's tick. Only push an `Activity.update` when the underlying dates change (e.g. user edits a mushroom).

The widget timeline (`MushroomTimelineProvider`) schedules its next refresh at the next finish/respawn moment, or at most 15 minutes out — newly-added mushrooms appear without forcing the user to wait an hour for the system's next budgeted refresh.

## The JSX mockup is a spec, not legacy

`pikmin_alarm_mockup.jsx` describes the intended UX. The SwiftUI files mirror it 1:1:
- `HomeView` ↔ `HomeScreen`
- `HeroCardView` ↔ `HeroCard`
- `MushroomCardView` ↔ `MushroomCard`
- `AddMushroomSheet` ↔ `AddMushroomSheet`
- `DeleteConfirmSheet` ↔ `DeleteConfirmSheet`
- `TimeFormatting.hms` ↔ `formatTime`
- `OCRService.parseRemainingSeconds` ↔ `parseRemainingTime`

When tweaking visual structure, check the JSX first to stay consistent with the approved design (Apple Health / Fitness-inspired, per proposal §5).

## Developer workflow

Per `proposal.md` §11 the user develops on Windows and builds on Mac. So:
- Prefer self-contained `.swift` files; avoid generated content (asset catalogs, storyboards) the user would have to hand-edit on Mac.
- Don't add Swift Package Manager dependencies casually — each one adds Mac-side setup friction.
- If you add a new file the Share Extension also needs, add a top-of-file comment listing both targets, and update `SETUP_MAC.md` step 4's membership list.
