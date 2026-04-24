# Dependencies

## Current Foundation
- `SwiftUI`
  - Reason: primary UI framework for iOS 17+.
  - Setup: included with Xcode.
- `Foundation`
  - Reason: base types, formatting, dates, and data handling.
  - Setup: included with Xcode.
- `AVFoundation`
  - Reason: likely recording and playback foundation for voice capture.
  - Setup: included with Xcode.
- `Speech`
  - Reason: future transcription pathway if local or hybrid speech capture is explored.
  - Setup: included with Xcode.

## Future Implementations
- `AuthenticationServices`
  - Reason: Apple Sign In support.
  - Setup: included with Xcode.
- `Clerk iOS SDK`
  - Reason: hosted authentication if Clerk is retained for account management.
  - Install: add via Swift Package Manager after auth scope is finalized.
- `OpenAI Swift SDK`
  - Reason: embeddings or API access if OpenAI remains part of the stack.
  - Install: add via Swift Package Manager after API shape is defined.
- `Anthropic SDK or thin HTTP client`
  - Reason: sorting, tagging, and insight generation if Anthropic remains the LLM provider.
  - Install: choose once backend ownership is decided.
- `SwiftData`
  - Reason: on-device structured persistence for captures, tags, and insight history.
  - Setup: included with Xcode.
- `TipKit`
  - Reason: constrained, explainable in-product guidance if needed later.
  - Setup: included with Xcode.

## Notes
- Prefer Apple-native frameworks before third-party packages.
- Add dependencies only after a spec exists in `docs/specs/`.
- Record chosen versions and the reason for them when packages are introduced.
