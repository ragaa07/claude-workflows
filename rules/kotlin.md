# Kotlin Rules

## Null Safety
- DO use `?.let { }` for nullable transformations, not `if (x != null)`
- DO use `?:` (Elvis) for defaults: `val name = input ?: "default"`
- DON'T use `!!` — if you think you need it, redesign the flow
- DO use `requireNotNull()` or `checkNotNull()` when a null signals a bug

## Coroutines
- DO use `suspend` functions for one-shot async work
- DO use `Flow` for observable streams of values
- DON'T use `GlobalScope` — inject `CoroutineScope` or use `viewModelScope`/`lifecycleScope`
- DO use `withContext(Dispatchers.IO)` for blocking I/O inside suspend functions
- DON'T catch `CancellationException` — let it propagate
- DO use `supervisorScope` when child failure should not cancel siblings
- DO prefer `Flow.catch { }` over try/catch around `collect`
- DO use `flatMapLatest` when only the latest emission matters

## Sealed Classes & Data Classes
- DO use `sealed class` for state machines and restricted hierarchies
- DO use `when` exhaustively — never add an `else` branch on sealed types
- DON'T put mutable properties (`var`) in data classes

## Extension Functions
- DO use extensions to add behavior without subclassing
- DON'T use extensions to access private members of the receiver — that's a smell
- DO keep extensions close to their usage (same file or module)

## Scope Functions
- `let` — transform nullable or chain results: `x?.let { use(it) }`
- `run` — execute a block on an object and return the result
- `with` — configure an object without needing `it`/`this` repeatedly
- `apply` — configure and return the same object (builder pattern)
- `also` — side effects (logging, validation) without altering the chain
- DON'T nest scope functions — one level max

## Flow vs Channel
- DO use `Flow` for cold, declarative streams
- DO use `Channel` for hot, event-driven communication (e.g., one-shot UI events)
- DO use `SharedFlow` / `StateFlow` for shared hot streams
- DON'T use `Channel` where `SharedFlow(replay=0)` suffices

## Hilt / DI
- DO annotate ViewModels with `@HiltViewModel` and use `@Inject constructor`
- DO use `@Binds` for interface-to-implementation bindings
- DO use `@Provides` only when you can't use `@Binds` or need factory logic
- DO use `@AssistedInject` + `@AssistedFactory` when runtime params are needed at construction

## General
- DO use `value class` for type-safe wrappers: `value class UserId(val id: String)`
- DON'T use raw `Thread` — use coroutines
- DO use `buildList`, `buildMap` for constructing collections conditionally
- DO use `Result` or sealed types for error handling instead of exceptions for expected failures
