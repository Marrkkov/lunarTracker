# Validation report and manual checklist

Initial validation date: 2026-10-29. Results below are observed runs, not promised
coverage or invented integration results. Artifacts in docs/previews are captured
windows or explicitly labeled generated asset previews.

Version 0.1.1 added an independently adjustable rounded panel. Its
933 automated Lua checks and 937 native checks passed. A live
Rainmeter capture verifies the default expanded panel (opacity 200, radius 20).
Compact mode at Scale=1.5, opacity 140 and radius 30 was also inspected in native
captures, including its expanded test alert and immediate panel shrink on dismissal.

Version 0.1.2 adds date arrows and Today/Hoy. The suite now passes 946 core
assertions plus 14 widget navigation assertions in Fengari, and 950 core
assertions plus the same 14 widget assertions in native Rainmeter Lua 5.1.
Navigation checks cover leap/month/year rollovers, local noon over Chile's
23/25-hour DST days, immediate phase image updates, preview countdowns, Today
restoring live operation, and real notification clock/event isolation. Actual
Rainmeter window captures verify the controls and a 14-day future Moon preview.
The previous-day control was also verified in compact Spanish mode at 1.5× scale
with southern orientation; the date, Moon, label and preview event details fit.

## Automated results

| Run | Observed result |
| --- | --- |
| Node 24.15.0 + locked Fengari | 946 core + 14 widget assertions passed; PNG checks passed |
| Installed Rainmeter 4.5.28.3936, 64-bit, Lua 5.1 | 950 core + 14 widget assertions passed, including four native journal IO checks |
| Independent event data | 298 USNO events in 2000, 2024, 2026, 2030, 2049, 2050 |
| Largest absolute event difference | 45.1 seconds; test threshold 120 seconds |
| Independent illumination data | Four noon references, threshold two percentage points; passed |
| Image assets | All 120 PNGs decoded, 256×256, transparent corners; waxing/waning brightness checks passed |
| Release ZIP | 133 allowlisted entries read successfully by independent .NET ZIP support; two builds had identical SHA-256 |

Node sets its process time zone to America/Santiago. Fengari's `os.date` uses
Node's Date/ICU behavior, so this is a real local-time conversion test but not a
test of the Windows C runtime. The separate native run used Windows' **Pacific
SA Standard Time** and exercised Rainmeter's own C-runtime `os.date`, including:

- Full moon 2026-11-24 14:53 UT → November 24, 11:53 local summer time.
- Full moon 2026-06-29 23:56 UT → June 29, 19:56 local winter time.
- Full moon 2026-12-24 01:28 UT → December 23, 22:28 local.
- 2026-04-05 02:59 → 03:00 UTC repeats local 23:59 → 23:00 on April 4.
- 2026-09-06 03:59 → 04:00 UTC skips local 23:59 → 01:00.

These rules are supplied by Windows/Node, not bundled into the widget. The
expected 2026 Santiago transitions are validated against both installed
implementations. Changed legislation or outdated time-zone databases require
updated OS/test expectations. Other time zones have not been exhaustively tested.

The Lua assertions cover all four phases; phase names/illumination at primary
events; leap days, month/year boundaries and support limits; next-event rollover;
countdown flooring and clamping; 12/24-hour and Spanish formatting; reminders
disabled/enabled, thresholds, catch-up expiration, optional events and deduplication.
Native-only IO checks exercise append/reload, duplicate suppression and failure
when the destination cannot be opened. There are no network calls in tests.

Illumination's two-percentage-point threshold is a test criterion, not a measured
global error bound. The four intermediate references and principal-event cases
are a limited sample. The two-minute event threshold is similarly a declared
validation tolerance; the six sampled years do not prove all dates through 2050.
The ΔT forecast is especially uncertain toward the end of the supported range.

## Observed Windows integration

Host: Windows 11 Pro 25H2, build 26200.9711. The project ran in a second, isolated
Rainmeter profile staged in `tests/.native`, without installing into or replacing
the user's existing profile.

- The production skin loaded on the native Rainmeter renderer without errors.
- Actual window captures verified Moon texture/shading, fonts, date, countdown,
  separator and optional event lines.
- English expanded mode and Spanish compact mode were inspected visually.
- The Spanish compact capture uses Scale=1.5 and Latitude=-33, rotating both
  lunar texture and illumination; the expanded capture uses the northern default.
- An encoding problem discovered in the first capture was fixed with Unicode
  character variables. The corrected capture and Spanish accents were verified.
- A **test-only** copy froze Lua's clock at a calculated full moon, opted into
  notifications and displayed the in-widget alert. This did not alter the OS
  clock or source settings. After refreshing the skin, the journal retained one
  occurrence key and the same alert was suppressed.
- Native assertions ran in the actual Rainmeter Lua 5.1 environment. No external
  Lua executable was installed or required for the widget.

The captured test notification is not evidence that a real astronomical event
occurred during development. No physical sleep/reboot, OS toast, mixed-DPI
monitor move, long-running performance benchmark or `.rmskin` installation has
been verified. CI configuration is supplied but has not run on GitHub yet.

## Reproduce

From the repository root, with Node 22+:

```text
npm ci --ignore-scripts
npm test
npm run assets
npm run package
```

PNG rendering is deterministic for the checked-in source map and locked tooling.
The ZIP builder uses sorted allowlisted paths and fixed archive timestamps.
Inspect its SHA-256 manifest and contents; dist is ignored by Git.

For the optional native run:

1. On a Windows 11 test machine with Rainmeter installed, select Santiago as
   the test user's OS time zone. The suite's local-time expectations assume it.
   Do not change a user's zone without permission; use a test account if needed.
2. Run `node tools/native-smoke.cjs`. It only stages files in `tests/.native`.
3. Launch Rainmeter with the **absolute path** to
   `tests/.native/Rainmeter.ini` as its sole argument. This creates an isolated
   profile. Use its own tray menu for refresh/quit; an unqualified executable
   bang can address a different instance.
4. Inspect `tests/.native/results.txt` and its Rainmeter.log. This runs the same
   production modules/spec and also the native persistence tests.
5. Optionally stage `node tools/native-smoke.cjs --alert` and refresh the test
   profile to simulate an occurrence. That flag modifies only the staged copy.
   The first run writes an event key; a refresh suppresses it. The journal is
   deliberately retained by staging. To repeat from a clean state, unload the
   test skin and delete only its staged NotificationState.dat.
6. Quit the isolated process. The normal user's Rainmeter instance is separate.

The optional C# development helper can send a documented command to a selected
Rainmeter PID or capture only its meter window via PrintWindow. It is neither a
plugin nor part of the installed skin. A missing/incorrect PID must fail rather
than target an arbitrary user's normal instance.

## Remaining manual release checks

- [ ] Install the reviewed ZIP into a clean standard-user Rainmeter profile.
- [ ] Verify dragging, saved position, click-through and Rainmeter opacity.
- [ ] Test Scale=0.5/1/1.5/2/2.5, 100%/150%/200% Windows DPI and multiple monitors.
- [ ] Check long dates, both languages and 12/24-hour clocks at all scale extremes.
- [ ] Change OS zones to UTC, Santiago and a zone ahead of UTC. Confirm the same
      event changes local calendar date correctly while the countdown stays fixed.
- [ ] Disconnect networking and verify normal updates for a full day.
- [ ] With reminders opted in, suspend across a trigger and resume within/after
      the catch-up window. Confirm one eligible alert or an expired notice.
- [ ] Restart Rainmeter/Windows after a delivered reminder; confirm it is not
      repeated. Verify the widget does not claim alerts while Rainmeter is off.
- [ ] Test a deliberately unwritable journal in a disposable profile; inspect
      the warning and confirm reminders are suppressed without breaking the widget.
- [ ] Monitor Rainmeter CPU/private memory over a day and near event rollover.
- [ ] Build/inspect a genuine `.rmskin` with Skin Packager, then validate a clean
      install, upgrade preference/history preservation and uninstall.

Do not mark these release checks complete based only on the tests above.
