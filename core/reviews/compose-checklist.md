# Jetpack Compose Code Review Checklist

| Check | Severity | What to Look For |
|-------|----------|------------------|
| Stateless composables | High | Composables should receive state as parameters and emit events up. No internal state for shared data. |
| State hoisting | High | State belongs in the ViewModel or nearest common ancestor. Composables should not own business state. |
| Recomposition safety | High | No side effects in composable body. Use `LaunchedEffect`, `SideEffect`, or `DisposableEffect`. |
| remember usage | High | Expensive computations wrapped in `remember`. Keys updated when dependencies change. |
| Stable parameters | Medium | Composable parameters should be stable/immutable to avoid unnecessary recompositions. Use `@Stable` or `@Immutable` when needed. |
| Modifier parameter | Medium | All composables accept a `modifier: Modifier = Modifier` parameter as the first optional param. |
| Modifier chaining order | Medium | `Modifier` chain order matters (e.g., `padding` before `background` vs after). Verify visual correctness. |
| Preview annotations | Low | Composables have `@Preview` with representative data. Multi-preview for dark/light themes. |
| Navigation safety | High | No direct context/activity references in composables. Use navigation callbacks or NavController. |
| List performance | High | `LazyColumn`/`LazyRow` items use `key` parameter. No `items(list.size)` without keys. |
| Theme usage | Medium | Colors, typography, and shapes come from `MaterialTheme`, not hardcoded values. |
| Accessibility | Medium | Content descriptions on icons/images. Touch targets meet minimum 48dp size. |
| ViewModel collection | High | Collect state with `collectAsStateWithLifecycle()`, not `collectAsState()`. |
| Slot pattern usage | Medium | Prefer slot APIs (content lambdas) over rigid layouts for reusable components. |
| Effect cleanup | High | `DisposableEffect` includes `onDispose` cleanup. `LaunchedEffect` keys trigger re-launch correctly. |
| String resources | Low | User-visible strings use `stringResource()`, not hardcoded strings. |
