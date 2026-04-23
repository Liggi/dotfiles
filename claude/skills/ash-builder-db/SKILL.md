---
name: ash-builder-db
description: Query the Ash Builder Supabase (production) — annotations, evaluation batches, transcripts, evaluation criteria and results, annotator users. Use for annotation analysis, evaluation campaign progress, annotator decision patterns, or cross-joining to AlloyDB/BigQuery for session context.
---

# Ash Builder DB

Query production Supabase (the Ash Builder database) for annotations, evaluation batches, transcripts, evaluation criteria and results, and annotator user accounts.

## When to Use

**Use this skill when:**
- You need to find specific annotations (by user, date, conversation, message)
- You need to analyze annotation patterns or decisions
- You need to understand what annotators accepted/rejected
- You need to check evaluation batch progress or completion status
- You need to query evaluation results (human or LLM evaluations)
- You need to cross-reference annotations with conversation data
- User asks about "Julia's annotations", "recent annotations", "evaluation batches", "evaluation progress"

**Don't use this skill when:**
- You only need conversation metadata (use `slingshot-data-kb` → `kb/alloydb.md` or `kb/bigquery.md`)
- You only need message content (use `sc fetch` or `slingshot-data-kb` → `kb/firestore.md`)
- Local Supabase is sufficient (development/testing)

## Architecture

### Data Lives in Two Places

**Supabase (Production - Ash Builder DB):**
- Annotations (accepted/rejected content, model IDs, annotator decisions)
- Annotation projects and metadata
- User accounts (annotators)
- Permissions and roles

**AlloyDB (Production Analytics DB):**
- Session metadata (session counts, timestamps)
- Message metadata (message IDs, actors, timestamps)
- **NOT message content** (content is in Firestore)

**Common Pattern:** Query Supabase for annotations, then join with AlloyDB for session/message context.

## Connection Details

### Production Supabase

**Project:** `xgaedutyrxmwzpwqsnec` (Ash Builder - Production)
**URL:** `https://xgaedutyrxmwzpwqsnec.supabase.co`
**Region:** East US (North Virginia)

**Get API Keys:**
```bash
supabase projects api-keys --project-ref xgaedutyrxmwzpwqsnec
```

Returns:
- `anon` key (public, client-side)
- `service_role` key (admin, server-side only)

**Check Available Projects:**
```bash
cd ~/src/slingshot-ai/ash-builder
supabase projects list

# Shows:
# - xgaedutyrxmwzpwqsnec (Ash Builder - Production)
# - gjvnrtqivksrxbknyeme (Ash Builder - Test)
# - Local: 127.0.0.1:54321 (current linked project, used by pnpm dev)
```

### Local Supabase (Development)

**URL:** `http://127.0.0.1:54321`
**Database:** `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
**Status Check:** `supabase status`

**Current State:**
- Builder's `.env.local` points to local Supabase by default
- Local Supabase has minimal test data (usually just jason@slingshotai.com)
- Production data NOT synced to local

## Annotations Table Schema

### Core Fields

```typescript
{
  // Identity
  id: string;                        // UUID
  created_at: timestamp;
  updated_at: timestamp;
  created_by: string;                // User ID (e.g., Julia's ID)
  updated_by: string | null;

  // Location
  data_collection_id: string;        // Anonymous user ID (links to AlloyDB)
  message_id: string;                // Message being annotated

  // Accepted content (what should be sent)
  accepted_content: string;          // Final accepted message
  accepted_original_content: string; // Original version before edits
  accepted_source: string;           // "original-message" | "ai-suggestion" | "handwritten-message"
  accepted_model_id: string | null;  // Model that generated accepted content
  accepted_annotation_suggestion_id: string | null;

  // Rejected content (what was rejected)
  rejected_content: string;          // What was rejected
  rejected_original_content: string; // Original rejected version
  rejected_source: string;           // "original-message" | "ai-suggestion"
  rejected_model_id: string | null;  // Model that generated rejected content
  rejected_annotation_suggestion_id: string | null;

  // Metadata
  status: string;                    // "review" | "deleted" | other statuses
  tags: string[];                    // Array of tag strings
  annotation_fork: string | null;

  // Tie handling (A/B comparisons)
  is_tie: boolean;
  tie1_content: string | null;
  tie1_original_content: string | null;
  tie1_model_id: string | null;
  tie1_source: string | null;
  tie1_annotation_suggestion_id: string | null;
  tie2_content: string | null;
  tie2_original_content: string | null;
  tie2_model_id: string | null;
  tie2_source: string | null;
  tie2_annotation_suggestion_id: string | null;

  // Prompt context (sometimes included)
  prompt: Array<{role: string, content: string}> | null;
  prompt_construction_dependencies: any | null;
}
```

### Key Column Differences from Expected Names

**⚠️ IMPORTANT:**
- Use `data_collection_id` (NOT `conversation_id`)
- Use `created_by` (NOT `user_id`)
- Message IDs link to AlloyDB `metadata.messages.message_id`
- Data collection IDs link to AlloyDB `metadata.sessions.anonymous_user_id`

## Evaluation Tables Schema

The Builder database also contains evaluation system tables for human/LLM conversation evaluation campaigns.

### evaluation_batches
Groups transcripts for organized evaluation campaigns.
```typescript
{
  id: string;                    // 'batch_...' prefixed UUID
  name: string;                  // e.g., "Julia", "New Evaluations - Nov 26th"
  description: string | null;    // e.g., "Pairwise comparison batch..."
  criteria_id: string | null;    // FK to evaluation_criteria
  created_at: timestamp;
}
```

### transcripts
Canonical conversation snapshots to be evaluated.
```typescript
{
  id: string;                    // 'transcript_...' prefixed UUID
  batch_id: string | null;       // FK to evaluation_batches
  source_type: string;           // e.g., "production", "simulated"
  source_identifier: string;     // Original session/conversation ID
  turns: JSONB;                  // Array of {role, content} messages
  metadata: JSONB;               // Additional context
  created_at: timestamp;
}
```

### evaluation_criteria
Reusable scorecard definitions.
```typescript
{
  id: string;                    // 'criteria_...' prefixed UUID
  name: string;                  // e.g., "Empathy & Direction (Simplified)"
  version: string;               // e.g., "1.0"
  definition: JSONB;             // Scorecard structure
  created_by: UUID | null;       // FK to auth.users
  created_at: timestamp;
  updated_at: timestamp;
}
```

### evaluation_results
Individual evaluation outcomes.
```typescript
{
  id: string;                    // 'result_...' prefixed UUID
  transcript_id: string;         // FK to transcripts
  criteria_id: string;           // FK to evaluation_criteria
  evaluator_type: string;        // 'human' | 'llm'
  evaluator_ref: string;         // User ID (for human) or model name (for llm)
  results: JSONB;                // Evaluation scores/responses
  started_at: timestamp;
  completed_at: timestamp | null;
  updated_at: timestamp;
}
```

**Unique constraint:** One evaluation per (transcript_id, criteria_id, evaluator_ref) combination.

### Example: Query Evaluation Batches

```javascript
// Get all batches with transcript counts
const { data: batches } = await supabase
  .from('evaluation_batches')
  .select('*')
  .order('created_at', { ascending: false });

for (const batch of batches) {
  const { count } = await supabase
    .from('transcripts')
    .select('*', { count: 'exact', head: true })
    .eq('batch_id', batch.id);

  console.log(`${batch.name}: ${count} transcripts`);
}
```

### Example: Get Evaluation Progress by Evaluator

```javascript
// Get evaluation completion stats for a batch
const { data: transcripts } = await supabase
  .from('transcripts')
  .select('id')
  .eq('batch_id', '<batch_id>');

const transcriptIds = transcripts.map(t => t.id);

const { data: results } = await supabase
  .from('evaluation_results')
  .select('evaluator_type, evaluator_ref, completed_at')
  .in('transcript_id', transcriptIds);

// Group by evaluator
const byEvaluator = {};
for (const r of results) {
  const key = `${r.evaluator_type}:${r.evaluator_ref}`;
  byEvaluator[key] = byEvaluator[key] || { total: 0, completed: 0 };
  byEvaluator[key].total++;
  if (r.completed_at) byEvaluator[key].completed++;
}
```

## Query Patterns

### Pattern 1: Find Annotator's Recent Annotations

**Script:** `~/src/slingshot-ai/ash-builder/scripts/find-julia-annotations-production.mjs`

```javascript
#!/usr/bin/env node
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://xgaedutyrxmwzpwqsnec.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

// Find user by email
const { data: users } = await supabase
  .from('users')
  .select('id, email')
  .ilike('email', '%julia%');

const juliaId = users[0].id;

// Get recent annotations
const { data: annotations } = await supabase
  .from('annotations')
  .select('*')
  .eq('created_by', juliaId)
  .order('created_at', { ascending: false })
  .limit(20);

// Write to file
fs.writeFileSync('/tmp/annotations-output.json', JSON.stringify({
  users,
  annotations,
  timestamp: new Date().toISOString(),
}, null, 2));
```

**Run:**
```bash
cd ~/src/slingshot-ai/ash-builder
SUPABASE_SERVICE_KEY=<key from api-keys command> \
node scripts/find-julia-annotations-production.mjs
```

**Output:** `/tmp/julia-annotations-production.json`

### Pattern 2: Enrich Annotations with AlloyDB Context

After getting annotations from Supabase, join with AlloyDB for session/message context:

```sql
-- Get user's total session count
SELECT
  anonymous_user_id,
  COUNT(*) as total_sessions
FROM metadata.sessions
WHERE anonymous_user_id = '<data_collection_id from annotation>'
GROUP BY anonymous_user_id
```

```sql
-- Get session number for this annotation
WITH user_sessions AS (
  SELECT
    session_id,
    started_at,
    ROW_NUMBER() OVER (ORDER BY started_at) as session_number
  FROM metadata.sessions
  WHERE anonymous_user_id = '<data_collection_id>'
)
SELECT
  session_id,
  session_number,
  started_at
FROM user_sessions
WHERE session_id IN (
  SELECT session_id FROM metadata.messages WHERE message_id = '<message_id from annotation>'
)
```

```sql
-- Get message number and total messages in session
WITH session_messages AS (
  SELECT
    message_id,
    actor,
    started_at,
    ROW_NUMBER() OVER (ORDER BY started_at) as message_number
  FROM metadata.messages
  WHERE session_id = '<session_id>'
)
SELECT
  message_id,
  message_number,
  actor,
  (SELECT COUNT(*) FROM metadata.messages WHERE session_id = '<session_id>') as total_messages
FROM session_messages
WHERE message_id = '<message_id from annotation>'
```

### Pattern 3: Find Annotations by Criteria

**Power users with long conversations:**
```javascript
// 1. Get annotations from Supabase
const { data: annotations } = await supabase
  .from('annotations')
  .select('*')
  .eq('created_by', annotatorId)
  .order('created_at', { ascending: false })
  .limit(50);

// 2. For each annotation, query AlloyDB for context
// 3. Filter to: session count >= 30, message count >= 30, message number >= 30
// 4. Rank by richness of context
```

### Pattern 4: Analyze Annotation Decisions

```javascript
// Extract annotation patterns
const patterns = {
  topicSwitches: [],
  validationAdded: [],
  probingRemoved: [],
};

for (const ann of annotations) {
  if (ann.rejected_content.includes('let\'s talk about') &&
      ann.accepted_content.includes('at your own pace')) {
    patterns.topicSwitches.push(ann);
  }
  // ... more pattern detection
}
```

## Common Queries

### Find All Annotations for a User
```javascript
const { data } = await supabase
  .from('annotations')
  .select('*')
  .eq('data_collection_id', '<data_collection_id>')
  .order('created_at', { ascending: false });
```

### Find Annotations by Message ID
```javascript
const { data } = await supabase
  .from('annotations')
  .select('*')
  .eq('message_id', '<message_id>');
```

### Find Annotations by Status
```javascript
const { data } = await supabase
  .from('annotations')
  .select('*')
  .eq('status', 'review')
  .order('created_at', { ascending: false })
  .limit(50);
```

### Find Annotations with Specific Tags
```javascript
const { data } = await supabase
  .from('annotations')
  .select('*')
  .contains('tags', ['send-photos'])  // Has this tag
  .order('created_at', { ascending: false });
```

## Safety Guidelines

**❌ NEVER:**
- Write/update/delete annotations without explicit user permission
- Modify production data
- Use production queries in automated loops (rate limits)

**✅ ALWAYS:**
- Use service_role key (not anon key) for reliable access
- Write results to `/tmp/` for easy reading
- Include timestamps in output files
- Log queries for debugging
- Cross-reference with AlloyDB for full context

**⚠️ Be Careful:**
- Production Supabase is the source of truth for annotations
- Local Supabase is empty/stale (only test data)
- Always verify you're querying the right environment

## Output File Conventions

**Annotations queries:** `/tmp/<annotator>-annotations-production.json`
**Schema dumps:** `/tmp/supabase-schema-<table>.json`
**Analysis results:** `/tmp/annotation-analysis-<date>.json`

**Standard format:**
```json
{
  "users": [...],
  "annotations": [...],
  "metadata": {
    "timestamp": "2025-11-01T...",
    "query": "description of what was queried",
    "filters": {...}
  }
}
```

## Cross-Database Workflow

**Typical workflow for analyzing annotations:**

1. **Query Supabase** for annotations
   ```bash
   SUPABASE_SERVICE_KEY=<key> node scripts/query-annotations.mjs
   # Outputs: /tmp/annotations.json
   ```

2. **Extract data collection IDs**
   ```bash
   jq -r '.annotations[].data_collection_id' /tmp/annotations.json | sort -u
   ```

3. **Query AlloyDB** for session/message context
   ```sql
   SELECT anonymous_user_id, COUNT(*) as sessions
   FROM metadata.sessions
   WHERE anonymous_user_id IN (...)
   GROUP BY anonymous_user_id
   ```

4. **Combine and analyze**
   - Match annotations to session numbers
   - Calculate message positions
   - Filter by criteria (session count, message count, etc.)

## Example: Find Julia's Annotations from Oct 30-31

```bash
# 1. Query Supabase
cd ~/src/slingshot-ai/ash-builder
SUPABASE_SERVICE_KEY=$(supabase projects api-keys --project-ref xgaedutyrxmwzpwqsnec | grep service_role | awk '{print $3}') \
node scripts/find-julia-annotations-production.mjs

# Output: /tmp/julia-annotations-production.json

# 2. Extract data collection IDs
jq -r '.annotations[].data_collection_id' /tmp/julia-annotations-production.json | sort -u > /tmp/data-collection-ids.txt

# 3. Check session counts in AlloyDB
/opt/homebrew/Cellar/postgresql@16/16.10/bin/psql \
  "host=localhost port=5435 dbname=production user=jason@slingshotai.com sslmode=disable" \
  -c "SELECT anonymous_user_id, COUNT(*) as sessions
      FROM metadata.sessions
      WHERE anonymous_user_id IN (...)
      GROUP BY anonymous_user_id
      ORDER BY sessions DESC"

# 4. For interesting annotations, get message/session numbers
# (See "Query Patterns" section above)
```

## Troubleshooting

### Issue: Empty Results from Supabase

**Cause:** Querying local Supabase instead of production

**Check:**
```bash
# Current builder environment
cd ~/src/slingshot-ai/ash-builder
rg "^NEXT_PUBLIC_SUPABASE_URL" .env.local

# If shows http://127.0.0.1:54321 → you're on local
# If shows https://xgaedutyrxmwzpwqsnec.supabase.co → you're on production
```

**Solution:** Use standalone scripts with explicit production credentials (don't rely on .env)

### Issue: "column does not exist" errors

**Cause:** Schema mismatch between local and production, or incorrect column names

**Solution:**
- Use `SELECT *` first to see actual schema
- Check column names match (e.g., `data_collection_id` not `conversation_id`)
- Reference schema in this doc

### Issue: Authentication errors

**Cause:** Using anon key instead of service_role key

**Solution:** Get fresh service_role key:
```bash
supabase projects api-keys --project-ref xgaedutyrxmwzpwqsnec | grep service_role
```

## Files and Scripts

### ⚠️ CRITICAL: Script Execution Rules

**Scripts MUST be placed in `~/src/slingshot-ai/ash-builder/scripts/` and run with `pnpm exec tsx`.**

Scripts in `/tmp/` will FAIL because they can't resolve `@supabase/supabase-js` from the project's node_modules.

**❌ WRONG - Will fail:**
```bash
# Script in /tmp can't find dependencies
SUPABASE_SERVICE_KEY=<key> node /tmp/my-query.mjs
SUPABASE_SERVICE_KEY=<key> pnpm exec tsx /tmp/my-query.mjs  # Also fails!
```

**✅ CORRECT - Always works:**
```bash
# 1. Put script in ash-builder/scripts/
cp /tmp/my-query.mjs ~/src/slingshot-ai/ash-builder/scripts/

# 2. Run from ash-builder directory with pnpm exec tsx
cd ~/src/slingshot-ai/ash-builder
SUPABASE_SERVICE_KEY=<key> pnpm exec tsx scripts/my-query.mjs
```

### Query Scripts

**Location:** `~/src/slingshot-ai/ash-builder/scripts/`

**Available:**
- `find-julia-annotations-production.mjs` - Query Julia's annotations from production
- `query-evaluation-batches.mjs` - List all evaluation batches with completion stats
- (Create more as needed for specific query patterns)

**Template for new scripts:**
```javascript
#!/usr/bin/env node
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabaseUrl = 'https://xgaedutyrxmwzpwqsnec.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseKey) {
  console.error('Set SUPABASE_SERVICE_KEY environment variable');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Your query here
const { data, error } = await supabase
  .from('annotations')
  .select('*')
  .limit(10);

// Write to /tmp/
fs.writeFileSync('/tmp/output.json', JSON.stringify(data, null, 2));
console.log('Results written to /tmp/output.json');
```

## Related Skills

- **slingshot-data-kb**: Data-systems reference for AlloyDB (session/message metadata), BigQuery (events, transcripts, costs), Firestore (message content), id graph, and cross-system joins.

## Examples

### Example 1: Find All of Julia's October Annotations

```bash
cd ~/src/slingshot-ai/ash-builder

# Get service key
SERVICE_KEY=$(supabase projects api-keys --project-ref xgaedutyrxmwzpwqsnec | grep service_role | awk '{print $3}')

# Create query script
cat > /tmp/query-julia-oct.mjs << 'EOF'
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(
  'https://xgaedutyrxmwzpwqsnec.supabase.co',
  process.env.SUPABASE_SERVICE_KEY
);

const { data: users } = await supabase
  .from('users')
  .select('id, email')
  .eq('email', 'julia.freels@slingshot.xyz');

const { data: annotations } = await supabase
  .from('annotations')
  .select('*')
  .eq('created_by', users[0].id)
  .gte('created_at', '2025-10-01T00:00:00Z')
  .lte('created_at', '2025-10-31T23:59:59Z')
  .order('created_at', { ascending: false });

fs.writeFileSync('/tmp/julia-oct-annotations.json',
  JSON.stringify({ users, annotations }, null, 2));

console.log(`Found ${annotations.length} annotations`);
EOF

# Run it
SUPABASE_SERVICE_KEY=$SERVICE_KEY node /tmp/query-julia-oct.mjs

# Output: /tmp/julia-oct-annotations.json
```

### Example 2: Find Annotations Where Annotator Replaced AI Response

```bash
# Query for handwritten replacements
cat > /tmp/find-handwritten.mjs << 'EOF'
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://xgaedutyrxmwzpwqsnec.supabase.co',
  process.env.SUPABASE_SERVICE_KEY
);

const { data } = await supabase
  .from('annotations')
  .select('*')
  .eq('accepted_source', 'handwritten-message')
  .order('created_at', { ascending: false })
  .limit(50);

console.log(JSON.stringify(data, null, 2));
EOF

SUPABASE_SERVICE_KEY=$SERVICE_KEY node /tmp/find-handwritten.mjs > /tmp/handwritten-annotations.json
```

### Example 3: Cross-Reference with AlloyDB

```bash
# 1. Get annotations
SUPABASE_SERVICE_KEY=$SERVICE_KEY node scripts/find-annotations.mjs

# 2. Extract data collection IDs
jq -r '.annotations[].data_collection_id' /tmp/annotations.json | sort -u > /tmp/dc-ids.txt

# 3. Build SQL IN clause
DC_IDS=$(cat /tmp/dc-ids.txt | awk '{print "'"'"'" $0 "'"'"'"}' | paste -sd "," -)

# 4. Query AlloyDB
/opt/homebrew/Cellar/postgresql@16/16.10/bin/psql \
  "host=localhost port=5435 dbname=production user=jason@slingshotai.com sslmode=disable" \
  -c "
SELECT
  anonymous_user_id,
  COUNT(*) as total_sessions
FROM metadata.sessions
WHERE anonymous_user_id IN ($DC_IDS)
GROUP BY anonymous_user_id
ORDER BY total_sessions DESC
"
```

## Quick Reference

**Get production service key:**
```bash
supabase projects api-keys --project-ref xgaedutyrxmwzpwqsnec | grep service_role | awk '{print $3}'
```

**Query template:**
```bash
SUPABASE_SERVICE_KEY=<key> node <script.mjs>
```

**Output location:**
```bash
/tmp/<query-description>.json
```

**AlloyDB connection:**
```bash
/opt/homebrew/Cellar/postgresql@16/16.10/bin/psql \
  "host=localhost port=5435 dbname=production user=jason@slingshotai.com sslmode=disable"
```
