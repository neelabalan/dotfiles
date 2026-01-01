# Python Coding Guidelines

## Environment & Tooling
- Default Python version: 3.11
- Package manager: uv
- Linter/Formatter: ruff

## Code Style
- Imports: Single-line imports without `from` keyword (e.g., `import os.path` instead of `from os import path`)
- Type hints: Always include type hints using lowercase built-ins (`list[str]`, `dict[str, int]`, `set[int]`) instead of typing module imports (`List`, `Dict`, `Set`)
- File operations: Prefer `pathlib.Path` over `os` module for file/path operations
- Command line arguments: Use `argparse` for CLI argument parsing
- Documentation: Avoid docstrings and comments unless absolutely necessary
- Data structures: Prefer `dataclass` with `frozen=True` for immutability
- Error handling: Use specific exception types, avoid bare `except` clauses
- Functions: Keep functions small and focused, prefer pure functions where possible
- Code structure: Write reusable code, extract common logic into functions, avoid deep nesting of loops (max 2-3 levels)
- Dependencies: Minimize external dependencies, prefer standard library
- Memory: Optimize for memory efficiency, avoid unnecessary allocations
- Naming: Use descriptive names, follow snake_case for functions/variables, PascalCase for classes

## Design Principles
- For applications and libraries: Apply SOLID principles strictly (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion)
- For simple scripts: SOLID principles can be relaxed, prioritize readability and simplicity
- Use composition over inheritance
- Favor immutability and stateless functions
- Keep side effects explicit and isolated
