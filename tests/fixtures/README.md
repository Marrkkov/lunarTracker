# Reference data provenance

Raw US Naval Observatory API responses were downloaded on 2026-10-29 over HTTPS.
They are independent of Lunar's implementation and committed so routine testing
has no network dependency. Do not regenerate fixtures from Lunar's own results.

`usno-YEAR.json` for 2000, 2024, 2026, 2030, 2049 and 2050 comes from:

```text
https://aa.usno.navy.mil/api/moon/phases/year?year=YEAR
```

These files contain 298 primary phases (all four kinds), rounded to minutes in
Universal Time. At this precision UT1 is treated as UTC. Event comparison permits
120 seconds including minute rounding and modeled ΔT error. USNO calculations
are an independent check, rather than NASA's table generated from related Meeus
equations. The largest event difference observed is documented in validation.md.

`illumination-DATE.json` for 2026-10-29, 2026-11-10, 2026-11-20 and 2024-02-29:

```text
https://aa.usno.navy.mil/api/rstt/oneday?date=DATE&coords=0,0&tz=0
```

USNO's daily fraction is for **local noon**; tz=0 therefore means 12:00 UTC.
Fractions are whole percentages. Tests compare the truncated phase-angle model
within two percentage points. These four dates are sparse intermediate-phase
coverage, not exhaustive validation of illumination accuracy.

Sources: [API documentation](https://aa.usno.navy.mil/data/api.html),
[event data and definitions](https://aa.usno.navy.mil/data/MoonPhases),
[daily data notes](https://aa.usno.navy.mil/data/RS_OneDay).
