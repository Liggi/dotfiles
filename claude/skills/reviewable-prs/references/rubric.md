# Self-scoring rubric — how hard is this PR to review?

Before you request review, score your own PR on the four things a reviewer actually feels. This is
**not** about whether the code is correct — automated review owns that. It's about how much effort a
reviewer spends to understand what changed, why, and where the risk is. A flawed PR can be easy to
review (the flaw is visible, caught fast); a flawless one can be hard (huge, no narrative, decisions
buried). Score the second axis.

Rate each 0–10, higher = easier to review. If any one is low, fix it before requesting review.

1. **Volume / scope.** Is this one logical, self-contained change a reviewer can hold in their head?
   Small and single-purpose scores high. A large diff that bundles unrelated concerns scores low — and
   a tightly-themed mechanical change (one rename across many files) is more reviewable than a medium
   one that mixes three concerns. If this is low, go back to step 1 of the skill and split.

2. **Narrative.** Can a reviewer reconstruct *what* changed, *why*, and *where to look* — from the
   description, the commit history, and any inline annotations, without reading every line? Clear
   what/why/where with a reading order scores high, and a clean commit-by-commit story plus a short
   inline note on the two genuinely non-obvious lines is part of that narrative, not just the
   description. A missing, templated, or diff-restating description — or a `wip`/`fix2` commit trail —
   scores low.

3. **Decision & risk surfacing.** Are the load-bearing and risky choices flagged for the reviewer's
   attention, instead of left to be discovered in the diff? A PR that names its key decision, the
   alternative it rejected, and any residual risk or workaround scores high. A PR that reframes a risky
   workaround as a clean feature, or stays silent about a sharp edge it knows about, scores low. **This
   is the dimension that separates a genuinely reviewable PR from a merely small one** — and the one
   most worth getting right.

4. **Signal-to-noise.** Is the diff free of reviewer-distracting noise — dead/commented-out code,
   unrelated churn, reformatting mixed with logic, and notes-to-self? Clean scores high. Comments that
   narrate what the adjacent code plainly does are noise, not documentation — strip them. Genuine
   documentation of a non-obvious *why* is signal — keep it.

A fatal problem on one dimension caps the whole thing: a buried crash-workaround (low on #3) or a
2,500-line grab-bag (low on #1) makes a PR hard to review no matter how clean the rest is. Don't
average — fix the floor.
