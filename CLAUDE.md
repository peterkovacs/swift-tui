# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build
swift build

# Run all tests
swift test

# Run a single test suite or test
swift test --filter TextTests
swift test --filter "TextTests/testString"

# Run the HelloWorld example
swift run --package-path Examples/HelloWorld HelloWorld

# Update snapshots (when intentionally changing rendering behavior)
swift test --filter <TestName>  # with RECORD=true env or .snapshots(record: .all) in the test suite
```

Tests use Swift Testing (`@Test`, `@Suite`) with SnapshotTesting and InlineSnapshotTesting. Snapshot files live in `Tests/SwiftTUITests/__Snapshots__/`. To record new snapshots, change `.snapshots(record: .missing)` to `.snapshots(record: .all)` on the suite trait temporarily.

## Architecture

SwiftTUI is a terminal UI library with an API modeled after SwiftUI. It requires Swift 6.2, macOS 15+.

### Three-layer view model

1. **`View` (public)** — user-facing protocol; types declare `body`. Analogous to SwiftUI.
2. **`GenericView` (internal)** — interface between the view and the node graph. A view is either:
   - `PrimitiveView`: implements `build`/`update` directly (no `body`). Used by all built-in layout and drawing views.
   - `ComposedView<T>`: wraps a user-defined `View`, evaluates `body`, and installs an `@Observable`-based invalidation callback so state changes retrigger layout.
3. **`Node`** — the retained render tree. Each `GenericView` builds a `Node` subtree. Nodes hold parent/child relationships, compute global frames, and own a draw buffer (`Window<Cell?>`).

### Control protocol

`Control` is the subset of `Node`s that have a frame and participate in layout. A `Control`:
- Implements `size(proposedSize:) -> Size` and `layout(rect:) -> Rect`
- Is visited by the `Visitor.Size` and `Visitor.Layout` protocols (used by stack containers to measure and position children in flexibility order)

Not every node is a `Control` — modifier nodes like `Border` or `Background` traverse their subtree to find the real controls inside.

### Layout algorithm

Stacks (`HStack`, `VStack`) use a two-pass visitor pattern:
1. **Size pass**: children are sorted by flexibility (least flexible first) and given their proportional share of space.
2. **Layout pass**: children are positioned in definition order after sizes are resolved.

`Extended` is an `Int` extended with `±infinity`, used for flexible sizing (e.g., `.frame(maxWidth: .infinity)`).

### Rendering pipeline

- `Application.update()` is debounced (10 ms) via `AsyncStream` and runs on `@MainActor`.
- It calls `node.layout(rect:)` on the root, then `renderer.update()`.
- `Renderer.draw(rect:)` computes a new `Window<Cell?>` and calls `drawPixel(_:at:)` only for cells that changed.
- `TerminalRenderer` writes ANSI escape sequences to stdout. `TestRenderer` holds the window in memory for snapshot assertions.

### Input handling

`KeyParser` reads raw bytes from a `FileHandle` and emits `Key` values (characters, function keys, mouse events). Mouse events go through `hitTest(at:key:)` on the node tree; keyboard events go through `FocusManager` which tracks the focused `Focusable` control and routes keys to it, falling back to `bubble(key:)` to walk up the tree.

### State and reactivity

`@State` stores values in a `DynamicPropertyNode` keyed by `(type, label)`. `@Observable`-based composed views re-invalidate when observed state changes. `@Environment` propagates values down via `Node.environment` closures attached at each boundary node.

### Testing pattern

```swift
@MainActor
@Suite("Button Tests", .snapshots(record: .missing)) struct ButtonTests {
    @Test func testBasic() throws {
        let (application, _) = try drawView(Button("OK") { })
        assertSnapshot(of: application.renderer, as: .rendered)
    }
}
```

`drawView(_:size:)` builds an `Application` with a `TestRenderer` and calls `setup()`. Use `application.process(keys:)` to simulate keyboard input, then `application.renderer` as the snapshot value with `.rendered`, `.attributes`, or `.background` strategies.
