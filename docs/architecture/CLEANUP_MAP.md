# Instruction Cleanup Map

## Problem found
The uploaded instruction package contains many overlapping root markdown files, multiple task files, old workboards, session files, and Besmele/Bismillah-related structures. This creates a high risk that Codex/Copilot will read stale instructions and act on the wrong plan.

## Keep active
```text
AGENTS.md
CORE.md
STATE.md
Besmele/README.md
Besmele/TASKS.md
Besmele/HANDOFF.md
Besmele/WORKBOARD.md
Besmele/QUALITY_GATE.md
Besmele/DECISIONS.md
Besmele/HISTORY.md
docs/architecture/TARGET_ARCHITECTURE.md
docs/architecture/CLEANUP_MAP.md
```

## Archive, do not delete immediately
Archive these if they exist and only contain old instruction/task material:

```text
BesmeleGenel/
ContextKit/
Besmele/
core/
rules/
flows/
plans/
sessions/
oturumlar/
hooks/
optional/
tools/
WORKBOARD-1.md
Tasks.md
TASK-001.md ... TASK-043.md
old root planning markdown files
```

## Migration rule
If an old file contains unique product knowledge, migrate the knowledge into one of:
- `Besmele/TASKS.md`
- `Besmele/DECISIONS.md`
- `docs/architecture/TARGET_ARCHITECTURE.md`
- `docs/architecture/CURRENT_ARCHITECTURE.md`

Then archive the old file.

