# Design System

## Color Tokens
- `bg`: `#0a0a0b`
- `bg-elevated`: `#0f0f11`
- `ink`: `#f4f1ea`
- `ink-dim`: `#8a857c`
- `ink-faint`: `#3a3731`
- `green`: `#4ade80`
- `green-deep`: `#14532d`
- `red`: `#f87171`
- `red-deep`: `#4c1414`
- `line`: `rgba(244, 241, 234, 0.08)`

## Typography
- Display family: `Fraunces`
- Mono family: `JetBrains Mono`
- Display weights: `300`, `400`, italic variants only for emphasis or reflective pull quotes
- Mono weights: `300`, `400`, `500`
- Use display for titles, section heads, and high-signal single-line statements.
- Use mono for body text, metadata, controls, timestamps, and tags.

## Spacing Scale
- `4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 120`

## Globe Treatment
- Base size reference: `132pt` to `168pt` circles depending on context.
- Green globe radial gradient:
  - center `#4ade80`
  - mid `rgba(74, 222, 128, 0.78)`
  - edge `#14532d`
  - outer falloff `rgba(10, 10, 11, 0.96)`
- Red globe radial gradient:
  - center `#f87171`
  - mid `rgba(248, 113, 113, 0.78)`
  - edge `#4c1414`
  - outer falloff `rgba(10, 10, 11, 0.96)`
- Stroke: `1pt` line with `rgba(244, 241, 234, 0.08)`
- Inset shadow:
  - highlight `rgba(244, 241, 234, 0.10)` at top-left
  - inner shade `rgba(0, 0, 0, 0.28)` at bottom-right
- Outer shadow:
  - blur `18`
  - y offset `3`
  - opacity `0.22`
- Pulse ring animation:
  - duration `2.4s`
  - easing `easeInOut`
  - scale `1.0 -> 1.08`
  - opacity `0.16 -> 0`
  - max two simultaneous rings

## Type Hierarchy
- `display-xl`: `34pt`, Fraunces, weight `400`, line height target `40`
- `display-lg`: `28pt`, Fraunces, weight `400`, line height target `34`
- `display-md`: `22pt`, Fraunces, weight `300`, line height target `28`
- `display-sm`: `18pt`, Fraunces, weight `300`, line height target `24`
- `body`: `15pt`, JetBrains Mono, weight `400`, line height target `22`
- `mono-sm`: `13pt`, JetBrains Mono, weight `400`, line height target `18`
- `mono-xs`: `11pt`, JetBrains Mono, weight `500`, line height target `14`
- `caption`: `10pt`, JetBrains Mono, weight `500`, uppercase tracking `0.8`

## Buttons
- Default height: `44pt`
- Corner radius: `12pt`
- Horizontal padding: `16pt`
- Primary fill: `bg-elevated`
- Border: `1pt` using `line`
- Text: `ink`
- Accent state may use green or red, never both in the same control

## Inputs
- Minimum height: `44pt`
- Background: `bg-elevated`
- Border: `1pt` using `line`
- Text: `ink`
- Placeholder: `ink-dim`
- Use mono text styles for all editable fields

## Cards
- Background: `bg-elevated`
- Border: `1pt` using `line`
- Radius: `16pt`
- Internal padding: `16pt` or `20pt`
- Avoid heavy blur or oversized glass effects; surfaces should feel editorial and restrained
