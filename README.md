# 🧠 Unreel

> **Know exactly how many reels you actually watch.** Unreel quietly counts the short-form videos (Instagram Reels, YouTube Shorts, Facebook Reels, Snapchat Spotlight) you scroll through each day — then helps you stop at a healthy limit. 100% offline, no account, no tracking.

![Platform](https://img.shields.io/badge/platform-Android%208%2B-green)
![Flutter](https://img.shields.io/badge/Flutter-3.9%2B-blue)
![Kotlin](https://img.shields.io/badge/native-Kotlin-purple)
![Privacy](https://img.shields.io/badge/permission-NO%20INTERNET-brightgreen)

> 📦 **Clone it:** `git clone https://github.com/<musharrafhamraz>/reel_protection_app.git` — replace `<musharrafhamraz>` with your GitHub handle.

---

## 🪄 The idea

Short-form feeds are engineered to blur together. *"Did I watch 5 videos or 50?"* Unreel answers that honestly — a reel only counts once you've actually **watched it for ~5 seconds**, so random flicks and unreadable frames don't inflate the number. From there, you set a daily limit and Unreel nudges (and, if you allow it, blocks) the feed when you've had enough.

Think of it as a **screenshot-free, private tally counter** for your brain rot. 🧠

---

## ✨ Features

| | Feature | What it does |
|---|---|---|
| 🔢 | **Live reel counting** | Counts distinct videos you watch — deduplicated by creator + caption + platform, with a 5-second dwell rule. Likes, pauses and scroll-backs never double-count. |
| 📊 | **Dashboard** | Today's total, per-app breakdown, estimated time on the feed, streak of days under your limit, and a GitHub-style contribution grid of your history. |
| 🚧 | **Daily limits & blocking** | Get a warning at 80%, then at 100% the reels screen is exited with a calm full-screen *"Limit reached"* page. Strict mode locks the limit in until the next day. |
| 🏠 | **Home screen widget** | A resizable 2×2/4×2, light/dark-aware widget showing today's count and progress — updates within seconds while you scroll. |
| 💭 | **Count bubble** | An optional draggable overlay that floats over any app and shows your running count — the little brain's face changes with your day's usage. 😵‍💫 |
| 🧘 | **Cognitive reset habits** | Built-in morning / afternoon / evening routine tasks (doomscroll antidotes — meditation, breathing, mindfulness, dopamine fast) with weekday-scheduled reminders. |
| 📆 | **History & charts** | 7-day and 30-day bar charts with per-app filters; all data stored locally in **Room (SQLite)**. |
| 📤 | **CSV export** | One-tap export and sharing of your full history — your data is yours. |
| 🌙 | **Light + dark mode** | Calm, playful design that follows your system theme. |

---

## 🔒 Privacy first — by construction

This is the part we're most proud of:

- **No `INTERNET` permission.** The app literally *cannot* phone home — there's no analytics, no ads, no cloud, no account.
- The Android **AccessibilityService** is used *only* to detect the reels screen and count videos. It never reads messages, passwords, or other content.
- Reel identities are stored as counts against **generic content identifiers** — raw captions/usernames are never persisted. 
- Everything lives in a local Room database. Export it or clear it whenever you like.

---

## 📱 Supported apps

| App | Status |
|---|---|
| Instagram Reels | ✅ Tested on device |
| YouTube Shorts | 🟡 Verified via captured layout tests |
| Facebook Reels (incl. **Lite**) | 🟡 Verified via captured layout tests |
| Snapchat Spotlight | 🟠 Beta — lowest confidence |

> Detection is **rule-driven JSON** (`lib/assets/detection_rules.json` + semantic parsers), not hard-coded logic — so when Instagram rebrands its UI next month, this is the file that gets updated.

---

## 🏗️ How it works

```
┌──────────────────────────── Flutter (Dart) ────────────────────────────┐
│  UI: onboarding · dashboard · history · limits · apps · settings        │
│  State: Riverpod   Routing: go_router   Charts: fl_chart               │
└───────────────▲───────────────────────────────────┬────────────────────┘
                │ EventChannel (live count stream)  │ MethodChannel
┌───────────────┴───────────────────────────────────▼────────────────────┐
│                        Native Android (Kotlin)                         │
│  ScrollAccessibilityService → ReelUiParser → ReelCounter (dedupe/dwell) │
│  Room (counts + seen identities) · LimitEnforcer · BlockActivity       │
│  CountOverlay bubble · Home-screen widget · Notification scheduler     │
└────────────────────────────────────────────────────────────────────────┘
```

**Key design choices**
- 🧩 **Native owns the data.** Only Kotlin writes to the database; Flutter reads through platform channels (`scrollcount/methods`, `scrollcount/live`).
- ⚙️ **The service is independent of the UI.** Counting keeps working after the Flutter engine is killed, and daily reminders survive reboots via alarm receivers.
- 🖼️ **Widget updates are push-based and throttled** — refreshed after each count flush, only while the screen is on.
- ⏱️ **A "logical day"** (with a configurable reset hour) decides when counters roll back to zero — `yyyy-MM-dd`, times before the reset hour count toward the previous day.

---

## 🚀 Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) stable (Dart SDK ≥ 3.9)
- Android SDK + an Android device/emulator (**Android 8.0+ recommended**)
- That's it — no API keys, no Firebase, no secrets 🎉

### Build & run

```bash
# 1. Clone
git clone https://github.com/<your-username>/reel_protection_app.git
cd reel_protection_app

# 2. Install dependencies
flutter pub get

# 3. Run in debug (on a connected device)
flutter run

# 4. Or build a release APK
flutter build apk --release
```

### Enable counting on your phone

Unreel needs one Android permission to see when a reel appears:

1. Open the app → follow the onboarding → tap **Enable**.
2. Find **Unreel → Unreel Reel Counter** and turn it **on**.
3. 📌 **On Android 13+ with a sideloaded APK:** open *App info → ⋮ → Allow restricted settings* first, or the accessibility toggle will be greyed out.
4. Grant the **notification permission** (Android 13+) to receive limit warnings.
5. On aggressive OEM skins (Xiaomi/MIUI, Oppo, Vivo, Samsung), exclude Unreel from **battery optimization** so alarms and counting survive.

When everything's connected, the dashboard banner flips to *"Counting"* and you'll see your first real number in minutes.

---

## 🧪 Testing

```bash
# Dart unit + widget tests
flutter test --no-pub

# Kotlin unit tests (detection parsers are tested against real captured layouts)
cd android && .\gradlew.bat :app:testDebugUnitTest

# Static analysis
flutter analyze --no-pub
```

Sanitized window-layout captures from real apps live in `android/app/src/test/resources/reel-layouts/` and back the detection test suite.

---

## 📁 Project structure

```
lib/                         # Flutter UI & app state
 ├── features/               #   onboarding · dashboard · history · limits · apps · settings
 ├── providers/              #   Riverpod providers (today, history, settings, permissions…)
 ├── data/                   #   models, scroll repository, native bridge, task scheduler
 └── core/                   #   theme (Material 3), router, shared widgets, utils

android/app/src/main/
 ├── kotlin/com/scrollcount/app/
 │    ├── service/           #   AccessibilityService, detection engine, reel counter, limits
 │    ├── data/              #   Room entities/DAOs, settings store
 │    ├── widget/            #   home screen widget (provider, renderer, updater)
 │    ├── ui/                #   BlockActivity (limit-reached screen)
 │    ├── bridge/            #   Method/Event channel handlers
 │    └── util/              #   logical-day date utils
 └── res/                    #   widget layouts, brain art, notification styles
```

---

## ⚠️ Known limitations (honesty section)

- **Counts are estimates.** Accessibility has no universal "reel ID"; a reel is identified by creator + caption + platform. Two reels with *identical* creator/caption can't be told apart, and caption-less videos are skipped rather than guessed.
- **App UI changes can break detection.** Instagram/YouTube/Facebook rename IDs and restructure layouts often. Because rules are JSON-driven and semantic (labels, not just raw IDs), detection degrades gracefully — a flagged "health" path is planned. Counts stay at a sensible pause instead of silently dropping to 0.
- **Interface languages & variants:** verified with English UI captures; Facebook Lite and other locales may need fresh layout dumps.
- **OEM background killers** can suppress reminders and widget updates until the app is reopened — the battery help screen inside the app explains the fix for your device.
- **Android-only** — iOS exposes no comparable API, so it's out of scope by design.

---

## 🗺️ Roadmap

- [ ] Per-app daily limits UI polish & per-app overrides
- [ ] Reel-detection "health" indicator (detect rule rot automatically)
- [ ] Focus schedules (e.g., no reels 22:00–07:00)
- [ ] Weekly digest notification
- [ ] Signed remote-updatable detection rules
- [ ] Widget variants (7-day sparkline, per-app)

---

## 🤝 Contributing

PRs welcome — especially:

1. 🧪 **Layout captures** from real phones for Facebook/Snapchat/other locales
2. 🌍 Translations of the app strings
3. 🧱 Flutter UI polish, a11y fixes, chart improvements

```bash
git checkout -b feature/amazing-thing
git commit -m "feat: add amazing thing"
git push origin feature/amazing-thing
```

---

<p align="center">
  <strong>Unreel</strong> — because "just five more" was never five. 🧠✋<br>
  <em>Values: privacy · offline-first · no dark patterns</em>
</p>
