# Changelog

All notable changes to quarry-tailwind. The format follows [Keep a Changelog](https://keepachangelog.com),
and versions follow [Semantic Versioning](https://semver.org).

## [Unreleased]

## [0.1.1] - 2026-10-22

### Changed

- `color(css)` raises on text that is not a CSS colour instead of returning nil, which left the
  token out of the theme without a word.

### Fixed

- A `Tw.bezier` transition no longer raises on Studio versions that add easing styles
  `TweenService:GetValue` refuses (Spring, Bezier): the curve is matched only against the plain
  styles from Linear to Circular.

## [0.1.0] - 2026-10-18

First release.

### Added

- `h(kind, props, ...children)`: DOM elements with a `className`, compiled into Roblox's style engine
  (StyleSheet, StyleRule) per state: hover, press, focus, disabled, `aria-pressed`, `data-*`,
  breakpoints, Reduced Motion, touch, and states that hold together.
- A compiler for Tailwind 4 class names against Tailwind 4.1.18's default theme: spacing, sizing,
  flex and grid, typography, borders and rings, radii, shadows, opacity, gradients, positioning,
  transforms, transitions, `animate-spin` and `animate-pulse`, arbitrary values and custom
  properties. Classes it cannot draw are warned of in Studio.
- `configure` to extend the theme and set the base styles (text, border and ring colours).
- CSS flow rules on Roblox layouts: blocks stretch, inline elements keep their width, text wraps in
  a definite width, margins, absolute and fixed children, transforms that keep the layout box,
  box shadows, one-sided and dashed borders.
- Inter calibrated to Chrome's text widths, and CSS line heights.
- `cva` and `cn`; `Presence` and `presets` for enter and exit animations; `Fade`, `AutoHeight`,
  `Portal`, `Layout`, `Text`, `Glyph`; `useText`, `useSlot`, `useViewport`, `useReducedMotion`,
  `useTween`; `bezier`, `linear`, `spring`, `frame` and `color`.

[Unreleased]: https://github.com/quarry-luau/quarry-tailwind/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/quarry-luau/quarry-tailwind/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/quarry-luau/quarry-tailwind/releases/tag/v0.1.0
