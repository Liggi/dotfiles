# House rules — what reviewers here flag

Patterns reviewers on this team comment on **repeatedly**. This is not a checklist to satisfy on
every PR — it's a memory of what has been flagged before, so you can pre-empt it. **Apply where
relevant; not every rule applies to every change.** When one clearly does apply and you chose the
other way anyway, don't hide it — put it in the PR's review notes.

Mined from real review comments on this repo. Highest-frequency patterns lead each section.

## Reversibility & remote control

- **Prefer backend/flag-driven over baked-in.** Anything a user sees or feels — copy, animations,
  which options exist, thresholds, whether a feature is on — should be changeable without an app
  release where practical. Test: *if we wanted to change this next week, would we need to ship a new
  build?* If yes and it plausibly will change, drive it from the backend or a Statsig flag.
  *(Flagged repeatedly — e.g. animations bundled into the app + a hardcoded option set → "make it
  backend-driven, don't lock it in.")*
- **New capabilities ship dark and ramp.** A new, optional feature should be safe to merge off and
  turned on gradually, not on-by-default for everyone the moment it lands.

## Performance & scale

- **Assume a power user, not a test account.** Anything that grows with usage — a history, a feed, a
  list — must lazy-load; never load a whole collection at once to render it. Instant on your account,
  janky or crashing on someone with a year of data. *(Flagged repeatedly — e.g. an eager history list
  → "must lazy-load, this will jank/crash for power users.")*
- **Watch work done per item in hot paths.** Tracking or recomputing per-item in a
  performance-sensitive area adds up; prefer the narrowest scope that does the job.

## Decomposition & structure

- **One responsibility per unit.** A widget/class/function that holds state *and* branches on type
  *and* fires analytics is doing too much — split it and pull the logic into a controller so it's
  testable on its own and the render code stays readable. *(Flagged — "this widget has too many
  responsibilities / file is too long.")*
- **Prefer the platform's native affordances** over hand-rolled equivalents where one exists (e.g.
  standard semantics/controls over a raw gesture handler), unless there's a reason not to.

## Code hygiene & noise

- **No notes-to-self in the code.** Comments that narrate what the next line does, or restate the PR
  description, get stripped as noise. Keep a comment only for a non-obvious *why* a reader can't get
  from the code. If the "why" is for the reviewer, put it as a GitHub inline PR comment instead.
  *(Flagged verbatim — "a note from Claude to itself, useless.")*
- **Keep stray files out of the tree.** Handoff docs, scratch notes, and generated artifacts dropped
  at the repo root are noise to everyone (and every agent) reading the repo later — put docs where docs
  go, or leave them out of the PR.

## Accessibility

- **Don't regress screenreader/semantics.** New or restructured UI should keep VoiceOver/TalkBack
  working — label interactive elements, preserve semantics when swapping widgets.

---

*This file is compiled from the team's actual review history and is expanded as new patterns recur.
If a reviewer flags something here more than once, it earns a line.*
