# Examples — the same change, written two ways

A real case (a per-voice animation feature for the app). The *code* was the same in both. The
difference is entirely in how the PR was written — and it's the difference between a reviewer
approving in seconds and a reviewer spending twenty minutes discovering the problem, or missing it.

## The hard-to-review version (what not to do)

> **Add resilient per-voice artboard loading**
>
> Adds per-voice Rive visualizers so each voice gets its own animation. Implements resilient
> artboard loading to handle edge cases gracefully. Bumps the Rive runtime to 0.14.9.

What's wrong with it:

- **It hides a workaround as a feature.** "Resilient artboard loading" is actually a workaround for a
  native crash (a SIGSEGV) the author hit and wasn't sure was safe. Describing it as a clean feature
  means the reviewer has to *discover* the crash by reading the diff and a stray handoff doc — the
  exact dig the skill exists to prevent.
- **It buries a one-way-door decision.** The animations are baked into the app bundle and the feature
  is locked to a specific set of voices. That's a reversibility decision the reviewer cares about a
  lot (it can't be changed without an app release) — and it's not mentioned at all.
- **It states the what, not the why or the risk.** A reviewer reading this learns nothing they
  couldn't get from the file list, and nothing about where to spend their attention.

A reviewer either spends a long time uncovering all of this, or trusts the confident description and
merges a crash workaround and an irreversible decision. Both are bad outcomes.

## The easy-to-review version (what to do)

> **Add per-voice animations (backed by a workaround I'm not sure about)**
>
> Each voice now shows its own animation instead of the shared one. The animation files are selected
> by voice id in `voice_visualizer.dart`; start there.
>
> ## Review notes
> Look here first: the artboard-loading change in `voice_visualizer.dart`.
> Decisions you might disagree with: the animation files are bundled in the app and the set of voices
> is hardcoded. That means changing or adding a voice needs an app release. The onboarding flow does
> this backend-driven — I didn't, to keep this PR small, but flagging it in case we'd rather do it the
> reversible way now.
> Workarounds: I hit a native crash (SIGSEGV) loading some artboards and worked around it by
> [what was done]. I'm not confident this is the right fix — I didn't find a root cause, and I bumped
> the Rive runtime 0.14.6 → 0.14.9 partly hoping it helps. Worth a careful look.
> Couldn't verify: the crash only reproduced intermittently, so I can't be sure the workaround covers
> every case.

Same code. But now the reviewer's attention lands in three seconds on exactly the two things that
matter — the crash workaround and the bake-it-in-vs-backend-driven call — and they can make a fast,
informed decision instead of hunting. That is the whole game.

## The tell

If you find yourself reaching for words like "resilient," "robust," "gracefully handles," or "clean"
to describe something that was actually a workaround or a thing you weren't sure about — stop. That's
the moment to write it plainly in the review notes instead. The reviewer's trust in a confident
description is exactly what lets a questionable decision slip through.
