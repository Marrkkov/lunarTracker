# Release packaging

The reproducible automated artifact is a **manual-install ZIP**, not a renamed
ZIP pretending to be `.rmskin`. Rainmeter's official package format includes
metadata/integrity information; use its Skin Packager for a genuine `.rmskin`.

## Prepare the release ZIP

1. Review LICENSE/NOTICE, update the version in package.json and Lunar.ini together,
   and verify notifications remain disabled in the source settings.
2. Run `npm ci --ignore-scripts`, `npm test`, `npm run assets`, and check that
   rendering did not change committed PNGs unexpectedly.
3. Run `npm run package`. Inspect `dist/Lunar-0.1.2.zip`, `manifest.json` and
   `SHA256SUMS.txt`. The builder reads an explicit list: one INI, one include,
   four Lua modules, 120 PNGs and seven offline documentation files. It never
   copies your installed preferences/history or the development test profile.
4. Open the ZIP with Windows Explorer or an archive viewer. It must contain
   only `Lunar/...`, with no executables, DLLs, plugins, layouts, startup items,
   private settings or scripts other than the four production Lua files.
5. Test a clean install as a standard user and complete the manual checklist.
   Publish the reviewed ZIP and checksum/manifest as release attachments.

SHA-256 detects a changed download only when the expected checksum comes from a
trusted source; it does not authenticate the publisher by itself.

The GitHub Actions workflow runs checks and produces an artifact on pushes/PRs
or manual dispatch. It has read-only repository permissions and **does not
publish releases, push code or create update mechanisms**. Review downloaded CI
artifacts before manually attaching them to a public release.

## Build a genuine `.rmskin`

1. Extract the reviewed release ZIP into a clean staging directory. Use this
   `Lunar` directory, not an installed copy containing local state.
2. Open Rainmeter → Manage → **Create .rmskin package…**.
3. Set Name `Lunar`, author to the actual publisher, and the matching version.
   Add only the staged `Lunar` root skin folder. Add no plugins or layouts.
4. On the options page, choose minimum Rainmeter 4.5.20 and Windows 11 if
   available (otherwise document Windows 11 in the description). Leave automatic
   skin loading and unrelated actions off. Preserve `@Resources\Settings.inc`
   as a variable file on upgrade if offered. The journal is not distributed;
   back it up and retain it when upgrading manually.
5. Save as `Lunar-VERSION.rmskin`. Open it with an archive viewer to inspect
   `RMSKIN.ini` and skin contents. Confirm no plugins/layouts/install actions or
   optional background components were introduced. Check the preserved variable
   file setting and that default notifications are off for a new installation.
6. Install on a clean standard-user profile, verify install/uninstall and
   preference/history preservation, then calculate and publish its SHA-256 too.

No `.rmskin` has been built or installation-tested in the initial implementation.
The ZIP is usable through Rainmeter's normal manual skin installation workflow.
Do not label the ZIP as an installer or claim `.rmskin` validation before this
GUI checklist is completed.

Official reference: https://docs.rainmeter.net/manual/distributing-skins/
