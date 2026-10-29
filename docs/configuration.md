# Configuration

## Date arrows

Click **‹** for the previous calendar day or **›** for the next. A selected date
is evaluated at **12:00 local time**, avoiding ambiguous midnight/DST times.
The displayed phase, image, illumination, previous/next events and next full
moon all refer to that selected instant. Its countdown is the interval from
selected noon to the next full moon, rather than the real current countdown.

The header marks this mode **PREVIEW** / **VISTA PREVIA**. Click **Today** / **Hoy**
to restore the real clock immediately. Preview does not persist across a refresh
or restart. Arrows stop at the supported 2000–2050 UTC range. This works in both
layouts and uses local calendar dates across 23/25-hour DST days.

Browsing never changes the operating system clock or the notification schedule.
Any enabled alerts remain tied to real UTC events and real current time.

## Settings

Edit `Lunar/@Resources/Settings.inc` as plain text. Keep the `[Variables]` header;
use one `Name=Value` per line. Save and refresh the skin. A running skin reads
these preferences only at initialization. No administrator access is needed.

| Setting | Default | Values and behavior |
| --- | --- | --- |
| Scale | 1 | 0.5–2.5; all meter geometry and fonts scale together |
| Opacity | 240 | Integer 0–255 for text and image; 0 makes them invisible |
| BackgroundOpacity | 200 | Integer 0–255 for the dark background only; 0 transparent, 255 solid |
| CornerRadius | 20 | Rounded background corners in base pixels, 0–90; 0 makes square corners |
| Language | en | `en` or `es`; other values fall back to English |
| DateFormat | long | `long` localized month, `iso` YYYY-MM-DD, `dmy` DD/MM/YYYY |
| Hour24 | 1 | 1: 24-hour; 0: 12-hour with AM/PM |
| Compact | 0 | 1: smaller Moon and shorter layout, no optional events |
| ShowEvents | 1 | 1: previous/next primary phase in expanded mode |
| Latitude | 0 | Approximate degrees -90–90; only its sign affects rotation |
| UpdateSeconds | 30 | 5–300 seconds for dates, countdown and reminder checks |
| Notifications | 0 | Global visual-reminder opt-in; 0 disables all reminder IO |
| NotifyAdvance | 1 | Enable advance notices after global opt-in |
| NotifyAtEvent | 1 | Enable event-occurrence notices after global opt-in |
| AdvanceHours | 24 | 6, 12, 24 or 48; other values use 24 |
| NotifyAllPhases | 0 | 0: full moons only; 1: also new, first and last quarter |
| CatchUpHours | 6 | 0–48; maximum lateness for missed reminders |

Numeric values are clamped; invalid numbers use defaults. Boolean settings are
enabled only by the literal `1`. Rainmeter is still an INI/code environment:
do not paste downloaded expressions into settings. DateFormat is an allowlist,
not an arbitrary C `strftime` string, avoiding Windows format inconsistencies.

Rainmeter's normal drag/position settings control location. Its skin-level
transparency affects the whole widget, including its background. The subtle
separator has a fixed low alpha; Opacity controls the text and Moon.
BackgroundOpacity independently controls the dark rounded panel. Its height
follows the selected layout and expands while a visual alert is shown.
CornerRadius scales with Scale. With BackgroundOpacity=0, only a nearly invisible
hit area remains so the widget can be dragged.

For a light wallpaper, try `BackgroundOpacity=220`. For a softer panel use `140`,
or set `0` to restore the original transparent look. Save and refresh the skin.
When upgrading, keep your existing Settings.inc and add the two new settings;
older settings files use defaults of 200 and 20 automatically.

For larger or high-DPI displays increase Scale. The Moon sources are 256×256;
large scale values interpolate the image. Test sharpness on your own monitor;
mixed-monitor DPI behavior is governed by Rainmeter. Display scaling and Scale
can both affect physical size.

Example for a Spanish-speaking user in Santiago:

```ini
Language=es
Latitude=-33
Hour24=1
DateFormat=long
Scale=1.25
```

No GPS or longitude is needed. Latitude is not inferred from language, Windows
time zone or an IP address. Hemisphere is independent of local time-zone settings.
At the equator the northern convention is used; exact horizon orientation there
cannot be inferred from latitude alone.

## Notifications

Enable `Notifications=1` explicitly. Preferences remain in Settings.inc across
refreshes/restarts. Each upcoming lunar event has a stable lunation/quarter ID;
the reminder key also contains the advance-hours value (or zero for occurrence).
Each key is appended to NotificationState.dat **before** it is displayed.

Changing the advance-hours value selects a different reminder. Turning reminders
off and on retains the journal, so previously delivered keys remain suppressed.
Enabling a setting for the first time can catch up a recent eligible reminder.
Occurrence reminders mean the calculated event time, within the calculation's
error and polling delay, not detection of an observed astronomical event.

An advance notice missed by less than CatchUpHours is shown on resume, provided
the event is still in the future. Occurrence notices catch up in the same window.
Older triggers are silently skipped. `CatchUpHours=0` requires a check at the
exact calculated second, so it will usually miss events: use at least 1 for
reliable catch-up. Reminders depend on the system clock being correct.

Messages remain inside the widget for ten minutes or until clicked. Multiple
eligible messages share the alert area; the tooltip contains the complete text.
The widget can be hidden behind other windows: there is no toast, sound, focus
change, service, task, startup registration or alert while Rainmeter is stopped.
No Windows toast API exists in the supported built-in Lua/skin interface; adding
a notification helper would introduce another executable or plugin, so this
release uses the safe visual fallback.

Keep one active instance per installed Lunar resource folder. The journal is
designed for that Rainmeter instance, not concurrent processes sharing files.
Normal restarts and refreshes retain duplicate suppression. A disk failure,
sudden power loss before OS cache flush, manual journal deletion or restoring an
old backup can lose history; Lua does not provide durable disk transactions.
If a write/close fails, the notice is suppressed and Rainmeter logs a warning.

## Local time and DST

Windows' selected local time zone is used automatically via `os.date('*t', utc)`.
The code never subtracts today's offset from an upcoming event. For mainland
Santiago use Windows' Santiago zone and keep Windows time-zone rules updated.
Other Chilean regions can follow different rules; select the zone for your region.
There is no bundled IANA time-zone database or hardcoded Chile offset.

Changing the OS time zone while the widget runs is picked up on its next data
poll (refresh the skin if the C runtime has retained stale zone information).
UTC event IDs and countdowns are unaffected by local DST clock jumps. The display
explicitly says `local time`/`hora local`; it does not claim an IANA zone ID.
