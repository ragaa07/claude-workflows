# Go Rules

## Error Handling
- DO return errors as the last return value: `func Open(path string) (*File, error)`
- DO check errors immediately — never discard with `_`
- DON'T use `panic` for expected errors — only for programmer bugs
- DO wrap errors with context: `fmt.Errorf("open config: %w", err)`
- DO use `errors.Is()` and `errors.As()` for error inspection
- DO define sentinel errors: `var ErrNotFound = errors.New("not found")`
- DO use custom error types when callers need structured info

## Interfaces
- DO keep interfaces small — 1-2 methods is ideal
- DO define interfaces where they are consumed, not where they are implemented
- DON'T use interface pointers (`*MyInterface`) — interfaces are already references
- DO use `io.Reader`, `io.Writer`, `fmt.Stringer` as design models
- DO accept interfaces, return structs

## Goroutines & Channels
- DO always ensure goroutines can exit — no goroutine leaks
- DO use `sync.WaitGroup` or `errgroup.Group` to wait for goroutine completion
- DO prefer `select` with `ctx.Done()` for cancellation-aware goroutines
- DON'T launch goroutines without clear ownership of their lifecycle
- DO use buffered channels when producer/consumer rates differ
- DO close channels from the sender side only

## Context
- DO pass `context.Context` as the first parameter: `func Do(ctx context.Context, ...) error`
- DO propagate context through the call chain — never store it in a struct
- DO use `context.WithTimeout` / `context.WithCancel` for lifecycle control
- DON'T use `context.Background()` in library code — accept context from caller

## Testing
- DO use table-driven tests with `[]struct{ name string; ... }` slices
- DO use `t.Run(tc.name, ...)` for subtests
- DO use `t.Helper()` in test helper functions
- DO use `t.Parallel()` for independent tests

## Package Design
- DO keep packages focused — one concept per package
- DON'T use `util`, `common`, `helpers` packages — name by what it does
- DON'T use `internal/` unless you need to enforce visibility boundaries
- DO put `main` packages in `cmd/<name>/`

## Dependency Injection
- DO use constructor functions: `func NewService(repo Repo, log Logger) *Service`
- DON'T use DI frameworks — Go's simplicity makes manual DI clean
- DO use `Option` pattern for optional configuration: `func WithTimeout(d time.Duration) Option`

## Naming
- Receivers: short (1-2 letters): `func (s *Service) Do()`
- DON'T use getters — `user.Name()` not `user.GetName()`

## General
- DO use `defer` for cleanup — but beware of loop `defer` accumulation
- DO use `sync.Once` for one-time initialization
- DON'T use `init()` functions for application logic — they hurt testability. Exception: driver/plugin registration patterns that require `init()` by convention.
- DO use `make` for slices/maps with known capacity: `make([]int, 0, 100)`
- DO use struct embedding for composition, not inheritance
- DO run `go vet` and `golangci-lint` before committing
