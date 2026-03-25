# Swift Rules

## Optionals
- DO use `guard let` for early returns: `guard let user = user else { return }`
- DO use `if let` for conditional binding in limited scope
- DON'T force-unwrap with `!` — use `guard`, `if let`, or `??`
- DO use `map`/`flatMap` on optionals for functional transforms
- DO use `??` for defaults: `let name = user?.name ?? "Anonymous"`

## Guard Statements
- DO use `guard` at the top of functions for preconditions
- DO keep the happy path un-indented — `guard` handles the edge cases
- DON'T use `guard` for complex branching — use `if/else` or `switch`

## Protocol-Oriented Programming
- DO prefer protocols over class inheritance
- DO use protocol extensions for default implementations
- DO compose behavior with multiple protocol conformances
- DO use `some Protocol` (opaque types) for return types when possible
- DON'T make protocols overly broad — keep them focused (ISP)

## Value Types vs Reference Types
- DO use `struct` by default — use `class` only when identity or inheritance is needed
- DO use `enum` for finite state machines and associated values
- DON'T mutate structs from closures without `mutating` keyword
- DO use `let` over `var` — immutability by default

## Async / Await
- DO use `async`/`await` over completion handlers for new code
- DO use `Task { }` to bridge sync → async contexts
- DO use `async let` for concurrent independent work
- DO use `TaskGroup` for dynamic numbers of concurrent tasks
- DO handle cancellation with `Task.checkCancellation()` or `Task.isCancelled`

## Actors
- DO use `actor` for shared mutable state to prevent data races
- DO use `@MainActor` for UI-bound types and functions
- DON'T access actor-isolated state without `await`
- DO use `nonisolated` for actor methods that don't touch mutable state

## Codable
- DO use `Codable` for JSON/API models
- DO use `CodingKeys` enum to map JSON keys to Swift naming: `case userName = "user_name"`
- DO use `@propertyWrapper` or custom `init(from:)` for complex decoding
- DON'T make domain models `Codable` — use separate DTO types

## SwiftUI Patterns
- DO use `@State` for local view state, `@Binding` for parent-owned state
- DO use `@StateObject` for owned ObservableObject, `@ObservedObject` for injected
- DO use `@EnvironmentObject` for deep dependency injection
- DO extract subviews to keep `body` under ~30 lines
- DO use `ViewModifier` for reusable styling
- DON'T perform heavy computation in `body` — use `onChange` or `task`

## Memory Management (ARC)
- DO use `[weak self]` in closures that outlive the owner
- DO use `[unowned self]` only when you guarantee the owner outlives the closure
- DON'T create strong reference cycles between classes — use `weak` properties
- DO watch for retain cycles in delegates — declare delegate properties as `weak`

## Naming
- Types/protocols: `PascalCase`
- Functions/properties/variables: `camelCase`
- DON'T prefix protocols with `I` or types with `T`
- DO name booleans as questions: `isLoading`, `hasPermission`, `canSubmit`
- DO use descriptive parameter labels: `func move(from source: Int, to destination: Int)`

## General
- DO use `Result<Success, Failure>` for operations that can fail
- DO use `typealias` for complex generic types
- DO prefer `compactMap` over `map` + `filter` for optional unwrapping
- DO use `@discardableResult` when return values are intentionally ignorable
- DON'T use `NSObject` subclassing unless interfacing with Objective-C
