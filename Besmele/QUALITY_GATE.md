# QUALITY_GATE.md

Before closing any task:

- [ ] Scope stayed limited.
- [ ] Changed files are listed.
- [ ] No unrelated refactor was mixed in.
- [ ] `flutter analyze` was run or skipped with reason.
- [ ] Relevant tests were run or skipped with reason.
- [ ] User-facing Turkish text was checked.
- [ ] No secret or local artifact was added.
- [ ] Before phone testing, user was reminded to run `flutter build apk --debug` successfully from the repository root.
- [ ] The debug APK was not installed to the phone unless explicitly requested; phone testing remains a separate user workflow.
- [ ] If architecture changed, `DECISIONS.md` was updated.
- [ ] If status changed, `STATE.md` and `HANDOFF.md` were updated.

