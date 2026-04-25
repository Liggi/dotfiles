---
name: oracle
description: Consult a frontier reasoning model (gpt-5.5-pro, Opus, etc.) as an oracle on hard technical and reasoning problems. Collect load-bearing context, call the model, spot-check every citation, push back with specifics, iterate 3-5 rounds, produce the artifact you need (design doc, diagnosis, recommendation, analysis, stress-test). Invoke when the current local context has hit its limit and a smarter outside perspective would change the answer.
---

# Oracle

Consult a frontier reasoning model as an oracle on a hard technical or reasoning problem. The output artifact varies — design doc, diagnosis, recommendation, adversarial stress-test of a proposed approach, architecture analysis — but the loop is the same: collect load-bearing context, call, spot-check, push back, iterate, produce a final artifact.

This is the "escalate to a smarter model" path. You use it when the current local session has hit the limit of what it can produce alone.

## When to invoke

- Hard design / architecture question where you want a second opinion before committing
- Debugging problem where local context is exhausted and you want a fresh angle from a model that can reason harder
- Technical decision with real tradeoffs and no obvious right answer
- Stress-test a proposed approach before shipping it — ask the oracle to try to break it
- Complex analysis that exceeds one-turn reasoning capacity (perf investigation, security model, protocol design, algorithmic choice, cross-system integration design)
- User explicitly says "oracle", "get a second opinion", "ask gpt-5.5", "what would a smarter model say", "have another model look at this"

Don't invoke for:
- Targeted bug investigation with clear symptoms — use `/diagnose` first; escalate here only if diagnosis stalls
- Anything you can verify directly by reading code, running the real system, or checking docs
- Low-stakes questions where the cost of the Pro call (10-20 min wall time, real $) isn't justified
- Tasks the user already has a design for and wants implemented — just implement

## The loop

The loop has the same shape regardless of artifact. Tune the opening ask and final merge step to what you're producing.

### Round 1 — collect and ask

**Collect load-bearing context.** What goes in depends on the problem:

- *Architecture / design*: route registry, schema, core services, shared state containers, key UI composition, 3-5 representative tests, existing architecture docs
- *Debugging*: failing test or repro, the code paths on the failure trajectory, relevant logs, state dumps, recent diffs to the involved modules
- *Technical decision*: the current implementation of the two (or N) options, the constraints that rule out obvious alternatives, any benchmark / measurement data
- *Stress-test*: the proposed design or code, the existing invariants it's supposed to preserve, 3-5 tests that encode the current contract
- *Algorithmic / protocol*: the data shape, the constraints, the current solution if any, the specific property you want (correctness, latency, ordering, idempotency)

The common rule: include what's **load-bearing** for the specific question. Skip what the model can guess from context — generated code, lockfiles, boilerplate, CSS, fixtures. Target 100-200k tokens. Bigger is not better — context dilution is real.

**Bundle** into a single markdown file where each file is prefaced with `### <path>` in a code block. A simple hardcoded shell script is fine; resist building a framework.

**Ask** the opinionated question. Not "review this" — a specific angle the model has to commit to:

- *Architecture*: "How would you redesign this for ease of work / debug / maintenance?" "What's the architectural invariant missing?"
- *Debugging*: "Given these traces and this code, what's the root cause? Where would I place a log to confirm?"
- *Decision*: "A vs B — commit to one. Under what quantitative signal should I revisit?"
- *Stress-test*: "Try to break this. Find the race, the partial-failure mode, the invariant violation."
- *Design*: "Produce a committable design. No 'it depends'. If you need more files, list them first."

**Always include the output language constraints block** (see below) in the prompt. Pro defaults to compressed, jargon-y synthesis that reads concrete but hides hallucination behind invented nouns. The constraints force it to write for cold reading and mark inferences vs verified facts. Without the block, downstream rounds and the user-facing summary become unreadable.

Use `tools/call-reasoning-model.py` with `reasoning.effort: high`. Expect 8-20 minutes for gpt-5.5-pro. Long calls go to `run_in_background` or tmux — never `sleep`-loop.

#### Output language constraints (paste verbatim into every Pro prompt)

```
## Output language rules — apply to every claim, task, and recommendation

1. Write for someone reading cold. Assume no shared vocabulary from prior rounds or this conversation. The reader has not been through the investigation with you.

2. Define every non-obvious noun the first time you use it. If a term is invented for this conversation, mark it explicitly: "(my label, not team vocabulary)".

3. Prefer existing team / repo / product vocabulary over new compressed labels. If you do not know what the team calls something, ask — do not invent.

4. Mark every claim as one of:
   - [verified] — the investigation actually checked this (cite the file/grep/query)
   - [inferred] — derived from verified facts but not directly checked
   - [assumed] — neither verified nor strictly derivable; you are guessing

5. Do not compress concrete work into shorthand nouns. "Build a credential ledger" is shorthand. "Write a doc listing each token's read/write scope" is the actual work. Always prefer the second shape.

6. For each task, include a one-sentence plain-English headline that someone with no context could read and understand. The headline is not the task name — it is what the work actually is.

7. Do not assume the reader knows acronyms, internal project codenames, or framework names from prior rounds. Define them on first use even if they appeared in earlier turns.

8. If a recommendation depends on a fact you are uncertain about, say so explicitly and name what would resolve the uncertainty. Do not paper over uncertainty with confident phrasing.
```

### Round 2 — spot-check, then push back

**Spot-check every citation.** The model confabulates file paths, function names, and line numbers — especially in unfamiliar codebases. Use `tools/spot-check.sh` as a first pass, then read the response manually and grep-verify anything load-bearing. Don't delegate this to a subagent; subtle renames and near-misses are easy to miss.

**Translate before forwarding.** Pro's output is raw material, not the user-facing artifact. Before showing the user, walk every recommendation in plain English. Phrases that resist plain translation are evidence of hollow content — surface those explicitly. See the **translation gate** section below.

Report to the user:
- What the model got right
- What it got wrong or confabulated
- Which terms turned out to be Pro-invented labels vs real team vocabulary
- Your own read: does the analysis ring true? What does it miss?

**Push back in a follow-up turn.** State specifics:
- Your skepticism (where you disagree and why)
- What additional context would sharpen its picture (let it ask; don't guess)
- Invite disagreement: "If you think I'm wrong, say so"

Feed prior turns back as conversation history via the Responses API messages array. **Never use `previous_response_id`** — it fails on ZDR orgs with a cryptic error.

### Round 3+ — send what it asks for, iterate

When the model asks for specific files or context, send exactly that. The whole point of the loop is to see if its recommendation *changes* when it sees more. It often does.

Typical cadence:
- Round 3: send the slices it requested, ask for a sharpened version
- Round 4: ask for the final artifact (design doc / diagnosis / recommendation)
- Round 5: send spot-check corrections against the final artifact

Some problems land in 2 rounds. Some need 6. Stop when the model stops changing its mind.

### Final round — produce the artifact

The final artifact depends on what you asked for:

- **Design doc**: model typically emits "replacement sections" after corrections. Merge into a canonical file using `tools/splice-replacements.py` helpers (`demote_headings`, `extract_section`, `splice_range`). Place in the target repo's `docs/` directory or wherever matches convention. Write a small per-use merge script; don't generalize the merge logic.
- **Diagnosis / analysis / recommendation**: just take the final turn's text. No merge needed.
- **Code suggestion**: extract code blocks, but spot-check every referenced symbol before handing it back.

**Do not commit** the artifact without explicit per-session permission, even when Lattice convention allows direct-to-main.

## Translation gate

Pro outputs concrete-sounding nouns that compress invented terminology, real concepts, and uncertain inferences into the same surface form. Forwarding raw output buries hallucination under confident phrasing. The translation gate forces verification by re-expression.

**Every Pro recommendation goes through this gate before reaching the user.** Walk each task / claim / recommendation as follows:

1. **Plain-English headline.** Restate in one sentence with no jargon, internal labels, or acronyms. If you can't, the recommendation is not yet understood — push back to Pro before forwarding.

2. **Phrase walk.** For every non-trivial noun phrase, label it as one of:
   - **REAL** — points at something verified (file, ticket, person, system, concept the team uses)
   - **PRO-INVENTED LABEL** — Pro made up the name; the underlying idea may still be real
   - **HOLLOW** — phrase resists plain translation; likely confabulation or filler
   - **SCOPE-BLOAT** — real but trying to do more than the task warrants

3. **Bottom line per task.** State what the task actually is, what's overscoped, and what to drop.

4. **Surface invented labels.** Tell the user explicitly which terms are Pro's invention so they don't repeat them to colleagues who won't recognize them.

When in doubt: if you find yourself echoing Pro's wording verbatim, you haven't done the gate. Re-write in your own words, or admit you can't.

## Hard rules

- **Never trust a citation without verifying it.** Every `file.ts:123` and every `` `functionName` `` gets grepped before you quote it to the user. This is the single most important rule.
- **Never forward Pro output verbatim.** Apply the translation gate (see above) to every recommendation before showing the user. Phrases that resist translation are evidence of hollow content — surface those.
- **Always include the output language constraints block** in the Pro prompt. Pro defaults to jargon-compressed synthesis that hides hallucination; the constraints force cold-readable output with [verified]/[inferred]/[assumed] tags.
- **ZDR-safe conversation replay.** Rebuild the conversation inline as a messages array. `previous_response_id` fails on ZDR orgs.
- **Long calls go to tmux or `run_in_background`.** Pro reasoning calls take 10-20 minutes. Don't `sleep`-loop. Use Monitor if you need to watch.
- **Don't over-collect.** Context dilution degrades quality. Every file you include should be load-bearing. If uncertain, leave it out — you can send in a follow-up round when the model asks.
- **Push back when you disagree.** The loop's value is stress-testing, not acquiescence. State specifics; the model often revises materially.
- **Demand commitment.** If the final artifact has "it depends" or "the maintainer should decide X" for things the model has enough context on, send another round demanding commitment.
- **Don't chain rounds silently.** Report back to the user between rounds — what the model said, what you're pushing back on, what you plan to send next.

## Tools

- `tools/call-reasoning-model.py` — OpenAI Responses API caller, ZDR-safe, saves raw JSON + extracted text, prints usage. Supports single-turn and conversation replay via a history JSON file.
- `tools/spot-check.sh` — first-pass citation verifier. Extracts file paths and backtick-wrapped identifiers from a markdown file, greps each against a target repo, reports misses.
- `tools/splice-replacements.py` — library of merge helpers (`demote_headings`, `extract_section`, `splice_range`) for building per-use merge scripts when the artifact is a multi-section doc.

Each use's file collector and (if needed) merge script are **per-use**. A 40-line shell script + a 100-line Python splicer is the right size. Don't over-generalize.

## Anti-patterns

- **Delegating the spot-check to a subagent.** Subtle renames and near-misses get missed. Read the response yourself.
- **Forwarding Pro output verbatim.** The user sees compressed jargon and can't tell hallucination from clumsy expression. Always translate first (see translation gate).
- **Omitting the output language constraints block.** Without it, Pro writes for the version of you that's been through the rounds. The user can't read cold.
- **Bundling the whole repo.** Context dilution wrecks response quality.
- **Treating round 1 as final.** Round 1 is almost always too confident and partially wrong. Rounds 3-5 are where the answer actually lands.
- **Accepting hedges.** "It depends" and "the maintainer should decide" are not answers. Push back.
- **Dragging the loop.** If the model stops changing its recommendations, stop — you've converged.
- **Using this for problems the local session could solve.** The Pro call has real cost. If reading a file or running the test would answer the question, do that instead.
