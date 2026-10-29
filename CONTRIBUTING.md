# Contributing

Keep the runtime self-contained: Rainmeter 4.5-compatible INI and Lua 5.1, local
assets, no network or helper processes. Explain changes to time scales,
notification persistence, hemisphere semantics or data provenance in your PR.

Use Node 22+ for development:

```text
npm ci --ignore-scripts
npm test
npm run assets
npm run package
```

Commit package-lock.json. Do not introduce install lifecycle scripts, application
tokens, local settings/history, generated dist files or desktop/profile paths.
Re-rendered source assets are committed, so a clean render should produce no
diff. NASA source replacement requires provenance, a checksum and notice review.
Bundled data fixtures must be real downloaded reference data, never expected
values copied from our own calculator.

For astronomy changes, add a regression tied to an independent authoritative
timestamp; keep the two-minute threshold unless new evidence justifies a change.
Do not label approximate illumination or a hemisphere rotation as exact physical
orientation. Test month/year/leap boundaries and UTC/local transitions.

For notifications, test disabled operation, failed persistence, restart history,
catch-up expiration and event boundaries. Do not add background scheduling or
Windows integration that executes external commands.

Run the native Windows checklist in docs/validation.md for changes affecting
Rainmeter. Document anything you could not verify. A passing Fengari run alone
does not prove native Lua/Rainmeter compatibility. Screenshots must be actual
captures or explicitly labeled design/asset previews.

PR descriptions should state the behavior changed and list meaningful checks
and limitations. Contributions are provided under the repository's MIT license;
retain all third-party notices. See SECURITY.md for vulnerability reporting.
