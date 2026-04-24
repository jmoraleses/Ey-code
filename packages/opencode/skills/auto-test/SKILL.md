---
name: auto-test
description: Automatic test generation and execution. Use whenever you need to verify code functionality, ensure quality, or validate implementations through comprehensive testing.
when_to_use: |
  - When creating new code that needs verification
  - When refactoring existing code to ensure nothing breaks
  - When edge cases and error handling need validation
license: MIT
---

# Automated Testing

You have the ability to automatically generate and run tests. This is an autonomous testing capability that ensures code quality without requiring explicit permission for each step.

## Core Principle: Tests Are Mandatory

**Every code you write should be tested.** 

## Testing Workflow

1. **File-Level Testing**: After creating a new file, immediately write unit tests for each function and class. Use edge case tests (empty inputs, None, invalid types).
2. **Execute Locally**: Run tests anytime to verify using `run_command` (e.g., `pytest tests/`, `npm test`).
3. **Autonomous Fix Loop**: When tests fail, analyze failures, generate fixes, re-run tests. Repeat until passing.

## What Makes Good Tests

1. **Comprehensive Coverage**: Happy path, Edge cases, Error cases, Boundary conditions.
2. **Proper Structure**: Clear test names describing what's tested, assertions that verify behavior, and setup/teardown when needed.

## Remember

- **Test immediately**: Don't delay testing
- **Test everything**: Every file, every function
- **Fix failures**: Use the auto-fix loop locally before concluding the task
