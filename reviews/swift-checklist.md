# Swift Code Review Checklist

| Check | Severity | What to Look For |
|-------|----------|------------------|
| No force-unwrap (`!`) | High | Every `!` is a potential crash. Use `guard let`, `if let`, or `??` instead. |
| Guard for preconditions | Medium | Functions validate inputs with `guard` at the top, keeping happy path unindented. |
| Retain cycle prevention | High | Closures capturing `self` use `[weak self]` or `[unowned self]` appropriately. |
| Delegate weakness | High | Delegate properties declared as `weak var` to prevent retain cycles. |
| Value type preference | Medium | Use `struct` by default. `class` only when identity semantics or inheritance is needed. |
| Protocol conformance | Medium | Types conform to protocols via extensions for organization. Protocols are small and focused. |
| Actor isolation | High | Shared mutable state uses `actor`. No unprotected concurrent access to class properties. |
| MainActor for UI | High | UI-updating code marked `@MainActor`. No background thread UI updates. |
| Task cancellation | Medium | Long-running async tasks check `Task.isCancelled` or call `Task.checkCancellation()`. |
| Async/await adoption | Medium | New code uses `async/await` over completion handler callbacks. |
| Codable separation | Medium | API DTOs are separate from domain models. Domain models don't conform to `Codable`. |
| Exhaustive switch | Medium | `switch` on enums covers all cases. No default branch that hides future cases. |
| Optional chaining depth | Medium | Deep optional chains (`a?.b?.c?.d`) suggest a modeling problem. Simplify the hierarchy. |
| Memory leak detection | High | No strong reference cycles in closures, timers, notification observers, or KVO. |
| Access control | Medium | Properties and methods use appropriate access level (`private`, `internal`, `public`). |
| Error handling | High | Throwing functions use `do/catch` with specific error types, not generic `catch`. |
| SwiftUI body complexity | Medium | View `body` under 30 lines. Complex views split into extracted subviews. |
| State management | Medium | `@State` for local, `@StateObject` for owned, `@ObservedObject` for injected. |
| Naming conventions | Low | `camelCase` functions, `PascalCase` types, `is/has` booleans, descriptive param labels. |
