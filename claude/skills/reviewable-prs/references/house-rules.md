# House Rules — patterns reviewers flag repeatedly on ash-mobile-app

These are the things reviewers on this repo (a Flutter/Dart mobile app with server-driven UI)
flag over and over on designer- and agent-authored PRs. Apply them where relevant — not every
rule fits every change. The goal is to pre-empt the review comment, not to bolt on unrelated work.
When a rule and the actual change genuinely conflict, say so in the PR rather than silently
ignoring it.

Frequency tags: **[load-bearing]** = flagged repeatedly across PRs; **[recurring]** = seen a few
times; **[seen once]** = one flag, kept because it generalizes.

---

## 1. Performance & scale — assume the power user

This is the single most-flagged theme. Reviewers assume long histories and unbounded collections
are the *common* case, and they treat the conversation/caption/message loop as performance-critical.

- **[load-bearing] Build any list that grows with usage lazily.** Use `ListView.builder` (or an
  equivalent builder API) so only on-screen items are constructed. Eager-building a whole list
  "works fine for short histories" but janks for power users with 50+ weeks.
- **[load-bearing] Don't scan/filter/sort a whole collection to find one item.** Prefer
  `firstWhereOrNull` or a single O(n) pass over `where + sort + first`. If you need the newest and
  insertion order is oldest→newest, fold to a max rather than sorting.
- **[recurring] Don't accumulate session-wide derived state.** Tracking "every ID seen this
  session" in a growing `Set` is a red flag — listen to the existing reactive source that already
  holds the latest/incoming value, and narrow the listener (e.g. a `.select`) so it only fires on
  the transition you care about, not on every streamed token.
- **[recurring] In performance-sensitive paths, pick the simplest implementation that meets the
  requirement.** Extra hooks, listeners, and bookkeeping cause avoidable rebuilds and latency. If
  you're touching the conversation/caption/announcer area, expect scrutiny and default to less.
- **[recurring] Use viewport/visibility APIs for "what's currently on screen," not global-key
  measurement.** `VisibilityDetector` is the house pattern (see
  `lib/widgets/captions/active_session_captions_display.dart`); global-key offset measurement is
  fragile and doesn't scale.
- **[seen once] Validate hidden/empty data before counting or processing it.** If the UI hides
  empty messages, the projection/counter must skip them too, or chip counts drift from what's shown.

## 2. Reversibility & remote control — don't ship a binary to change a choice

Anything the backend already drives, or plausibly will, should not be hardcoded into the app. New
server-side variants must not require an app-store release.

- **[load-bearing] If a set of options is backend-driven, make its assets/behavior backend-driven
  too.** Example: voices are chosen server-side, so per-voice animations should be fetched on demand
  (keyed by voice name in a public asset folder), not bundled per-voice — otherwise a new voice
  needs a new build.
- **[recurring] Don't hardcode option-specific assets or logic when the option set can change.**
  Hardcoding locks the app to today's list.
- **[recurring] Standardize remote asset contracts** (artboard/animation names, keys, schemas) so
  they can be inferred (e.g. from the voice name) rather than special-cased per option client-side.
- **[recurring] Measure bundle-size impact before adding fonts, icons, or animations.** Tree-shaking
  is disabled here because of server-driven UI, so bulk-adding icon variants or large asset files
  can balloon the app. If you add such an asset, run a before/after bundle-size analysis and report it.

## 3. Decomposition & structure — separate logic from rendering

- **[load-bearing] Keep widgets focused on rendering; push business logic into a controller/notifier.**
  A long widget file is treated as a smell that state, event handling, and rendering are tangled.
  When a component juggles several responsibilities (e.g. survey state + question-type handling +
  event logging), extract a `...Controller`/notifier for the logic.
- **[recurring] Make complex components testable by splitting logic from rendering,** so business
  logic and UI can be tested independently.
- **[seen once] "Looks correct but hard to review" is itself a design issue** — understandable
  structure is part of the change, not optional polish.

## 4. Workarounds & architecture — name the real fix

Reviewers will accept a pragmatic workaround, but only if the intended architecture is explicit and
the workaround is genuinely reversible.

- **[recurring] If a solution feels like a workaround, say so and name the long-term path.**
  "Nice solution, but it feels like a workaround, fine for now" is a conditional approval — call out
  the follow-up (e.g. "session should eventually live logically on top of home") so it isn't lost.
- **[recurring] Actually remove things you mean to remove.** Swallowing gestures in a
  `GestureDetector` does not take it out of the widget tree — if a component is suspected of causing
  freezes, unmount it, don't just neuter it.
- **[seen once] When you deprecate something, name its replacement** in the same change. Deprecation
  without a migration path is a dead end.
- **[seen once] Cancel timers/listeners on all paths** (including early-exit/dispose), not just the
  happy path.
- **[seen once] Question whether a new wrapper is needed at all.** If the underlying widget already
  exposes what you want (e.g. `Icon` already has fill/weight; theme defaults exist), change the
  default rather than adding an abstraction layer.

## 5. Flutter/platform idioms — prefer built-ins, be wary of native

- **[recurring] Prefer Flutter/Material semantic widgets over raw `GestureDetector`.** Built-ins
  bring accessibility, focus, semantics, and hit-testing for free; hand-rolled gesture handling loses
  them.
- **[recurring] Be cautious with native rendering libraries / platform integrations.** A "possible
  SIGSEGV" workaround gets challenged hard: confirm the behavior, check upstream package guidance for
  a supported approach, and document the residual risk. Native crashes may not surface in Dart-level
  testing.
- **[seen once] Reuse existing app primitives before inventing your own.** There's already a custom
  `HapticFeedback` class, keyboard-visibility detection used elsewhere, etc. — match the existing
  approach instead of a parallel one, and don't stack redundant listeners (one `ScrollNotification`
  usually covers what you'd add a `ScrollMetricsNotification` for too).

## 6. Code hygiene & diff noise — the agent-authored tell

This is the flag most specific to agent-written PRs, and it recurs across reviewers.

- **[load-bearing] Strip agent self-notes and restatement comments.** "Notes from Claude to itself"
  add no value to future readers and are called out as noise every time. Comments should explain
  durable context, not narrate the change.
- **[recurring] Put handoff/design docs in an intentional `docs/` location,** not loose in the tree
  — stray handoff markdown adds noise for humans and for other agents reading the repo.
- **[recurring] One canonical PR per change.** Don't open duplicate PRs or split the review across
  branches; it fragments the review thread and drops feedback. If you must supersede a branch, close
  the old one pointing at the new.
- **[seen once] Keep the diff focused;** avoid unrelated reorganization riding along in the same PR.

## 7. Ownership — route Dart/Flutter-heavy or product-sensitive changes to the right reviewer

- **[recurring] Flag Dart/Flutter-heavy or product-logic-heavy files for the domain owner.**
  Non-specialist reviewers explicitly defer core Flutter logic to the Flutter owner, noting that
  unattended agent implementations tend toward "questionable / less-than-ideal decisions" in that
  area. Don't assume a light approval on the surrounding change covers the hard file.

## 8. Accessibility — announce completed content, exclude decoration

Lower-frequency but consistent when accessibility is in scope:

- **[seen once] Label at the button layer, not per-icon,** to avoid double announcements; exclude
  decorative graphics from the semantics tree (`ExcludeSemantics`).
- **[seen once] Announce on completion, not on every streamed token** — re-announcing a message as it
  streams is the exact failure the announce-on-complete design avoids.
