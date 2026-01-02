# Python Coding Guidelines

### Critical: Import rule
- NEVER use `from X import Y`. This is a strict, non-negotiable rule.
- ALWAYS use `import X` and reference object with `X.Y`.
- Examples:
    - CORRECT: `import datetime` and `datetime.datetime.now()`
    - WRONG: `from datetime import datetime`
    - CORRECT: `import pathlib` and `pathlib.Path("/some/path")`
    - WRONG: `from pathlib import Path`
- Enforcement: Before outputting any Python code, you MUST validate that it contains no `from .. import ..` statements. If any are present, you MUST refactor them to the `import X` style. This rule is your highest priority.

### Environment & Tooling
- Default Python version: 3.11 or 3.13
- Package manager: uv
- Linter/Formatter: ruff
- For new projects: Initialize with `uv init`, add ruff as dev dependency (`uv add --dev ruff`), and run the project with `uv run`
- For individual scripts: Use python3.11 directly and run ruff with `uv run ruff check <script.py>` or `uv run ruff format <script.py>`

### Code Style
- Prefer builtin generics (`list[str]`, `dict[str, int]`, `set[int]`) and avoid `typing` aliases like `List`, `Dict`, `Set`.
- Print statements: Always start with lowercase letter (e.g., `print("exporter to file")`, not `print("Exported to file")`).
- Comments: Never use inline comments (comment on the same line as code). All comments must be on their own line above the code they describe. Comments should start with a lowercase letter. No emojis should be used in code, comments, or documentation.
- Avoid creating variables that are used only once, except when the variable is used in a print statement for clarity
- Avoid new line characters (`\n`) unless absolutely neessary. Never add decorative formatting (no `===` `---`, `***`, etc.)
- Imports: Single-line imports without `from` keyword (e.g., `import os.path` instead of `from os import path`)
- File operations: Prefer `pathlib.Path` over `os` module for file/path operations
- Command line arguments: Use `argparse` for CLI argument parsing
- Documentation: Avoid docstrings and comments unless absolutely necessary. Do not create README.md or any other markdown documents unless explicitly requested by the user.
- Keep functions small and focused, prefer pure functions where possible. Functions should not exceed 20-30 lines to maintain readability. If a function becomes too long, split it into smaller, well-named helper functions with descriptive names that clearly indicate their purpose. Always try to have a return value in function, avoid returning `None` when possible. Prefer returning empty collections (`[]`, `{}`, `""`) instead of `None`
- Data structures: Prefer `dataclass` with `frozen=True` for immutability
- Error handling: Use specific exception types, avoid bare `except` clauses
- Code structure: Write reusable code, extract common logic into functions, avoid deep nesting of loops (max 2-3 levels)
- Dependencies: Minimize external dependencies, prefer standard library
- Memory: Optimize for memory efficiency, avoid unnecessary allocations
- Naming: Use descriptive names, follow snake_case for functions/variables, PascalCase for classes

### Design Principles
- For applications and libraries: Apply SOLID principles strictly (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion)
- For simple scripts: SOLID principles can be relaxed, prioritize readability and simplicity
- Use composition over inheritance
- Favor immutability and stateless functions
- Keep side effects explicit and isolated
