---
name: build-transcript-cohort
description: Find a nuanced cohort by combining AlloyDB candidate discovery, Firestore transcript fetches, LLM judging, and resumable ash-lab batch runs.
---

# Build Transcript Cohort

Use this when the user wants a cohort defined by what is actually said in transcripts, not just coarse metadata.

## When to Use

- The target condition is nuanced enough that intake categories or existing taxonomies are too noisy.
- You need actual conversation text from Firestore, not just AlloyDB metadata.
- The work will likely require an LLM judge over many sessions.
- The run may be long enough that resumability matters.

Examples:
- "Find ~200 users clearly discussing their own alcohol or SUD issues."
- "Build a cohort of first sessions where the user asks for roleplay."
- "Screen transcripts for a therapy pattern that existing metadata cannot capture."

## Core Rule

Do not jump straight into a large batch. First prove the end-to-end path on a small sample:

1. candidate discovery
2. transcript fetch
3. judge prompt behavior
4. batch output + resume behavior

## Workflow

### 1. Restate the cohort as an explicit acceptance test

Write down:
- what counts
- what does not count
- whether the unit is user, session, or message
- whether recall or precision matters more

If the target is underspecified, ask only the question that changes the judge or sampling strategy.

### 2. Find candidate sessions in AlloyDB

Use the `alloydb-analytics` skill or direct SQL.

Default constraints:
- `data_collection_consent_given = true`
- sessions should usually be at least 2 days old so Firestore has synced
- completed sessions only unless the user explicitly wants active/incomplete ones
- start with a generous candidate pool if the metadata proxy is known to be noisy

Save candidate session IDs to a file.

### 3. Verify transcript accessibility before designing the full batch

Fetch 3-5 candidate sessions with `ash-lab fetch`.

Check:
- transcripts actually exist in Firestore
- the content matches the cohort intent
- the IDs you discovered in AlloyDB are usable for fetch
- message counts and session quality are good enough for judging

If Firestore fetches fail, debug that first. Do not continue to prompt design on an unverified data path.

### 4. Preflight the environment explicitly

Before any large run, verify the operational prerequisites.

Checklist:
- AlloyDB proxy is listening on `5435`
- Firestore auth works
- required API key exists for the chosen model provider
- `PYTHONPATH` and any service URL requirements are set if you are calling into slingshot-ml scripts
- output directory location is chosen intentionally
- `tmux` or another reconnectable shell is available for long runs

If OpenAI credentials are missing but Anthropic is available, say that explicitly and choose the provider deliberately instead of failing halfway through the batch.

### 5. Draft the judge on a tiny sample

If the judge itself is new, use the `create-analysis` skill.

Then run a pilot on a small sample first:

```bash
ash-lab batch-analyze \
  --prompt judge_prompt.txt \
  --sessions-file sample_ids.txt \
  --output-dir pilot_results/ \
  --model claude-sonnet-4-6 \
  --parallel 3
```

Review the outputs for:
- false positives
- false negatives
- evidence quality
- whether the output structure is actually usable downstream

### 6. Tighten the cohort loop before scaling

After the pilot, summarize:
- hit rate
- the main failure modes
- whether the upstream candidate query is too broad or too narrow
- whether the judge criteria need refinement

Only then expand to the full candidate set.

### 7. Run the full batch in a resumable way

Use a stable output directory and `--resume` for retries.

```bash
ash-lab batch-analyze \
  --prompt judge_prompt.txt \
  --sessions-file candidate_ids.txt \
  --output-dir cohort_run/ \
  --model claude-sonnet-4-6 \
  --parallel 5 \
  --resume
```

For long runs, use `tmux` rather than a fragile background shell.

### 8. Review, filter, and report the cohort honestly

Open the review UI when needed:

```bash
ash-lab review cohort_run/
```

Report back with:
- candidate pool size
- confirmed hit count
- approximate hit rate
- the main false-positive pattern
- what you would do next if the user wants a bigger or cleaner cohort

## Common Failure Modes

### Metadata proxy is too blunt

Symptom:
- the candidate query returns many irrelevant sessions

Response:
- widen candidate discovery if recall matters
- rely on transcript-level judging for the real inclusion test
- do not pretend the metadata proxy is cleaner than it is

### AlloyDB IDs and Firestore reality diverge

Symptom:
- IDs look correct in SQL but transcript fetches fail or map awkwardly

Response:
- verify on a small sample immediately
- document the exact ID mapping issue before scaling

### Large run dies partway through

Symptom:
- long batch is interrupted or killed

Response:
- reuse the same output directory
- rerun with `--resume`
- do not start from scratch unless the prompt or cohort definition changed materially

### Missing provider credentials

Symptom:
- OpenAI or Anthropic call fails because the key is absent

Response:
- surface the exact missing credential
- choose a deliberate provider fallback only if the user is okay with the model change
- note the change in the final summary because it affects comparability

## Deliverables

A good cohort-building session should leave behind:
- the SQL or candidate-selection method
- the session ID file
- the judge prompt
- the output directory for the batch run
- a short summary of hit rate and failure modes

That makes the next iteration a refinement pass, not a restart from zero.
