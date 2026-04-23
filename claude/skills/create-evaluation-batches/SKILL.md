---
name: create-evaluation-batches
description: Create pairwise evaluation batches from Supabase annotations with conversation context. Use when user wants to create evaluation batches for annotators, set up pairwise comparisons, or asks to "create evaluation batches" or "set up annotator batches". Three-step workflow using existing scripts.
---

# Create Evaluation Batches

Create pairwise evaluation batches from Supabase annotations, enriched with conversation context from Internal Service.

## When to Use

- User wants to create evaluation batches from annotations
- User asks to "set up annotator batches" or "create pairwise comparisons"
- User wants to evaluate accepted vs rejected annotation content
- User needs to distribute evaluation work across annotators

## What This Creates

**Evaluation batches** in Supabase containing:
- Transcripts with last 5 turns of conversation context
- Pairwise comparison: accepted vs rejected content (randomly assigned to A/B for blinding)
- Shared transcripts across annotators (for inter-rater calibration)
- Unique transcripts per annotator

**Default configuration:**
- 5 annotators: Derrick, Daniel, Julia, Clare, Alexis
- 10 transcripts per batch: 3 shared + 7 unique
- Total: 38 annotations needed

## Three-Step Workflow

### Step 1: Query Annotations (JS → Supabase)

Queries annotations with both `accepted_content` and `rejected_content`, saves to intermediate file.

```bash
cd ~/src/slingshot-ai/ash-builder
SUPABASE_SERVICE_KEY="<key>" node scripts/query-annotations-for-context.mjs
```

**Output:** `/tmp/annotations-for-context.json`

**Script location:** `~/src/slingshot-ai/ash-builder/scripts/query-annotations-for-context.mjs`

### Step 2: Fetch Conversation Context (Python → Internal Service)

Fetches formatted prompts from production Internal Service using `data_collection_id` + `message_id`, extracts last 5 conversation turns.

```bash
cd ~/src/slingshot-ai/slingshot-ml
INTERNAL_SERVICE_URL="https://internal-607150243036.us-east5.run.app" \
INTERNAL_SERVICE_USE_AUTHENTICATION=true \
PYTHONPATH=. poetry run python scripts/fetch_annotation_contexts.py
```

**Input:** `/tmp/annotations-for-context.json`
**Output:** `/tmp/annotations-with-context.json`

**Script location:** `~/src/slingshot-ai/slingshot-ml/scripts/fetch_annotation_contexts.py`

### Step 3: Create Evaluation Batches (JS → Supabase)

Creates 5 evaluation batches in Supabase, one per annotator.

```bash
cd ~/src/slingshot-ai/ash-builder
SUPABASE_SERVICE_KEY="<key>" node scripts/create-annotator-batches-from-context.mjs
```

**Input:** `/tmp/annotations-with-context.json`
**Output:** 5 batches in Supabase, URLs printed

**Script location:** `~/src/slingshot-ai/ash-builder/scripts/create-annotator-batches-from-context.mjs`

## Script Locations

All scripts are saved in the codebase:

| Script | Location | Purpose |
|--------|----------|---------|
| `query-annotations-for-context.mjs` | `ash-builder/scripts/` | Query Supabase annotations |
| `fetch_annotation_contexts.py` | `slingshot-ml/scripts/` | Fetch context from Internal Service |
| `create-annotator-batches-from-context.mjs` | `ash-builder/scripts/` | Create batches in Supabase |

## Configuration

### Modify Annotators or Counts

Edit `create-annotator-batches-from-context.mjs`:

```javascript
const ANNOTATORS = ['Derrick', 'Daniel', 'Julia', 'Clare', 'Alexis'];
const NUM_SHARED = 3;
const NUM_UNIQUE_PER_ANNOTATOR = 7;
```

### Modify Context Turns

Edit `fetch_annotation_contexts.py`:

```python
CONTEXT_TURNS = 5
```

### Supabase Service Key

The service key for production Supabase (Builder database):
```
[REDACTED-SUPABASE-SERVICE-ROLE-KEY-ROTATED]
```

## Transcript Structure

Each transcript contains:

```json
{
  "source_type": "annotation_comparison",
  "source_identifier": "ann-<last8chars>",
  "turns": [
    {"id": "context-0", "role": "user", "content": "..."},
    {"id": "context-1", "role": "assistant", "content": "..."},
    {"id": "context-2", "role": "user", "content": "..."},
    {"id": "context-3", "role": "assistant", "content": "..."},
    {"id": "context-4", "role": "user", "content": "..."},
    {"id": "option-a", "role": "assistant-1", "content": "<accepted or rejected>"},
    {"id": "option-b", "role": "assistant-2", "content": "<rejected or accepted>"}
  ],
  "metadata": {
    "annotation_id": "...",
    "message_id": "...",
    "data_collection_id": "...",
    "accepted_source": "handwritten-message",
    "rejected_source": "ai-suggestion",
    "option_a_is_accepted": true/false,
    "context_turns": 5
  }
}
```

## Pairwise Comparison Criteria

Uses existing criteria "Annotation Pairwise Comparison" v1.0:
- Single dimension: "Which response is better?"
- Options: Response A, Response B, Tie/Unsure
- Includes rationale field

## Evaluation URLs

After creation, batches are accessible at:
```
https://builder.ash.health/evaluations/<batch_id>
```

## Troubleshooting

### "Not enough annotations with context"

- Check that annotations have `data_collection_id` and `message_id`
- Verify Internal Service is accessible (authentication working)
- Check logs for failed fetch requests

### Context fetch fails

- Ensure `INTERNAL_SERVICE_USE_AUTHENTICATION=true`
- Verify you have valid GCP credentials (`gcloud auth application-default login`)
- Check the prompt version exists (script auto-fetches latest)

### Supabase insert fails

- Check `SUPABASE_SERVICE_KEY` is set correctly
- Verify the `transcripts` and `evaluation_batches` tables exist
- Check RLS policies allow service role inserts

## Why Three Steps?

- **Python (slingshot-ml)**: Has gRPC tooling + Firestore auth for Internal Service
- **JavaScript (ash-builder)**: Has Supabase client setup
- **Intermediate JSON files**: Let each tool do what it's best at, easy to debug
