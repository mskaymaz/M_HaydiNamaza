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
- Before starting and before finishing any code-file edit, silently check the line count of each touched code file. Do not report this check to the user unless a touched code file exceeds or would exceed 600 lines. If a touched code file would exceed 600 lines, split it into appropriate smaller files instead of leaving it above 600 lines.
- UI renders state and sends actions; business logic belongs to services/domain.
- When a requested UI size/spacing change is given as a ratio or percent, calculate the final value first and commit the nearest clear literal value. Do not leave request-derived size expressions such as `base * 1.30`, `value + value * 0.30`, or temporary percentage math in code.
- Do not hardcode app-specific text inside reusable shared modules.
- Never commit secrets, service-account files, local build folders, generated zip files, or private credentials.

## Output rules
- Be brief and factual.
- Always list changed files.
- Always list validation command results or say clearly that validation was not run.
- Update `STATE.md` and `Besmele/HANDOFF.md` only when the task changes project status.

## Validation preference (user workflow)
- For `flutter analyze` and similar validation commands, ask the user to run the command and share the terminal output.
- Prefer user-provided validation output in this repo unless the user explicitly asks the assistant to run validations directly.

## Device testing workflow (mandatory)
- Before the user performs the separate debug/test flow on the phone, first remind the user to run `flutter build apk --debug` from the repository root.
- Treat a successful `flutter build apk --debug` as the computer-side build checkpoint before phone testing.
- Do not install the generated APK to the phone as part of this workflow unless the user explicitly asks; phone testing uses the user's separate debug process.
- At the end of implementation work, always remind the user of the `flutter build apk --debug` command and ask them to share its result before proceeding to phone testing.

