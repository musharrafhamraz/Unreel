# Prompt: Build "ScrollCount" — a Reels & Shorts Counter App (Flutter + Native Android)

> Paste this whole document into your AI coding assistant (or use it as your own spec).
> The app name "ScrollCount" is a placeholder; rename it freely.

---

## 1. Role and Goal

You are a senior Android + Flutter engineer. Build a production-quality Android app that **counts how many short-form videos (Instagram Reels, YouTube Shorts, Facebook Reels, Snapchat Spotlight/Stories-style reels) the user scrolls through each day**, shows the numbers in a clean dashboard, and optionally **enforces a daily limit** by blocking further scrolling.

The app is for personal use first, so favor reliability, privacy and simplicity over monetization features. Everything must work **fully offline**, with **no account and no network permission**.

---

## 2. Key Technical Reality (read this first)

Flutter alone **cannot** see what happens inside other apps. Counting reels requires an Android **AccessibilityService**, which must be written **natively in Kotlin**. Therefore:

- **Flutter** = all UI, state management, settings, charts, onboarding.
- **Kotlin (native Android)** = the AccessibilityService, detection logic, counting, blocking, local database.
- **Platform channels** (`MethodChannel` + `EventChannel`) connect the two.

The counting service must keep working **even when the Flutter UI is closed**, so the native side must never depend on the Flutter engine being alive.

---

## 3. Scope

### 3.1 MVP (build this first)
1. Onboarding with clear explanation + accessibility permission flow.
2. Live counting of reels/shorts for: Instagram, YouTube, Facebook, Snapchat (each individually toggleable).
3. Dashboard: today's total, per-app breakdown, estimated time spent, streak of days under limit.
4. History: last 7 / 30 days bar chart, per-app filter.
5. Daily limit setting (global, optional per-app).
6. Soft warning notification when reaching 80% and 100% of the limit.
7. Blocking mode: when the limit is hit, exit the reels screen (Back/Home action) and show a full-screen "You've hit your limit" overlay.
8. Settings: apps to track, limit, reset time (default 00:00), theme, data export/clear.
9. Local-only storage; export to CSV.
10. **Home screen widget** showing how many reels were watched today (see section 6.11), with an in-app button to add it.

### 3.2 Later (do NOT build in MVP, but keep the architecture ready)
- Remote-updatable detection rules (signed JSON).
- Extra widget variants (per-app widget, 7-day sparkline widget, lock-screen widget).
- Focus schedules (e.g., block 10pm–7am).
- Weekly report notification.
- "Brain rot score" gamification.

### 3.3 Explicit non-goals
- No iOS support (iOS has no equivalent API).
- No cloud sync, analytics SDKs, ads, or accounts.
- No screen recording, no reading of message/text content, no screenshots.

---

## 4. Tech Stack

| Layer | Choice |
|---|---|
| UI framework | Flutter (stable channel), Dart 3+, Material 3 |
| State management | Riverpod (`flutter_riverpod`, with `riverpod_annotation` optional) |
| Routing | `go_router` |
| Charts | `fl_chart` |
| Local notifications (UI-side) | `flutter_local_notifications` (or do it natively, see 6.7) |
| Native language | Kotlin |
| Native storage | SQLite via Room (preferred) or `SQLiteOpenHelper` |
| Min SDK | 26 (Android 8.0) |
| Target SDK | Latest stable |
| Build | Gradle Kotlin DSL |

---

## 5. Architecture

```
┌──────────────────────────── Flutter (Dart) ────────────────────────────┐
│  Presentation: screens, widgets, charts                                 │
│  State: Riverpod providers (todayStats, history, settings, permission)  │
│  Data layer: ScrollRepository  ──►  NativeBridge (platform channels)   │
└───────────────▲───────────────────────────────────┬─────────────────────┘
                │ EventChannel (live count stream)  │ MethodChannel (queries/commands)
┌───────────────┴───────────────────────────────────▼─────────────────────┐
│                         Native Android (Kotlin)                          │
│                                                                          │
│  ScrollAccessibilityService  ──►  DetectionEngine  ──►  ReelCounter      │
│        (receives events)          (rules per app)       (dedupe+debounce)│
│                                                              │           │
│                      LimitEnforcer  ◄── SettingsStore        ▼           │
│                  (warn / block / overlay)               Room Database    │
│                                                                          │
│  MainActivity (FlutterActivity)  +  BridgeHandler (channel endpoints)    │
│  ScrollCountWidgetProvider  (home screen widget, reads Room directly)    │
└──────────────────────────────────────────────────────────────────────────┘
```

### 5.1 Principles
- **Native owns the data.** Only Kotlin writes to the database. Flutter reads through the channel. This avoids two processes/engines fighting over one SQLite file.
- **Service is independent of UI.** The AccessibilityService runs in the app process regardless of whether an Activity or Flutter engine exists.
- **Live updates:** when the Flutter UI is open, the service pushes count changes through a singleton `EventSink` holder; when it's closed, the sink is null and nothing breaks.
- **Detection rules are data, not code.** Store per-app rules in a JSON file (`assets/detection_rules.json` on the native side) so they can be patched without rewriting logic when Instagram/YouTube change their UI.

---

## 6. Native Android Specification (Kotlin)

### 6.1 Project layout (native side)

```
android/app/src/main/
├── AndroidManifest.xml
├── kotlin/com/example/scrollcount/
│   ├── MainActivity.kt
│   ├── bridge/
│   │   ├── BridgeHandler.kt          // MethodChannel handlers
│   │   └── LiveCountStream.kt        // EventChannel sink holder
│   ├── service/
│   │   ├── ScrollAccessibilityService.kt
│   │   ├── DetectionEngine.kt
│   │   ├── DetectionRules.kt         // data classes + JSON parser
│   │   ├── ReelCounter.kt
│   │   └── LimitEnforcer.kt
│   ├── data/
│   │   ├── AppDatabase.kt            // Room
│   │   ├── DailyCountEntity.kt
│   │   ├── DailyCountDao.kt
│   │   └── SettingsStore.kt          // SharedPreferences wrapper
│   ├── ui/
│   │   └── BlockOverlayManager.kt    // WindowManager overlay
│   ├── widget/
│   │   ├── ScrollCountWidgetProvider.kt   // AppWidgetProvider
│   │   ├── WidgetUpdater.kt               // throttled refresh entry point
│   │   └── WidgetRenderer.kt              // builds RemoteViews per size/state
│   └── util/
│       └── DateUtils.kt              // "logical day" with custom reset hour
├── res/xml/accessibility_service_config.xml
├── res/xml/scrollcount_widget_info.xml
├── res/layout/widget_small.xml, widget_medium.xml, widget_disabled.xml
├── res/drawable/ (widget_bg, progress variants), res/drawable-night/ or values-night/ colors
└── assets/detection_rules.json
```

### 6.2 Manifest essentials

- `<service android:name=".service.ScrollAccessibilityService" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE" android:exported="false">` with intent filter `android.accessibilityservice.AccessibilityService` and `meta-data` pointing to `@xml/accessibility_service_config`.
- Permissions: `POST_NOTIFICATIONS` (Android 13+), `SYSTEM_ALERT_WINDOW` (only if using overlay; otherwise use an Activity-based block screen — see 6.6).
- **Do NOT request** `INTERNET`. Proving the app is offline is a feature.
- Register the widget: `<receiver android:name=".widget.ScrollCountWidgetProvider" android:exported="false">` with intent filter `android.appwidget.action.APPWIDGET_UPDATE` and `meta-data android:name="android.appwidget.provider" android:resource="@xml/scrollcount_widget_info"`. Also let this receiver (or a small second receiver) handle `ACTION_DATE_CHANGED`, `ACTION_TIMEZONE_CHANGED` and a custom `ACTION_DAY_ROLLOVER` alarm so the widget resets at the logical day boundary.
- Add `<queries>` entries for the tracked package names so `PackageManager` can resolve app names/icons on Android 11+.

### 6.3 `accessibility_service_config.xml`

```xml
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeViewScrolled|typeWindowContentChanged|typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagReportViewIds|flagRetrieveInteractiveWindows"
    android:canRetrieveWindowContent="true"
    android:notificationTimeout="100"
    android:packageNames="com.instagram.android,com.google.android.youtube,com.facebook.katana,com.snapchat.android"
    android:description="@string/accessibility_description"
    android:settingsActivity="com.example.scrollcount.MainActivity" />
```

Restricting `packageNames` is important for both battery and privacy: the service must receive events **only** from the tracked apps.

### 6.4 Detection rules (`detection_rules.json`)

Each tracked app has:
- `packageName`
- `reelsScreenIndicators`: a list of view IDs / class names / content descriptions that, when present in the window's node tree, mean "the user is on the reels/shorts screen".
- `pagerNodeIds`: the vertical pager/RecyclerView whose scroll indicates moving to the next video.
- `videoIdentityHints`: optional node IDs/texts (e.g., creator name, caption text) used to tell if the *video actually changed*.

Example structure (**the IDs below are illustrative placeholders; you MUST verify real IDs with Android Studio's Layout Inspector / `uiautomatorviewer` / `adb shell uiautomator dump` on the current app versions, because they change often**):

```json
{
  "version": 1,
  "apps": [
    {
      "id": "instagram",
      "displayName": "Instagram Reels",
      "packageName": "com.instagram.android",
      "reelsScreenIndicators": ["com.instagram.android:id/clips_viewer_view_pager"],
      "pagerNodeIds": ["com.instagram.android:id/clips_viewer_view_pager"],
      "videoIdentityHints": ["com.instagram.android:id/clips_author_username"]
    },
    {
      "id": "youtube_shorts",
      "displayName": "YouTube Shorts",
      "packageName": "com.google.android.youtube",
      "reelsScreenIndicators": ["com.google.android.youtube:id/reel_recycler"],
      "pagerNodeIds": ["com.google.android.youtube:id/reel_recycler"],
      "videoIdentityHints": ["com.google.android.youtube:id/reel_channel_bar"]
    },
    {
      "id": "facebook_reels",
      "displayName": "Facebook Reels",
      "packageName": "com.facebook.katana",
      "reelsScreenIndicators": [],
      "pagerNodeIds": [],
      "videoIdentityHints": []
    },
    {
      "id": "snapchat",
      "displayName": "Snapchat Spotlight",
      "packageName": "com.snapchat.android",
      "reelsScreenIndicators": [],
      "pagerNodeIds": [],
      "videoIdentityHints": []
    }
  ]
}
```

Leave Facebook/Snapchat arrays empty in the first pass and fill them after inspecting the real UI trees. The code must handle empty rules gracefully (app is listed but "detection not configured").

### 6.5 Counting algorithm (`ReelCounter`)

Goal: count **one increment per distinct video viewed**, not per scroll event (accessibility fires many events per swipe).

1. On each event from a tracked package, ask `DetectionEngine` whether the **reels screen is active** (search the active window's `AccessibilityNodeInfo` tree for any `reelsScreenIndicators`). Cache the result for ~300 ms to avoid walking the tree on every event. Always `recycle()`/release nodes correctly.
2. If not on a reels screen: reset "current video" state and return.
3. If on a reels screen: compute a **video signature** = hash of text from `videoIdentityHints` nodes (creator name + caption snippet), falling back to the pager's first visible child bounds/hash if no hints are found.
4. Increment the counter **only if**:
   - the signature differs from the last counted signature for that app, **and**
   - at least **700 ms** passed since the last increment (debounce), **and**
   - the new video stays on screen for at least **400 ms** (filters accidental flicks — implement via a short delayed check on a `Handler`).
5. When the user leaves the reels screen and comes back, the first video shown counts as a new view only if the signature differs from the last one.
6. After incrementing: write to DB (batched, see below), push to `LiveCountStream`, call `LimitEnforcer.onCountChanged(...)`.

**DB write batching:** keep an in-memory count and flush to Room every 5 increments or 10 seconds (whichever first) and on `onUnbind`/`onInterrupt`, to reduce I/O.

**Time estimate:** also track **seconds spent on the reels screen** per app per day (start timer when reels screen becomes active, stop when it's not). Store alongside count.

### 6.6 Blocking and limits (`LimitEnforcer`)

- Read limits from `SettingsStore` (global limit + optional per-app override; `0` = unlimited).
- At **80%**: post a notification ("You've watched X of Y reels today").
- At **100%**: post a notification and enter **blocked state** for the rest of the logical day.
- While blocked and the user enters a reels screen:
  1. Call `performGlobalAction(GLOBAL_ACTION_BACK)`, then if still on reels after ~500 ms, `GLOBAL_ACTION_HOME`.
  2. Show a block screen. Prefer a lightweight **`BlockActivity`** (translucent, `FLAG_ACTIVITY_NEW_TASK`) over `SYSTEM_ALERT_WINDOW` — it avoids a scary extra permission. Offer overlay mode only as an optional setting.
  3. The block screen shows: "Limit reached", today's count, a calm message, a **"Go back to home"** button, and optionally a **"Snooze 5 min"** button (configurable, can be disabled for strict mode; each snooze is logged).
- Blocking must apply only to the **reels screen**, never to the whole app (users must still be able to DM, post, etc.).
- Provide a **strict mode** setting: when ON, the limit cannot be changed or disabled until the next day (store a "locked until" timestamp).

### 6.7 Notifications
Implement notifications **natively** from the service (NotificationManager + a channel `limit_alerts`), because the Flutter engine may not be running. On Android 13+, check the `POST_NOTIFICATIONS` permission before posting.

### 6.8 Logical day
`DateUtils.logicalDay(now, resetHour)` returns the date key (`yyyy-MM-dd`) such that times before `resetHour` count toward the previous day. Default reset hour = 0. Listen for timezone/date changes (`ACTION_TIMEZONE_CHANGED`, `ACTION_DATE_CHANGED`) and re-evaluate the current day key.

### 6.9 Database schema (Room)

```
Table: daily_counts
  id            INTEGER PK AUTOINCREMENT
  day           TEXT      -- 'yyyy-MM-dd' logical day
  app_id        TEXT      -- 'instagram' | 'youtube_shorts' | 'facebook_reels' | 'snapchat'
  count         INTEGER   -- number of videos
  seconds       INTEGER   -- time spent on reels screen
  UNIQUE(day, app_id)

Table: events_log   (optional, for debugging; cap to last 1000 rows)
  id, timestamp, app_id, signature_hash, event_type
```

DAO methods needed: `increment(day, appId, deltaCount, deltaSeconds)` (upsert), `getDay(day)`, `getRange(startDay, endDay)`, `clearAll()`, `exportAll()`.

### 6.10 Resilience
- Handle `onServiceConnected`, `onInterrupt`, `onUnbind`; flush pending counts.
- Guard everything in `try/catch`; a crash in the service disables it for the user until they re-enable.
- Handle OEM battery killers: provide an in-app help screen with deep links to battery/autostart settings for Xiaomi, Oppo/Realme, Vivo, Huawei, Samsung ("Don't optimize"), with `Intent` fallbacks.
- Detect when the accessibility service has been turned off by the system and show a banner in the dashboard.

### 6.11 Home Screen Widget (native, required for MVP)

**Goal:** the user can long-press their home screen, add the ScrollCount widget, and always see **how many reels they've watched today** without opening the app.

**Why native:** widgets are rendered by the launcher via `RemoteViews`, which Flutter cannot draw. Build the widget in Kotlin with XML layouts. It reads the Room database directly, so it works even if the Flutter UI has never been opened or has been killed.

#### Behavior
- Shows **today's total** (logical day, respecting the reset hour), labeled "reels today".
- Updates **live-ish**: refreshed after each batched DB flush from the counting service, throttled to **at most once every ~5 seconds**, and **only when the screen is interactive** (`PowerManager.isInteractive`) to save battery. Always do one final refresh when the screen turns off/on.
- `updatePeriodMillis` in the provider XML should be `0` (the system minimum of 30 min is useless here); updates are push-based from the service instead.
- **Day rollover:** schedule an inexact alarm (`AlarmManager.setAndAllowWhileIdle`) for the next logical-day boundary, and also handle `ACTION_DATE_CHANGED` / `ACTION_TIMEZONE_CHANGED`, so the widget resets to 0 at the right time even if no reel was watched. Re-schedule after reboot (`BOOT_COMPLETED`) and whenever the reset-hour setting changes.
- **Tap action:** tapping anywhere on the widget opens the app (`PendingIntent.getActivity` with `FLAG_IMMUTABLE`) on the dashboard.
- Data access: in `onUpdate`/`onReceive`, use `goAsync()` and a background thread/executor to query Room, then push `RemoteViews` through `AppWidgetManager.updateAppWidget`. Never query the DB on the main thread.
- Multiple widget instances must all be updated (`getAppWidgetIds`).

#### Widget states
| State | What it shows |
|---|---|
| **Normal, no limit** | Big number + "reels today" + small time estimate ("≈ 42 min") |
| **Normal, with limit** | Big number "87 / 100", thin progress bar, "reels today" |
| **≥ 80% of limit** | Same as above, number/bar in warning color |
| **Limit reached** | Number + bar in danger color, label "Limit reached" |
| **Service disabled** | Dimmed layout with "Counting paused — tap to enable"; tapping opens the accessibility settings screen via the app |
| **No data yet today** | "0" and "reels today" (never blank or an error) |

#### Sizes and layouts
Support resizing via `resizeMode="horizontal|vertical"`, and ship two layouts:

1. **Small (2×2):** large number centered, "reels today" caption, progress ring/bar if a limit is set.
2. **Medium/wide (4×2):** left side = big number + caption + time estimate; right side = compact per-app breakdown (up to 4 rows: app color dot, name, count) and the progress bar along the bottom.

Pick the layout by size:
- Android 12+ (API 31+): pass a `Map<SizeF, RemoteViews>` to `RemoteViews(Map)` so the launcher chooses the layout responsively, and set `targetCellWidth/targetCellHeight` in the widget info XML.
- Android 8–11: choose by `OPTION_APPWIDGET_MIN_WIDTH/HEIGHT` in `onAppWidgetOptionsChanged`.
- Provide `previewLayout` (API 31+) and `previewImage` (fallback) so the widget picker shows a realistic preview.

#### Widget info XML (`scrollcount_widget_info.xml`)
```xml
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:minResizeWidth="110dp"
    android:minResizeHeight="110dp"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="0"
    android:widgetCategory="home_screen"
    android:initialLayout="@layout/widget_small"
    android:previewLayout="@layout/widget_small"
    android:description="@string/widget_description" />
```

#### Design
- Rounded container (corner radius 20dp; on Android 12+ use `@android:dimen/system_app_widget_background_radius` so it matches the launcher), semi-opaque surface color, comfortable 12–16dp padding.
- Follow system light/dark theme using `values/colors.xml` + `values-night/colors.xml` (RemoteViews can't read Flutter themes, so duplicate the palette from section 10 as native color resources).
- Big number: 40–48sp bold; caption 12sp secondary color; use `sp` but keep the layout from clipping at large font sizes (use `autoSize` text where supported, or `setTextViewTextSize` bucketed by digit count so 3- and 4-digit numbers fit).
- Progress color: `RemoteViews` can't freely tint everything on old APIs, so include **three ProgressBar variants (primary / warning / danger)** and toggle visibility with `setViewVisibility`; set text colors with `setTextColor`.
- Accessibility: set `contentDescription` on the root, e.g. "ScrollCount: 87 of 100 reels watched today".

#### Adding the widget from inside the app
- Dashboard shows a dismissible card: **"Add a widget to your home screen"**, and Settings has an **"Add widget"** button.
- Implement `requestPinWidget` on the native side using `AppWidgetManager.requestPinAppWidget(componentName, null, successCallback)` (API 26+; check `isRequestPinAppWidgetSupported()`).
- If pinning isn't supported by the launcher, show instructions: "Long-press your home screen → Widgets → ScrollCount".
- Expose `isWidgetAdded` (any widget ids exist) so the dashboard can hide the prompt once the widget is placed.

#### Edge cases
- Launchers/OEMs may throttle or freeze widget updates for apps in battery-restricted mode; the OEM battery help screen (6.10) should mention that this also affects the widget.
- If the app was force-stopped, widgets show stale data until the next update; on `onEnabled`/`onUpdate` always re-read the DB so stale numbers are corrected as soon as the launcher refreshes.
- After "Clear all data" in settings, immediately refresh all widgets to 0.

---

## 7. Platform Channel Contract

### 7.1 `MethodChannel("scrollcount/methods")`

| Method | Args | Returns |
|---|---|---|
| `isAccessibilityEnabled` | — | `bool` |
| `openAccessibilitySettings` | — | `void` (launches `Settings.ACTION_ACCESSIBILITY_SETTINGS`) |
| `getToday` | — | `{day, total, totalSeconds, perApp: [{appId, count, seconds}]}` |
| `getRange` | `{startDay, endDay}` | `List<{day, appId, count, seconds}>` |
| `getSettings` | — | settings map |
| `updateSettings` | settings map | `bool` |
| `getTrackedApps` | — | `[{appId, displayName, packageName, installed, detectionConfigured}]` |
| `exportCsv` | — | file path or CSV string |
| `clearAllData` | — | `bool` |
| `openBatterySettings` | — | `void` |
| `requestNotificationPermission` | — | `bool` |
| `isWidgetSupportedForPin` | — | `bool` |
| `requestPinWidget` | — | `bool` (true if the pin request was shown) |
| `isWidgetAdded` | — | `bool` |
| `refreshWidgets` | — | `void` (forces an immediate widget update) |

### 7.2 `EventChannel("scrollcount/live")`
Emits `{day, appId, count, total}` every time a count changes while the Flutter UI is attached. Dart side exposes it as a `Stream<LiveCount>`.

### 7.3 Settings map

```json
{
  "globalLimit": 100,
  "perAppLimits": { "instagram": 0, "youtube_shorts": 0 },
  "trackedApps": ["instagram", "youtube_shorts", "facebook_reels", "snapchat"],
  "blockingEnabled": true,
  "strictMode": false,
  "snoozeMinutes": 5,
  "resetHour": 0,
  "warnAtPercent": 80,
  "overlayMode": false
}
```

---

## 8. Flutter Specification

### 8.1 Folder structure

```
lib/
├── main.dart
├── app.dart                      // MaterialApp.router, theme
├── core/
│   ├── theme/ (colors.dart, typography.dart, app_theme.dart)
│   ├── router/app_router.dart
│   └── utils/ (date_utils.dart, formatters.dart)
├── data/
│   ├── native_bridge.dart        // wraps MethodChannel/EventChannel
│   ├── models/ (daily_stat.dart, app_stat.dart, settings.dart, live_count.dart)
│   └── scroll_repository.dart
├── providers/
│   ├── permission_provider.dart
│   ├── today_provider.dart       // combines getToday() + live stream
│   ├── history_provider.dart
│   └── settings_provider.dart
└── features/
    ├── onboarding/
    ├── dashboard/
    ├── history/
    ├── limits/
    ├── apps/
    └── settings/
```

### 8.2 State rules
- `todayProvider` = `StreamProvider` that first loads `getToday()`, then merges incoming `EventChannel` updates.
- Re-check `isAccessibilityEnabled` every time the app resumes (use `WidgetsBindingObserver`) — users toggle it in system settings and come back.
- Immutable models (use `freezed` or hand-written `copyWith`).
- All native calls wrapped in a repository that converts `PlatformException` into typed errors shown with friendly messages.

---

## 9. Screens and UX

### 9.1 Onboarding (3–4 pages, skippable only the intro, not the permission)
1. **Welcome:** "See how much you really scroll." Simple illustration.
2. **How it works:** plain-language explanation — "We use Android's Accessibility feature to notice when a new reel appears. We never read your messages, passwords or content, and nothing leaves your phone."
3. **Choose apps** to track (toggle list with app icons).
4. **Enable permission:** step-by-step visual guide ("Open Settings → Installed apps → ScrollCount → turn on") with a button that calls `openAccessibilitySettings`. Auto-advance when `isAccessibilityEnabled` becomes true.
   - Include a note about Android 13+ "Restricted setting" for sideloaded apps: *App info → ⋮ → Allow restricted settings*.
5. Ask for notification permission (Android 13+), optional.

### 9.2 Dashboard (home)
- **Hero card:** big circular progress ring — today's count vs. limit (if no limit, just a large number). Subtitle: "reels today" + estimated time ("≈ 42 min").
- **Status banner** (only if service is off): red/amber "Counting is paused — tap to enable".
- **Per-app cards:** icon, name, count, mini bar of share of total.
- **Widget prompt card** (only if no widget is placed yet): "Add a widget to your home screen" with an **Add** button (calls `requestPinWidget`) and a dismiss action.
- **Insight chip row:** "Yesterday: 134", "7-day avg: 98", "Streak under limit: 3 days".
- Pull-to-refresh; numbers animate when they change (count-up animation).

### 9.3 History
- Segmented control: **7 days / 30 days**.
- Bar chart (stacked per app or single), tap a bar for the day's details.
- Below: list of days with total + time.
- Filter chips by app.

### 9.4 Limits
- Slider/number stepper for the daily global limit (0 = off), with presets (50 / 100 / 150 / 200).
- Per-app limit overrides (expandable list).
- Toggles: *Block when limit reached*, *Strict mode*, *Allow snooze*, *Warning at 80%*.
- Preview button that shows what the block screen looks like.

### 9.5 Apps
- List of the four apps: installed/not installed, "detection OK / not configured" tag, toggle to track.

### 9.6 Settings
- **Add widget to home screen** (same action as the dashboard card), theme (system / light / dark), reset hour, export CSV, clear data (with confirmation), battery optimization help, privacy explanation, app version, link to "How detection works".

### 9.7 Block screen (native `BlockActivity`)
- Calm full-screen design, dark background, large "Limit reached" text, today's number, one-line encouraging message (rotate a few), primary button "Go home", secondary "Snooze 5 min" (if allowed).
- No dark patterns: easy to understand, no guilt-tripping.

---

## 10. Design System

**Mood:** calm, focused, slightly playful — not a scary "addiction" app. Clean cards, generous spacing, soft rounded corners.

| Token | Light | Dark |
|---|---|---|
| Background | `#F6F7FB` | `#0E1116` |
| Surface/card | `#FFFFFF` | `#171B22` |
| Primary | `#4F46E5` (indigo) | `#8B93FF` |
| Success (under limit) | `#16A34A` | `#4ADE80` |
| Warning (≥80%) | `#F59E0B` | `#FBBF24` |
| Danger (limit hit) | `#E11D48` | `#FB7185` |
| Text primary | `#111827` | `#F3F4F6` |
| Text secondary | `#6B7280` | `#9CA3AF` |

- Per-app accent colors: Instagram `#E1306C`, YouTube `#FF0000`, Facebook `#1877F2`, Snapchat `#FFFC00` (use with dark text).
- Typography: Inter or Plus Jakarta Sans (via `google_fonts` is fine if bundled offline; otherwise bundle font files in assets since the app has no internet permission). Hero number: 56–64 sp, weight 700.
- Corner radius 20 on cards, 14 on buttons/chips.
- Progress ring color shifts: primary → warning at 80% → danger at 100%.
- Motion: 250–350 ms ease-out transitions; count-up animation; subtle haptic when the limit is reached.
- Accessibility: min tap target 48dp, contrast AA, support font scaling, add `Semantics` labels.

---

## 11. Privacy, Security and Store Policy

- Declare clearly in-app and in the privacy policy: the app uses the AccessibilityService **only** to detect the reels screen and count videos; it does **not** collect, store or transmit any screen content, text, or personal data.
- No `INTERNET` permission, no analytics, no crash-reporting SDKs.
- Never log text content of other apps; only store hashed signatures transiently in memory (do not persist raw captions/usernames).
- If you ever publish on Google Play: the AccessibilityService requires a **Permissions Declaration Form** and a prominent in-app disclosure + consent screen before the user is sent to settings. Digital-wellbeing/self-control tools are an area where reviewers are strict, so keep the disclosure honest and specific. For personal use, sideloading avoids this entirely.
- Android 13+ restricts accessibility for sideloaded apps until the user allows "restricted settings" — document this in onboarding.

---

## 12. Performance and Battery Requirements

- Limit event types and package names in the service config (see 6.3).
- Avoid walking the node tree on every event; throttle to at most ~3 tree scans per second per app.
- Always release `AccessibilityNodeInfo` objects.
- Batch DB writes (see 6.5).
- Throttle widget refreshes to once per ~5 s and only while the screen is on; widget updates must never block the accessibility service thread.
- Target: < 1% battery per day attributable to the service during normal use; no visible UI jank in the tracked apps.

---

## 13. Testing Plan

**Unit tests (Kotlin):** `ReelCounter` debounce/dedupe logic, `DateUtils.logicalDay`, rule parsing, `LimitEnforcer` thresholds.
**Unit tests (Dart):** repository mapping, providers, formatters.
**Widget tests:** dashboard states (service off, no data, under limit, over limit), onboarding flow.
**Manual device matrix:** at least one stock Android, one Samsung (One UI), one Xiaomi/Oppo (aggressive battery management), Android 8, 12, 14+.
**Manual scenarios:**
1. Swipe 20 reels on Instagram → count is 20 (±1).
2. Rapid flicking through reels → no double counting.
3. Pause on one reel for 5 minutes → count stays 1, time keeps increasing.
4. Leave and re-enter reels → no false increment for the same video.
5. Hit limit → blocked, can still open DMs/profile.
6. Kill Flutter UI from recents → counting continues; reopen → numbers match.
7. Reboot → service restarts (user must have it enabled), counts persist.
8. Midnight rollover and custom reset hour.
9. Add the widget (2×2 and 4×2); watch the number rise while scrolling reels and match the dashboard.
10. Resize the widget; the layout switches cleanly. Check light/dark and large font sizes (3–4 digit counts must not clip).
11. Reach 80% and 100% of the limit; widget color changes. Disable the service; widget shows the "paused" state.
12. Midnight/reset-hour rollover resets the widget to 0 without opening the app; reboot keeps the widget correct.
13. App update changes UI IDs → the app shows "detection may be outdated" instead of silently counting 0.

---

## 14. Known Risks (document them in the README)

1. **UI changes by Instagram/YouTube/etc. can break detection** at any time. Mitigation: rules in a JSON file, a "detection health" indicator (if the user spent > 2 min in a tracked app's reels screen but count stayed 0, flag it), and an easy way to update rules.
2. Facebook and Snapchat detection is the least predictable; ship them as "beta".
3. Some OEMs kill background services; the in-app help screen is required, not optional.
4. Counts are **estimates** of videos viewed, not exact.

---

## 15. Deliverables and Working Instructions for the AI

Work in these milestones and **stop for review after each**:

1. **M1 – Skeleton:** Flutter project, theme, routing, empty screens, platform channel plumbing with stub data.
2. **M2 – Native service + Instagram only:** AccessibilityService, rules JSON, `ReelCounter`, Room DB, `getToday`, live `EventChannel`. Include a simple debug screen showing the current detection state (on reels screen? signature? last increment).
3. **M3 – Dashboard + history UI** wired to real data.
4. **M4 – Add YouTube Shorts**, then Facebook/Snapchat (beta).
5. **M5 – Limits, notifications, block screen, strict mode.**
6. **M6 – Home screen widget:** provider, small + medium layouts, all states, throttled updates from the service, day-rollover alarm, in-app "Add widget" (pin request) flow.
7. **M7 – Onboarding, settings, export, OEM battery help, polish, dark mode.**
8. **M8 – Tests + README** (setup, how to update detection rules, how to find view IDs with Layout Inspector, known limitations).

**Output requirements:**
- Provide complete, compilable code per milestone (no pseudo-code placeholders except the detection IDs which must be flagged for verification).
- Explain every file's purpose briefly.
- Keep Dart code null-safe, lint-clean (`flutter_lints`), and well-commented where logic is non-obvious (especially the counting algorithm).
- Where something can't be verified without a real device (view IDs), say so explicitly and give the exact steps to verify it.
- Ask me **at most one clarifying question** at a time, and only if blocked.

---

## 16. Acceptance Criteria (definition of done for MVP)

- [ ] Enabling the accessibility service from onboarding works and the dashboard reflects the state live.
- [ ] Instagram Reels and YouTube Shorts counts are within ±5% of manual counts over a 50-video test.
- [ ] Counting continues with the app UI closed and after the device reboots.
- [ ] Daily limit triggers 80% and 100% notifications and blocks only the reels screen.
- [ ] History charts show correct 7/30-day data; CSV export works.
- [ ] A home screen widget can be added (from the app and from the launcher), shows today's reel count, updates within ~5 s of a change while the screen is on, resets at the day boundary, and shows a clear "paused" state when the service is off.
- [ ] Widget works in light/dark mode, at 2×2 and 4×2 sizes, and with the Flutter UI closed.
- [ ] App has no `INTERNET` permission and works fully offline.
- [ ] Dark and light themes both look polished; supports font scaling.
- [ ] README documents setup, detection-rule updates, and limitations.
