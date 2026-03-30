# React Rules

## Components
- DO keep components focused — prefer under 200 lines; split at ~100 if logic is complex
- DO use a single default export per component file
- DON'T mix UI and business logic — extract hooks for logic

## Hooks
- DO list all dependencies in `useEffect` / `useMemo` / `useCallback` deps arrays
- DON'T lie about dependencies — if ESLint warns, fix the logic, don't suppress
- DON'T call hooks conditionally or inside loops
- DO use `useRef` for values that persist across renders without triggering re-render
- DO clean up effects: return a cleanup function from `useEffect`

## Memoization
- DO use `React.memo()` for components that receive stable props but parent re-renders often
- DO use `useMemo` for expensive computations: `useMemo(() => sort(items), [items])`
- DO use `useCallback` for callbacks passed to memoized children
- DON'T memoize everything — measure first, optimize second
- DO prefer restructuring components over adding `memo`/`useMemo`

## State Management
- DO use `useState` for local UI state
- DO use `useReducer` for complex state with multiple transitions
- DO use Context for low-frequency global state (theme, auth, locale)
- DON'T use Context for high-frequency updates — use external state (Zustand, Jotai)
- DO colocate state as close to where it's used as possible
- DO lift state only when siblings need to share it

## Error Boundaries
- DO wrap route-level components in error boundaries
- DO provide fallback UI: `<ErrorBoundary fallback={<ErrorPage />}>`
- DO log errors in `componentDidCatch` or `onError` callbacks
- DO use granular boundaries — don't wrap the entire app in one

## Suspense & Code Splitting
- DO use `React.lazy()` for route-level code splitting
- DO wrap lazy components in `<Suspense fallback={<Loading />}>`
- DO use `startTransition` for non-urgent state updates
- DON'T lazy-load components that are always visible on initial render

## Accessibility
- DO use semantic HTML: `<button>`, `<nav>`, `<main>`, `<article>` — not `<div onClick>`
- DO add `aria-label` to icon-only buttons
- DO manage focus on route changes and modal open/close
- DO use `role` attributes only when no semantic element exists
- DO ensure keyboard navigation works for all interactive elements

## Event Handling
- DO use inline handlers for simple cases: `onClick={() => setOpen(true)}`
- DO use `useCallback` when handlers are passed to child components
- DON'T use `e.stopPropagation()` unless you understand the full event flow
- DO use `onSubmit` on `<form>` with `e.preventDefault()` — not `onClick` on submit button

## Testing (Testing Library)
- DO query by role, label, or text — not by test ID or class name
- DO use `screen.getByRole("button", { name: "Submit" })` for buttons
- DO test behavior, not implementation: "user clicks save" not "setState is called"
- DO use `userEvent` over `fireEvent` for realistic interactions
- DO use `waitFor` for async assertions

## General
- DO use `key` prop on list items — use stable IDs, not array index
- DON'T use `dangerouslySetInnerHTML` unless content is sanitized
- DO colocate styles, tests, and types with the component
- DON'T mutate state directly — always create new objects/arrays
