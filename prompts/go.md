# Go Coding Guidelines

### Critical: error handling and naming
- Never ignore errors. Always check them.
- Wrap errors with `fmt.Errorf("...: %w", err)` for context.
- Use short receiver names, 1-3 letters (e.g. `f *File`, `s *Server`). Don't use `self` or `this`.
- Check every function before finishing: errors handled/wrapped, receiver names short.

### Environment and tooling
- Default Go version: 1.21 or above
- Dependency management: Go modules
- Formatter: gofmt or goimports
- Linter: golangci-lint
- New projects: `go mod init`, run with `go run`, build with `go build`

### Code style
- Always run gofmt or goimports, follow standard Go formatting.
- Use camelCase for unexported names, PascalCase for exported names. Keep names short and clear. Avoid stuttering (e.g. `http.Server`, not `http.HTTPServer`).
- Return errors as the last return value. Create them with `errors.New()` or `fmt.Errorf()`.
- Keep interfaces small and focused. Define them where they're used, not next to the implementation. Accept interfaces, return concrete types.
- Use pointers for large structs or when mutation is needed. Use values for small structs or read-only data.
- Keep functions small and focused. Avoid deep nesting (max 2-3 levels). Extract complex logic into helpers.
- Pass `context.Context` as the first argument to functions doing I/O, network calls, or long-running work.
- Add package-level comments for every package. Comment exported functions, types, and constants as full sentences starting with the name being documented.
- Skip comments on obvious code. Document non-obvious behavior, edge cases, and public APIs.
- Use goroutines and channels carefully. Avoid shared state where you can. Use `sync` primitives when shared state is unavoidable.
- Minimize external dependencies, prefer the standard library.
- Watch allocations, reuse buffers where it helps, use `sync.Pool` for objects allocated often.

### Design principles
- Libraries and services: apply SOLID, focus on clear interfaces and separation of concerns.
- Simple tools and scripts: favor simplicity and readability over abstraction.
- Prefer composition over inheritance: use struct embedding and interfaces for reuse.
- Accept interfaces, return structs.
- Make behavior explicit, avoid hidden control flow.
- Return errors to callers instead of panicking in library code.
- Design zero values to be useful and ready to use.
- Handle errors early and return, so the happy path stays left-aligned.
