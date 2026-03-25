# Jetpack Compose Rules

## Recomposition Stability
- DO mark classes used as parameters with `@Stable` or `@Immutable`
- DON'T pass unstable types (e.g., `List`, `Map`) directly — wrap in `@Immutable` holders or use `kotlinx.collections.immutable`
- DO use `ImmutableList` / `PersistentList` from kotlinx-collections for stable list params
- DON'T create new object instances in composable calls: `Color(0xFF000000)` → extract to a val

## Remember & DerivedStateOf
- DO use `remember { }` for expensive computations that survive recomposition
- DO use `remember(key) { }` when the result depends on a key
- DO use `derivedStateOf { }` for values derived from frequently changing state: `val isValid by remember { derivedStateOf { name.isNotBlank() } }`
- DON'T use `derivedStateOf` for simple reads — only when filtering rapid changes

## Side Effects
- DO use `LaunchedEffect(key)` for suspend work tied to composition lifecycle
- DO use `DisposableEffect(key)` when cleanup is needed (listeners, callbacks)
- DO use `SideEffect` for non-suspend work that must run after every recomposition
- DO use `rememberCoroutineScope()` for event-driven coroutines (button clicks)
- DON'T launch coroutines directly in composable body — use `LaunchedEffect` or `rememberCoroutineScope`
- DO use `rememberUpdatedState(value)` inside long-running effects to read the latest value

## State Hoisting
- DO hoist state to the nearest common ancestor that needs it
- DO follow the pattern: `value: T, onValueChange: (T) -> Unit`
- DO create state holder classes for complex state: `class FormState(val name: MutableState<String>, ...)`
- DON'T read ViewModel state deep in the tree — pass values down as parameters

## Annotations
- DO use `@Immutable` for classes whose public properties never change after construction
- DO use `@Stable` for classes where changes are observable by Compose (e.g., `MutableState`)
- DO add `@Composable` only to functions that call other composables or use composition locals

## LazyColumn / LazyRow
- DO always provide `key` in `items(key = { it.id })` for stable identity
- DON'T use `items(list.size) { index -> }` — use `items(list, key = ...) { item -> }`
- DO use `contentType` for heterogeneous lists to optimize recycling
- DON'T put `LazyColumn` inside a vertically scrollable container

## Slot APIs
- DO use lambda parameters (slots) for composable content: `fun Card(content: @Composable () -> Unit)`
- DO use multiple named slots for complex layouts: `topBar`, `bottomBar`, `content`
- DO provide sensible defaults: `title: @Composable () -> Unit = {}`

## Modifier Chaining
- DO always accept `modifier: Modifier = Modifier` as the first non-required parameter
- DO apply the passed-in modifier first: `Modifier.then(modifier).padding(16.dp)`
- DON'T hardcode size modifiers inside reusable components — let the caller decide
- DO chain modifiers in order: layout → drawing → interaction: `.fillMaxWidth().background(color).clickable { }`

## Preview
- DO add `@Preview` to all reusable components
- DO use `@PreviewParameter` for data-driven previews
- DO create preview-specific data: `@Preview @Composable fun UserCardPreview() { UserCard(user = previewUser) }`
- DO use `@PreviewLightDark` and `@PreviewFontScale` for multi-config previews

## Material3 Theming
- DO use `MaterialTheme.colorScheme`, `.typography`, `.shapes` — never hardcode colors/fonts
- DO define custom theme extensions via `CompositionLocal` if needed
- DO use `Surface` as the root of themed content
- DON'T mix Material2 and Material3 components in the same screen

## Performance
- DO use `key(id) { }` in non-lazy composables to preserve state across reordering
- DO defer reads with lambda: `Modifier.drawBehind { drawRect(color) }` over `Modifier.background(color)` for animated colors
- DON'T allocate lambdas in tight recomposition loops — hoist or `remember` them
- DO profile with Layout Inspector and recomposition counts before optimizing
