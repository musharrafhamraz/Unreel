# Counting and reminder verification

## Behavior
- A reel must expose a visible caption/title and remain identifiable for five continuous seconds. Rapid skips, unreadable frames, app exits, lock screens and ambiguous multi-page transitions reset the timer.
- Creator + complete normalized caption + platform form the identity. Generic UI labels, likes, timestamps and offscreen preload nodes are excluded. Different captions from one creator are distinct.
- Room v2 stores counted identities without eviction, in the same transaction as the increment. Restarting, scrolling back or watching an identical identity on another day does not increment again. Daily history survives the v1 migration.
- Accessibility and Flutter now share one process so SharedPreferences settings changes are immediately visible. Foreground service behavior remains enabled.
- Reminders have Android delivery/boot receivers, use the device's IANA time zone, and fall back to inexact alarms if exact access is absent/revoked. Reopening the dashboard refreshes schedules after a time-zone change. Daily schedules respect DST; weekly tasks use weekday recurrence.
- The dashboard test button sends an immediate notification AND schedules a one-shot notification about one minute later.

## Verification commands
- `flutter test --no-pub`
- In `android`: `.\gradlew.bat :app:testDebugUnitTest`
- `flutter analyze --no-pub` (the existing UI has unrelated warnings)

## Device checks
1. Install the rebuilt APK, open it and enable notifications and accessibility. Existing accessibility grants may need toggling after changing the service process.
2. Tap the dashboard notification test. Leave the app. Confirm both the immediate and delayed notifications arrive. Inexact alarms can be delayed by Android/MIUI.
3. Watch an identifiable reel for five seconds; expect one count. Like, pause and resume it, then scroll away and back; expect no second count. Try two different captions from the same creator and rapid skips.
4. Leave the viewer or lock the screen before five seconds; expect no count. Disable tracking and verify counts stop.
5. Restart the process and revisit a counted identity. Reboot and verify future daily reminders remain registered.
6. Check midnight/configured reset-hour and app switching for count/time attribution.

## Limits requiring real-device validation
Accessibility does not expose a universal reel ID. Two distinct reels with identical creator/caption cannot be distinguished; changed captions can look like a new reel. Captionless reels or app versions with hidden/renamed IDs are skipped rather than guessed. Facebook/Lite/Snapchat particularly need real viewer node dumps to validate their markers. No claim of perfect detection across app versions is made.

The new identity algorithm cannot reliably translate old creator-only fingerprints. Historical counts are preserved, but a reel counted only by the old implementation can be counted once by the new algorithm.

Android force-stop and manufacturer background/autostart restrictions can suppress alarms until the app is reopened. Time-zone travel while the app remains closed needs native rescheduling beyond the plugin's stored-zone behavior. The follow-up debug APK was installed on the attached phone. Instagram produced stable identities and successful five-second confirmations in live service logs; Facebook and YouTube layout extraction is covered by captured-layout tests.

## Follow-up: observed app layouts (October 27)
The first revision missed Instagram captions because the username/caption were at depth 32, beyond the depth-28 limit, and the caption text belonged to an unnamed descendant. The new bounded snapshot walks to depth 64 and carries semantic container IDs down to children.

Facebook's installed app removes resource IDs. Its `Reels tab details` plus video-controls label now identify the viewer, and the enclosing caption and `View <creator>'s reels` label identify content. A navigation tab alone is not enough.

YouTube Shorts exposes channel/title as unnamed footer descendants. The parser now uses the channel accessibility label and text in the footer's left column, excluding the right-side action/counter rail and playback time.

Sanitized captures from the attached phone are in `android/app/src/test/resources/reel-layouts/`. Five additional layout tests cover these cases. Facebook Lite and other interface languages remain unverified; the observed fallback labels are English. The five-second viewing requirement remains unchanged.

