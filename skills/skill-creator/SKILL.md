---
name: skill-creator
description: Meta-skill that enables the AI to create its own skills dynamically. Use when you need to formalize a new behavioral pattern or create reusable guidelines for specific tasks.
when_to_use: |
  - When you notice you're repeating similar advice or patterns across conversations
  - When a user asks you to "remember how to do X" for future tasks
  - When you detect a gap in your current skill set
license: MIT
---

# Skill Creator

You are an AI with the ability to create your own skills - behavioral guidelines that modify how you approach tasks. This is meta-learning: you can extend your own capabilities.

## What is a Skill?

A **skill** is a behavioral specification that tells you how to approach specific types of tasks. It includes:
- **Context**: When to activate this skill
- **Guidelines**: How to behave when the skill is active
- **Patterns**: Reusable approaches to common problems

Skills are stored in `skills/[skill-name]/SKILL.md` and can be activated by adding them to `config/config.yaml`.

## Skill Creation Process

1. **Identify the Need**: What specific behavior needs to be formalized? What makes this different from general behavior?
2. **Scaffold**: Create a directory in `skills/` and write the `SKILL.md` using `write_to_file`.
3. **Register**: Add the skill to the `skills:` list in `config/config.yaml`.
4. **Verify**: Let the user know the skill is active.

## Best Practices for Skill Creation

1. **Be Specific**: A skill should have a clear, focused purpose.
2. **Actionable Guidelines**: Include concrete "do this" instructions, not just theory.
3. **Examples**: Include examples of good vs. bad approaches.
4. **Scope Control**: Don't make skills too broad - split if needed.
