# TypeScript Rules

## Type Safety
- DO enable `strict: true` in tsconfig — no exceptions
- DON'T use `any` — use `unknown` and narrow, or define a proper type
- DON'T use `@ts-ignore` — fix the type error or use `@ts-expect-error` with a comment
- DO use `as const` for literal types: `const STATUS = { OK: 200 } as const`

## Type Narrowing
- DO use discriminated unions with a `type` or `kind` field
- DO use `in` operator, `instanceof`, or type guards for narrowing
- DO write custom type guards: `function isUser(x: unknown): x is User`
- DON'T use type assertions (`as`) unless you've verified the shape at runtime

## Interfaces vs Types
- DO use `interface` for object shapes that may be extended
- DO use `type` for unions, intersections, mapped types, and utility types
- DON'T mix both for the same concept in a codebase — pick one convention

## Generics
- DO use generics for reusable utilities: `function first<T>(arr: T[]): T | undefined`
- DO constrain generics: `<T extends Record<string, unknown>>`
- DON'T over-abstract — if a generic is used once, a concrete type is clearer

## Async / Await
- DO always `await` promises — never leave them floating
- DO use `try/catch` around `await` calls, or `.catch()` at the call site
- DON'T use `.then()` chains when `async/await` is available
- DO type async return values: `async function fetchUser(): Promise<User>`
- DO use `Promise.all()` for independent concurrent operations

## Modules
- DO use ESM (`import`/`export`) — no `require()`
- DO use barrel exports (`index.ts`) sparingly — they can bloat bundles
- DO use path aliases (`@/utils`) over deep relative imports (`../../../utils`)
- DO use named exports over default exports for better refactoring

## Error Handling
- DO define custom error classes extending `Error`
- DO use `Result` pattern or discriminated unions for expected failures
- DON'T throw for expected cases (validation, not-found) — return typed errors

## React Hooks (when applicable)
- DO list all dependencies in `useEffect`/`useMemo`/`useCallback` deps arrays
- DON'T call hooks conditionally or inside loops
- DO extract complex logic into custom hooks
- DO use `useRef` for values that shouldn't trigger re-renders

## Naming
- Interfaces/types: `PascalCase` — no `I` prefix
- Functions/variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE` or `camelCase` (match project convention)
- Enums: `PascalCase` for name and members
- Files: `kebab-case.ts` or `PascalCase.tsx` for components

## General
- DO use `readonly` for properties that shouldn't change
- DO use `satisfies` operator for type-safe inference: `const cfg = {...} satisfies Config`
- DO prefer `Map`/`Set` over plain objects for dynamic key collections
- DON'T use `enum` — use `as const` objects or union types instead
- DO use `??` (nullish coalescing) over `||` for defaults
- DO use optional chaining `?.` instead of manual null checks
