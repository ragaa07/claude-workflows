# React Code Review Checklist

| Check | Severity | What to Look For |
|-------|----------|------------------|
| No direct DOM manipulation | High | No `document.querySelector` or `innerHTML`. Use refs and React state for DOM interactions. |
| Hook rules | High | Hooks only called at top level of components/custom hooks. No hooks inside conditionals or loops. |
| useEffect dependencies | High | Dependency arrays are complete and correct. No missing deps causing stale closures. |
| useEffect cleanup | High | Effects that subscribe/listen return a cleanup function to prevent memory leaks. |
| Key prop on lists | High | Mapped elements have stable, unique `key` props. No array index as key when list can reorder. |
| Memoization correctness | Medium | `useMemo`/`useCallback` used for expensive computations or stable references, not prematurely on everything. |
| Component size | Medium | Components under ~200 lines. Extract sub-components or custom hooks when larger. |
| Prop types | High | All props have TypeScript interfaces. No `any` types. Optional props marked with `?`. |
| State colocation | Medium | State lives in the closest common ancestor. No unnecessary lifting or prop drilling beyond 2 levels. |
| Error boundaries | Medium | Async operations and third-party components wrapped in error boundaries with fallback UI. |
| Controlled components | Medium | Form inputs are controlled (value + onChange) or explicitly uncontrolled with refs. No mixed patterns. |
| Event handler naming | Low | Event handlers named `handleX` or `onX`. Callbacks passed as props use `onX` convention. |
| Conditional rendering | Low | Avoid `&&` with numbers/falsy values (use ternary or Boolean cast). No deeply nested ternaries. |
| Data fetching patterns | Medium | Data fetching uses React Query, SWR, or equivalent. No raw `useEffect` + `fetch` for API calls. |
| Re-render prevention | Medium | Components receiving callbacks use `useCallback`. Objects/arrays created in render are memoized. |
| Accessibility | Medium | Interactive elements use semantic HTML. ARIA attributes for custom widgets. Keyboard navigation works. |
| Test coverage | Medium | Components tested with React Testing Library. User interactions and async states covered. |
