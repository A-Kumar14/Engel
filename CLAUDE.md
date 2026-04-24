# Engel

Engel is an iOS second-brain app built around two mirrored spaces: a green globe for wins, energy, and aliveness, and a red globe for frustration, heaviness, and stuckness. Users capture short fragments, review AI-assisted sorting and tags, and notice patterns over time without being judged, scored, or pushed toward advice.

## Non-Negotiables
- Never prescribe, diagnose, or moralize.
- Show at most one insight per week.
- Skip is always a valid option.
- Export is one tap.
- No streaks, no guilt loops, no shame-based nudges.
- Authority stays with the human; AI suggestions are always editable.

## Workflow Rules
- Read `/docs/design-system.md` before any UI work.
- Read `/docs/screens/[screen].md` before implementing that screen.
- Every new feature requires a spec in `/docs/specs/` before implementation.
- Any change affecting globe visualization must reference `/docs/design-system.md`.
- If you get stuck or fail twice, stop and ask instead of trying a third blind approach.
- When the user writes `/handoff`, re-write `/handoff.md` with a short summary of the important work completed in the current chat so the next chat can resume with minimal context tokens.

## Tech Stack
- SwiftUI for UI and navigation.
- iOS 17+ only.
- Prefer Apple-native frameworks before adding third-party dependencies.
- Use Swift Package Manager for external packages when needed.
- Pin versions deliberately and document the reason in `/docs/dependencies.md`.

## Naming
- Types and views: `PascalCase`
- Properties and functions: `camelCase`
- Markdown files: `kebab-case`
- Constants: `SCREAMING_SNAKE_CASE` only when true global constants are needed

## Platform Constraint
- This project is iOS-only.
- Do not add Android, cross-platform, or `Platform.OS` style branching.

## Documentation Boundaries
- Keep specs concise and task-specific.
- Reference docs instead of duplicating them inside implementation files.
- Prefer small, scannable sections over long prose.
