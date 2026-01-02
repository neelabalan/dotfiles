# Go Coding Guidelines

### Environment & Tooling
- Default Go version: 1.21 or above
- Dependency management: Go modules
- Formatter: gofmt or goimports
- Linter: golangci-lint
- For new projects: Initialize with `go mod init`, run with `go run`, build with `go build`

### Code Style
- Formatting: Always use gofmt or goimports, follow standard Go formatting conventions
- Naming: Use camelCase for unexported names, PascalCase for exported names. Keep names concise and clear. Avoid stuttering (e.g., `http.HTTPServer` should be `http.Server`)
- Error handling: Always check errors explicitly, never ignore them. Return errors as the last return value. Use `errors.New()` or `fmt.Errorf()` for error creation
- Interfaces: Keep interfaces small and focused. Define interfaces where they are used, not where implementations exist. Prefer accepting interfaces and returning concrete types
- Pointers: Use pointers for large structs or when mutation is needed. For small structs or read-only operations, use values
- Functions: Keep functions small and focused. Avoid deep nesting (max 2-3 levels). Extract complex logic into helper functions
- Comments: Use package-level comments for all packages. Add comments for exported functions, types, and constants. Comments should be complete sentences starting with the name being documented
- Documentation: Avoid unnecessary comments for obvious code. Document non-obvious behavior, edge cases, and public APIs
- Concurrency: Use goroutines and channels appropriately. Avoid shared state when possible. Use `sync` package primitives when shared state is necessary
- Dependencies: Minimize external dependencies, prefer standard library
- Memory: Be mindful of allocations, reuse buffers when appropriate, use `sync.Pool` for frequently allocated objects

### Design Principles
- For libraries and services: Apply SOLID principles, focus on clear interfaces and separation of concerns
- For simple tools and scripts: Prioritize simplicity and readability over complex abstractions
- Composition over inheritance: Use struct embedding and interfaces for code reuse
- Accept interfaces, return structs: Functions should accept interface parameters and return concrete types
- Explicit is better than implicit: Make behavior clear, avoid hidden control flow
- Handle errors explicitly: Don't panic in library code, return errors to callers
- Zero values are useful: Design types so their zero value is useful and ready to use
- Keep the happy path left-aligned: Avoid deep nesting by handling errors early and returning
