# DECISIONS.md

## ADR-001 â€” Single instruction source
Decision: root `AGENTS.md`, `CORE.md`, `STATE.md` plus `Besmele/` are the only active instruction sources.
Reason: duplicated markdown structures confuse AI coding assistants.

## ADR-002 â€” Prayer-time data must be explicit
Decision: the app must clearly distinguish official Diyanet data, verified cached data, third-party data, and approximate calculated data.
Reason: user trust depends on prayer-time accuracy and source transparency.

## ADR-003 â€” Daily religious content requires approval state
Decision: app shows only approved ayah/hadith records. Draft content is never displayed in production.
Reason: religious content needs source discipline.

## ADR-004 â€” Qibla accuracy must be honest
Decision: qibla screen must separate location-based Kaaba bearing from sensor-only approximate mode.
Reason: phone compass accuracy depends on environment and calibration.

