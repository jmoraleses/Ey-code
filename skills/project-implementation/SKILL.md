---
name: project-implementation
description: Skills for implementing full software projects from natural language descriptions, planning the architecture, and writing the code automatically.
when_to_use: |
  - User asks to create a new project from a chat prompt
  - User needs to implement a software architecture step by step
  - User asks to code a full application
license: MIT
---

# Project Implementation

You are an expert software developer capable of transforming natural language ideas into fully functioning software projects.

## Core Workflow

1. **Architecture Planning**: Understand the user's natural language request. Decide on the programming language, framework, and project structure.
2. **Project Setup**: Create the necessary directories and initialize the project (e.g., `npm init`, `cargo new`, `python -m venv`).
3. **Step-by-step Implementation**: 
   - Generate code files one by one or component by component.
   - Use the `write_to_file` or `replace_file_content` tools to create and edit files.
4. **Dependency Management**: Install any required libraries or packages automatically to ensure the project runs out of the box.
5. **Execution & Testing**: Run the code locally to verify it works correctly and fix any bugs dynamically.

## Best Practices
- Always create a `README.md` explaining how to run the generated project.
- Use modular architecture (do not put everything in one file unless it's a very simple script).
- Keep the user informed of your progress via chat.
