# AGENTS.md

Repo: M_HaydiNamaza

This file is the only bootstrap file for AI coding assistants.

## Mandatory startup
1. Read `CORE.md`.
2. Read `STATE.md`.
3. Read `Besmele/TASKS.md` only for implementation planning.
4. Read only task-relevant source files before editing.

## Runtime commands
- `bismillah` or `eko`: strict scoped mode.
  - Required response: `Bismillah, baglam alindi, calismaya hazirim.`
  - Work only on the requested scope.
  - Use minimum files and minimum explanation.
  - Do not propose unrelated features.
- `fren`: stop immediately.

## Editing rules
- Do not rewrite the full app in one step.
- Preserve working behavior before improving it.
- Keep files preferably under 400 lines; 600 lines only if unavoidable.
- UI renders state and sends actions; business logic belongs to services/domain.
- Do not hardcode app-specific text inside reusable shared modules.
- Never commit secrets, service-account files, local build folders, generated zip files, or private credentials.

## Output rules
- Be brief and factual.
- Always list changed files.
- Always list validation command results or say clearly that validation was not run.
- Update `STATE.md` and `Besmele/HANDOFF.md` only when the task changes project status.

