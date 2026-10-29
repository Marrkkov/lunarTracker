# Security policy and review

Lunar 0.1.x is a local Rainmeter skin. No network connection or extra executable
is needed. Review this source and the package manifest before installation.
This is a source review and functional test report, not a third-party security
audit or proof that Rainmeter itself is free of vulnerabilities.

## Runtime inventory

| Component | Capabilities used |
| --- | --- |
| Lunar.ini | Script, Image, String, Shape meters; fixed dismiss/date navigation callbacks |
| Settings.inc | Local preferences; no credential or location lookup |
| Astronomy.lua | Math and tables only |
| Format.lua | Math/string operations and OS local date conversion |
| Alerts.lua | Reads/appends the fixed numeric reminder journal |
| Widget.lua | Reads local settings; loads fixed bundled modules; sets meter options; diagnostic logs |
| PNGs | Local raster images generated from credited NASA surface data |

Runtime does not use PowerShell, CMD, batch files, processes, remote scripts,
`os.execute`, `io.popen`, `loadstring`, arbitrary `load`, plugins, HTTP,
registry APIs, telemetry, admin rights, startup entries, services or tasks.
Bundled modules are loaded with `dofile` at fixed paths; this is auditable module
loading, not execution of state or downloaded code. The standard Rainmeter
`!CommandMeasure` mouse actions invoke only literal `Dismiss()`, `PreviousDay()`,
`NextDay()` and `Today()` callbacks. Preview dates are stored only in memory and
never change the OS clock or notification decision timestamps.
Date format, language, booleans and numeric settings are constrained before use.

Only NotificationState.dat is written by the production Lua, and only after
explicit reminder opt-in. The path is derived from Rainmeter's own resource
directory, not user-provided text. It contains event/reminder identifiers, no
personal information. An unwritable journal fails closed. The skin neither
creates its parent directory nor executes its contents. Preferences are edited
by the user; widget positioning is managed by Rainmeter itself.

Rainmeter skins are programs running as the current user, not a security sandbox.
Keep Rainmeter and Windows updated, avoid running Rainmeter elevated, and protect
the installation folder. A party able to replace bundled Lua or INI files could
change behavior. Local file integrity and single-process journal access are
assumptions. OS write caching means duplicate suppression cannot be guaranteed
after arbitrary storage failure, and deleting history intentionally resets it.

## Development-only tools and connections

No development tool is included in the installed skin. The release builder uses
an explicit allowlist and refuses symlink inputs; it omits state, fixtures,
node_modules, binaries, profiles and workstation paths.

| Tool | Purpose and side effects |
| --- | --- |
| tests/run.cjs, tests/spec.lua, tests/widget-spec.lua, tests/assets.cjs | Run actual Lua/math/policy/navigation with locked Fengari and check PNG geometry; offline |
| tools/render.cjs | Decode the checked-in JPEG and write local PNGs/contact sheet; offline |
| tools/package.cjs | Write deterministic ZIP and SHA-256 manifest into dist; no shell |
| tools/native-smoke.cjs, tests/native-probe.lua | Stage an isolated profile in tests/.native; optional native tests write a workspace report/test journal |
| tools/CaptureWindow.cs | Optional development helper: capture only a selected Rainmeter process's skin window or send it documented Rainmeter commands; no runtime role |
| .github/workflows/check.yml | Read-only CI: locked development install, test, render reproducibility check, package/artifact upload; no deployment |

Initial research/fixture acquisition used these HTTPS endpoints. Tests use saved
responses and never re-fetch them automatically:

- `https://docs.rainmeter.net/` — official capability/packaging reference.
- `https://www.rainmeter.net/` and `https://github.com/rainmeter/rainmeter/`
  (including `raw.githubusercontent.com/rainmeter/rainmeter/...`) — release/API reference.
- `https://raw.githubusercontent.com/soniakeys/meeus/...` — MIT mathematical implementation reference; no downloaded code is executed.
- `https://eclipse.gsfc.nasa.gov/phase/phases2001.html` and
  `https://eclipse.gsfc.nasa.gov/SEhelp/deltatpoly2004.html` — time-scale/math references.
- `https://svs.gsfc.nasa.gov/4720/` and
  `https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/lroc_color_poles_1k.jpg`
  — original texture and attribution.
- `https://www.nasa.gov/nasa-brand-center/images-and-media/` — media policy.
- `https://aa.usno.navy.mil/api/moon/phases/year?year=...` — six independent yearly event test tables.
- `https://aa.usno.navy.mil/api/rstt/oneday?date=...&coords=0,0&tz=0` — four
  noon illumination references. Coordinates are a synthetic reference, not the user's location.
- `https://registry.npmjs.org/` — development-only locked npm dependencies;
  installs use `--ignore-scripts`. npm's normal audit may contact its registry.
- GitHub Actions endpoints — repository checkout, pinned actions and artifact storage during CI.

The development shell used to stage and inspect Windows tests is not part of
the skin. No shell helper is required for users. Rainmeter's own update/network
behavior is controlled by Rainmeter; it is outside this skin's implementation.

## Reporting

Use the repository's GitHub Security → Report a vulnerability feature if the
maintainer has enabled private vulnerability reporting. If unavailable, open a
minimal issue asking for a private contact without publishing exploit details
or private machine information. There is no invented support email or guaranteed
response window. Maintainers should enable private reporting before publication.
