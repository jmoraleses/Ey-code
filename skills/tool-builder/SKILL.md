---
name: tool-builder
description: Create new tools (scripts, CLIs, Python functions) the user can reuse. Each tool ships with its invocation example and a smoke test.
when_to_use: |
  - User asks to "build a tool for X" or "write a script that does Y".
  - User asks to automate a recurring workflow.
license: MIT
---

# Tool Builder

## Contract

A tool you deliver must have:

1. **One clear purpose.** One verb, one object. If you need "and" in the description, split it into two tools.
2. **A runnable entry point.** E.g., `python scripts/<name>.py --help` must work.
3. **A smoke test.** A one-line bash command that proves the tool works end-to-end.
4. **Documentation.** A docstring at the top of the file describing inputs, outputs, and exit codes.

## Pipeline

1. **Clarify** — Determine inputs, outputs, failure modes, and where it should live.
2. **Scaffold** — `write_to_file` to create `tools/<name>.py` or `scripts/<name>.sh`.
3. **Implement** — Use the standard library first (e.g., `argparse` or `os`), add third-party dependencies only when strictly necessary.
4. **Test** — Use `run_command` to execute the smoke test. Fix errors iteratively.
5. **Finalize** — Present the tool to the user with examples of how to run it.

## Rules

- Stdlib > third-party. Add `requirements.txt` entries only when truly needed.
- Ensure scripts are executable (`chmod +x`).
- Exit non-zero on failure. Print errors to `stderr`.
- If the tool touches the filesystem destructively, require an explicit `--yes` or `--force` flag.
