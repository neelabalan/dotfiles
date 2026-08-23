# Python Coding Guidelines

### Critical: import rule
- Never use `from X import Y`.
- Always use `import X`, then call `X.Y`.
- Examples:
    - correct: `import datetime` then `datetime.datetime.now()`
    - wrong: `from datetime import datetime`
    - correct: `import pathlib` then `pathlib.Path("/some/path")`
    - wrong: `from pathlib import Path`
- Check every script for `from .. import ..` before finishing. Fix any you find. This is the top priority rule.
- Add type hints to all function parameters and return types. Use built-in generics (e.g. `list[str]`).

### Environment and tooling
- Default Python version: 3.11 or 3.13
- Package manager: uv
- Linter/formatter: ruff
- New projects: `uv init`, add ruff as a dev dependency (`uv add --dev ruff`), run with `uv run`
- Single scripts: use python3.11 directly, lint with `uv run ruff check <script.py>` or format with `uv run ruff format <script.py>`

### Code style
- Use built-in generics (`list[str]`, `dict[str, int]`, `set[int]`). Don't use `typing` aliases like `List`, `Dict`, `Set`.
- Print statements start with a lowercase letter (e.g. `print("exporter to file")`, not `print("Exported to file")`).
- Error messages in `print`, `sys.exit`, or exceptions start with a lowercase letter.
- No inline comments (comment on the same line as code). Put comments on their own line, above the code. Comments start lowercase. No emojis in code, comments, or docs.
- Don't create a variable that's used only once, unless it's used in a print statement for clarity.
- Avoid unnecessary `\n`. No decorative formatting (`===`, `---`, `***`, etc.).
- Use f-strings for string interpolation. Don't use `.format()` or `%`.
- Write imports as single lines without `from` (e.g. `import os.path`, not `from os import path`).
- Use `pathlib.Path` for all file and path operations. Don't use `os.path` or `os.makedirs`.
- Use `argparse` for CLI argument parsing.
- Skip docstrings and comments unless they're really needed. Don't create README.md or other markdown files unless the user asks for them.
- Use `if __name__ == "__main__":` for scripts meant to run directly.
- Keep functions small and focused, ideally under 20-30 lines. Split long functions into smaller, well-named helpers. Prefer functions that return a value over ones that return `None` - return an empty collection (`[]`, `{}`, `""`) instead where possible.
- Prefer `dataclass` with `frozen=True` for immutable data.
- Catch specific exception types, not bare `except`.
- Extract repeated logic into functions. Keep loop nesting to 2-3 levels max.
- Minimize external dependencies, prefer the standard library.
- Avoid unnecessary allocations.
- Use descriptive names: snake_case for functions/variables, PascalCase for classes.

### Design principles
- Apps and libraries: follow SOLID principles (single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion).
- Simple scripts: relax SOLID, favor readability and simplicity.
- Prefer composition over inheritance.
- Favor immutable data and stateless functions.
- Keep side effects explicit and isolated.
