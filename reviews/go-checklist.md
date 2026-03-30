# Go Code Review Checklist

| Check | Severity | What to Look For |
|-------|----------|------------------|
| Errors not discarded | High | Every returned `error` is checked. No `_ = SomeFunc()` ignoring errors. |
| Error wrapping | Medium | Errors wrapped with context: `fmt.Errorf("fetch user %d: %w", id, err)`. |
| No `panic` in libraries | High | `panic` only for unrecoverable programmer bugs. Libraries return errors. |
| Goroutine lifecycle | High | Every goroutine has a clear exit path. No fire-and-forget goroutines. |
| Goroutine leak check | High | Goroutines listen on `ctx.Done()` or a quit channel to stop when no longer needed. |
| Context propagation | High | `context.Context` passed as first param. Not stored in structs. |
| Context.Background usage | Medium | `context.Background()` only in `main()` or top-level. Libraries accept context from callers. |
| Channel ownership | Medium | Channels closed by sender only. Receiver never closes. |
| Race condition safety | High | Shared mutable state protected by `sync.Mutex` or confined to a single goroutine. |
| Interface size | Medium | Interfaces have 1-3 methods max. Large interfaces should be split. |
| Interface location | Medium | Interfaces defined at consumer side, not alongside implementation. |
| No `init()` functions | Medium | Avoid `init()` — use explicit initialization for testability and clarity. |
| Defer correctness | Medium | `defer` in loops may accumulate — ensure deferred calls behave as intended. |
| Error types | Medium | Custom errors implement `error` interface. Use `errors.Is`/`errors.As` for checks. |
| Package naming | Low | Packages are lowercase, single-word. No `util`, `common`, `helpers`. |
| Constructor pattern | Low | Use `NewXxx()` constructors. Return concrete types, accept interfaces. |
| Table-driven tests | Medium | Test cases use `[]struct{name string; ...}` with `t.Run` subtests. |
| Test parallelism | Low | Independent tests call `t.Parallel()` for faster execution. |
| Slice/map capacity | Low | `make([]T, 0, expectedCap)` when size is known to avoid reallocations. |
| Linter compliance | Medium | Code passes `go vet`, `golangci-lint`. No suppressed warnings without justification. |
