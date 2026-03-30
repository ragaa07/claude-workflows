# Kotlin Code Review Checklist

| Check | Severity | What to Look For |
|-------|----------|------------------|
| No force-unwrap (`!!`) | High | Every `!!` is a potential NPE. Require early-return null checks (`?: return`, `?.let { }`, safe calls). |
| Nullable types justified | Medium | Nullable params/returns should have a reason. Prefer non-null defaults. |
| Coroutine scope ownership | High | No `GlobalScope`. ViewModels use `viewModelScope`, lifecycle owners use `lifecycleScope`. |
| Dispatcher correctness | High | I/O on `Dispatchers.IO`, CPU on `Default`, UI on `Main`. No blocking on Main. |
| CancellationException propagation | High | `CancellationException` must not be swallowed in catch blocks. |
| Sealed class exhaustiveness | Medium | `when` on sealed types must not use `else` — compiler checks completeness. |
| Data class immutability | Medium | Data classes should use `val` properties. No `var` in data classes. |
| Extension function scope | Low | Extensions should not access internals of unrelated classes. Keep them focused. |
| Scope function nesting | Medium | No nested `let`/`run`/`apply` — flatten or extract to named functions. |
| Flow collection safety | High | Collect flows in lifecycle-aware scope (`repeatOnLifecycle`). No `collect` in `init`. |
| StateFlow vs SharedFlow | Medium | `StateFlow` for state (has current value). `SharedFlow` for events (no replay needed). |
| Hilt module correctness | Medium | `@Binds` for interfaces, `@Provides` for factories. Correct component scope. |
| ViewModel injection | Medium | `@HiltViewModel` + `@Inject constructor`. No manual ViewModel instantiation. |
| Collection mutability | Low | Use `listOf`/`mapOf` unless mutation is required. Don't expose `MutableList` in APIs. |
| Naming conventions | Low | `camelCase` functions, `PascalCase` classes, `SCREAMING_SNAKE` constants, `is/has` booleans. |
| Resource cleanup | High | Closeable resources wrapped in `use { }` or properly closed in `finally`. |
| Thread safety | High | Shared mutable state protected by `Mutex`, `Atomic*`, or confined to single coroutine. |
| Test coverage | Medium | Public functions tested. Edge cases (null, empty, error) covered. |
| Exception specificity | Medium | Catch specific exceptions, not `Exception` or `Throwable` broadly. |
