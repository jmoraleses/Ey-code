---
name: coding-agent
description: Programming workflow for the runtime — read before edit, surgical changes, test-driven fixes, and efficient use of existing tools.
when_to_use: |
  - User asks to write, edit, refactor, debug, or test code.
  - User asks to review a file or diff.
license: MIT
---

# Coding Agent

## Pipeline for any code task

1. **Locate** — Use `list_dir`, `grep_search` to find relevant files.
2. **Read** — Use `read_file` before any edit. Never edit blind or assume line numbers.
3. **Plan** — Think about the architecture before writing code.
4. **Edit** — Use `replace_file_content` or `multi_replace_file_content`. Change only the lines the task requires. Do not rewrite entire files unless completely necessary.
5. **Verify** — `run_command` to execute tests, linters, or syntax checks (`python -m py_compile ...`).
6. **Report** — Cite `file:line` and briefly summarize what changed.

## Rules

- **Zero Hallucination Tolerance:** Never invent variables, functions, or imports. If you don't know the exact name, use `grep_search`.
- No speculative features, no extra abstractions, no defensive code for impossible paths.
- Match the existing style of the file being edited (indentation, naming conventions).
- When fixing a bug: first reproduce it with a command or test, then fix, then re-run to confirm.
- When unsure of API signatures: search the repo before guessing.

## Preferred tools

- **Read/Search**: `view_file`, `list_dir`, `grep_search`.
- **Edit**: `replace_file_content`, `multi_replace_file_content`, `write_to_file`.
- **Verify**: `run_command` (for tests or syntax checks).
- **Git Operations**: Use `run_command` to stage and commit when asked.
