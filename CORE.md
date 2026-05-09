# CORE.md

Purpose: keep M_HaydiNamaza maintainable, reliable, respectful, and easy for AI assistants to improve without drowning in duplicated instructions.

## Product direction
M_HaydiNamaza is a Flutter prayer-time application. It should become a clean, professional, offline-capable, user-trust-first mobile app.

## Core engineering principles
- Working app first, then refactor.
- No instruction sprawl.
- No giant UI files.
- No hidden or fragile prayer-time data dependency.
- No religious content without source metadata and approval state.
- No false accuracy claims for qibla direction.
- No manipulative monetization or intrusive ads.

## Target architecture
Use feature-based clean architecture gradually:

```text
lib/
  app/
  core/
  features/
    prayer_times/
    qibla/
    daily_content/
    shared_settings/
    location/
    notifications/
assets/
  data/
    daily_content/
    prayer_times/
docs/
  architecture/
Besmele/
```

## Priority refactors
1. Split oversized UI files.
2. Extract prayer-time logic from UI.
3. Build official prayer-time data strategy before release.
4. Add daily ayah/hadith panel architecture without publishing unapproved content.
5. Upgrade qibla engine with location-based bearing and sensor fallback.
6. Add shared settings modules based on reusable AllApp contracts.
7. Improve tests and release readiness.

## Active instruction source
- Root: `AGENTS.md`, `CORE.md`, `STATE.md`
- Work plan: `Besmele/TASKS.md`
- Current handoff: `Besmele/HANDOFF.md`
- Quality gate: `Besmele/QUALITY_GATE.md`

Do not create new competing instruction folders unless explicitly requested.

