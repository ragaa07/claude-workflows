# TypeScript Code Review Checklist

| Check | Severity | What to Look For |
|-------|----------|------------------|
| No `any` usage | High | Every `any` weakens type safety. Use `unknown` with narrowing or define proper types. |
| No `@ts-ignore` | High | Use `@ts-expect-error` with explanation, or fix the underlying type issue. |
| Strict mode enabled | High | `tsconfig.json` must have `strict: true`. No `strictNullChecks: false`. |
| Proper null handling | High | Use optional chaining (`?.`), nullish coalescing (`??`), and type guards. |
| Async error handling | High | Every `await` should be in a try/catch or the promise chain must have `.catch()`. |
| No floating promises | High | Every promise must be awaited, returned, or explicitly voided with `void promise`. |
| Discriminated unions | Medium | State types should use discriminated unions, not optional fields for variants. |
| No type assertions | Medium | Avoid `as` casts. Use type guards or restructure code to let TS infer types. |
| React hook deps | High | `useEffect`/`useMemo`/`useCallback` deps arrays must be complete and correct. |
| No hooks in conditions | High | Hooks must be called at the top level — never inside `if`, loops, or callbacks. |
| Effect cleanup | High | `useEffect` with subscriptions/timers must return a cleanup function. |
| Component size | Medium | Components over 100 lines should be split. Separate logic into custom hooks. |
| Bundle size impact | Medium | Check for large imports. Use tree-shakeable imports: `import { x } from 'lib'`. |
| Accessibility | Medium | Interactive elements use semantic HTML. Icon buttons have `aria-label`. |
| Key prop in lists | High | List items use stable `key` (ID, not index) to prevent rendering bugs. |
| Error boundaries | Medium | Route-level components wrapped in error boundaries with fallback UI. |
| No default exports | Low | Prefer named exports for better IDE support and refactoring. |
| Readonly usage | Low | Properties that shouldn't change marked `readonly`. |
| Enum alternatives | Low | Prefer `as const` objects or union types over `enum`. |
| Test coverage | Medium | Components tested with Testing Library. Queries by role/label, not test ID. |
