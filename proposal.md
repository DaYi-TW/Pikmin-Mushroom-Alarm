# Pikmin Mushroom Alarm — Proposal

## 1. Project Overview

Pikmin Mushroom Alarm is a mobile application designed for Pikmin Bloom players.

The core concept is:

```text
Screenshot → OCR Recognition → Auto Timer → Intelligent Notifications
```

The application automatically detects mushroom remaining time from screenshots, creates timers, and reminds users when new mushrooms are about to respawn.

The goal is to eliminate manual tracking and provide a fast, frictionless workflow optimized for frequent Pikmin Bloom gameplay.

---

# 2. Target Users

## Primary Users

* Pikmin Bloom active players
* Mushroom raid-focused players
* Users managing multiple mushroom timers
* Players farming mushroom refresh cycles

## Pain Points

Current workflow:

```text
Open Pikmin
→ Check mushroom remaining time
→ Manually remember it
→ Wait 5 minutes after finish
→ Open game again
```

Problems:

* Easy to forget refresh timing
* Difficult to track multiple mushrooms
* No centralized reminder system
* Repetitive manual checking

---

# 3. Core Product Vision

The app should feel like:

```text
A native iOS utility app
+
A fast gaming companion
+
A lightweight reminder assistant
```

UX priorities:

* Extremely fast interaction
* Minimal taps
* Native iOS feeling
* Beautiful timer visualization
* Low cognitive load

---

# 4. Key Features

# 4.1 Screenshot OCR Recognition

Users can:

* Import screenshots manually
* Share screenshots directly from Photos
* Batch import multiple screenshots

The app extracts:

* Mushroom location
* Mushroom type
* Remaining time
* Finish time
* Respawn time

Example:

```text
功夫壁畫
一般 輝煌蘑菇
剩下 1 小時 0 分 13 秒
```

↓

```json
{
  "location": "功夫壁畫",
  "type": "一般 輝煌蘑菇",
  "remaining_seconds": 3613,
  "finish_time": "09:15",
  "respawn_time": "09:20"
}
```

---

# 4.2 Intelligent Notification System

After mushroom completion:

```text
T + 0:00 → Mushroom finished
T + 3:00 → 2-minute reminder
T + 4:00 → 1-minute reminder
T + 4:30 → 30-second reminder
T + 4:50 → 10-second reminder
T + 5:00 → Mushroom respawn
```

Notification frequency increases near respawn time.

This creates a:

```text
"high urgency escalation"
```

experience.

---

# 4.3 Multi-Mushroom Management

Users may track:

* Multiple locations
* Different mushroom types
* Parallel timers

Features:

* Horizontal carousel cards
* Independent timers
* Independent notification schedules
* Quick switching between mushrooms

---

# 4.4 Share Extension Workflow

Best UX flow:

```text
Pikmin Bloom
→ Screenshot
→ Share
→ Pikmin Alarm
→ Auto OCR
→ Auto Create Timer
```

This avoids:

```text
Open App
→ Press +
→ Select Photo
```

The app becomes:

```text
Capture → Share → Done
```

---

# 4.5 Delete Protection

Deleting timers requires confirmation.

Flow:

```text
Tap delete
→ Bottom sheet confirmation
→ Confirm delete
```

This prevents accidental timer loss.

---

# 5. UX/UI Design Direction

## Design Style

Inspired by:

* Apple Health
* Apple Fitness
* Apple Maps Bottom Sheets
* iOS 18 native design language

Visual keywords:

* Soft gradients
* Rounded cards
* Floating glass effect
* Smooth animations
* Large typography
* Minimal clutter

---

# 6. Proposed Screens

## Home Screen

Displays:

* Active mushroom
* Circular countdown timer
* Finish time
* Respawn time
* Notification schedule
* Mushroom carousel

---

## Add Mushroom Bottom Sheet

Appears from bottom.

Contains:

* Import screenshot
* Batch import
* OCR preview
* Parsed result confirmation

---

## Delete Confirmation Sheet

Bottom confirmation modal:

```text
Delete this timer?
```

Actions:

* Delete
* Cancel

---

# 7. Technical Architecture

# Frontend

## iOS

Recommended:

```text
SwiftUI
```

Reasons:

* Native performance
* Native animations
* Native notifications
* Native share extension
* Best iOS UX

---

## Alternative Cross-Platform

Possible:

* React Native
* Flutter

But native SwiftUI is recommended for:

* Dynamic Island support
* Live Activities
* Notification UX
* Widget support

---

# Backend

No backend required initially.

Everything can run locally:

* OCR
* Timer scheduling
* Local notifications
* Data persistence

---

# OCR

Possible implementations:

## iOS Native

```text
Vision Framework
```

Advantages:

* Offline
* Fast
* Free
* Native integration

---

## Future AI OCR

Optional future upgrades:

* GPT Vision
* Gemini Vision
* Claude Vision

For more robust parsing.

---

# 8. Notification System

Uses:

```text
UNUserNotificationCenter
```

Features:

* Scheduled local notifications
* Time-sensitive alerts
* Repeating escalation reminders

Future possibilities:

* Critical Alerts
* Live Activities
* Apple Watch notifications

---

# 9. Future Features

## Live Activities

Display timer on:

* Lock Screen
* Dynamic Island

---

## Widget Support

Home screen widget:

```text
Next mushroom respawn in:
00:01:32
```

---

## Team Sharing

Future multiplayer features:

* Shared mushroom tracking
* Friend notifications
* Team coordination

---

## AI Auto Classification

Automatically identify:

* Mushroom rarity
* Priority
* Event mushrooms

---

# 10. Recommended Development Stack

## Recommended

```text
Frontend:
- SwiftUI

OCR:
- Apple Vision Framework

Storage:
- SwiftData

Notifications:
- UNUserNotificationCenter

Share:
- Share Extension

Build:
- Xcode Cloud
```

---

# 11. Recommended Development Workflow

## Development Environment

Current situation:

```text
Windows PC
+
MacBook Air (borrowed/shared)
```

Recommended workflow:

```text
Claude Code
→ Generate SwiftUI code
→ Open in Xcode on MacBook
→ Run simulator
→ Test on iPhone
```

---

# 12. App Store Strategy

## Initial MVP

Focus on:

* OCR
* Timer management
* Notifications
* Share extension

Avoid:

* Login systems
* Cloud sync
* Backend complexity

---

# 13. Estimated MVP Scope

## MVP Version

Includes:

* OCR screenshot recognition
* Multiple timers
* Local notifications
* Share extension
* Delete protection
* Beautiful native UI

Estimated complexity:

```text
Medium
```

Very feasible for solo development with AI-assisted coding.

---

# 14. Final Recommendation

The strongest version of this product is:

```text
Native iOS App
+
SwiftUI
+
Share Extension
+
Local Notifications
+
Vision OCR
```

This provides:

* Best UX
* Lowest latency
* Lowest operational cost
* No backend dependency
* Fastest interaction flow

The product concept is highly suitable for:

```text
"utility-first gaming companion app"
```

which matches modern successful mobile app patterns extremely well.
