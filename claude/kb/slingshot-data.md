# Slingshot data knowledge base

The canonical reference for Slingshot data systems lives at:

```
~/src/slingshot-ai/slingshot-analyst/idris-config/kb/
```

This is the same KB baked into the Idris (analyst) container. Read the relevant file **before your first interaction with each system in a conversation**. Don't rely on memory for connection strings, schema details, CLI flags, ID formats, data quality rules, or tool syntax.

## Lookup table

| Before you... | Read |
|---|---|
| Query AlloyDB (Postgres, shared, 1,024 conn limit) | `kb/alloydb.md` |
| Query BigQuery (default for sessions, events, transcripts, costs, experiments) | `kb/bigquery.md` |
| Fetch from or query Firestore | `kb/firestore.md` |
| Run semantic search | `kb/qdrant.md` |
| Query Mixpanel via MCP | `kb/mixpanel.md` |
| Query Statsig via MCP | `kb/statsig.md` |
| Query APEX / prompt experiments (Supabase, read-only) | `kb/supabase-apex.md` |
| Cross-system joins / IDs across sources | `kb/id-graph.md` |
| Apply data-quality gates (timestamp fuzzing, consent, discarded, environment) | `kb/data-quality.md` |
| Use `sc` (slingshot-core) CLI | `kb/slingshot-core.md` |
| Classify what kind of question you're answering | `kb/question-types.md` |
| Search Cloud Logging | `kb/cloud-logging.md` |
| Explore Grafana | `kb/grafana.md` |
| Error tracking via Sentry | `kb/sentry.md` |
| Search Notion | `kb/notion.md` |
| Search GitHub code/PRs | `kb/github.md` |
| Slack MCP | `kb/slack.md` |
| Term mapping (user-facing → data terms) | `kb/glossary.md` |
| Ash product context (how users use it, session types) | `kb/product-context.md` |
| Create or iterate on an analyzer | `kb/analyzer-workflow.md` |
| LLM-powered transcript analysis | `kb/analysis-methodology.md` |

## Routing — which system answers which question

1. Session/user metadata → BigQuery `metadata.*` (default) or AlloyDB `metadata.*`
2. Analyzer results, issue detection, quality → **AlloyDB `analysis.*`** (AlloyDB-only)
3. Surveys, health scores, feedback → **AlloyDB `surveys.*`** (AlloyDB-only)
4. Tracking events, funnels, user creation → BigQuery `ash.*` (always `_view` suffix). These ARE the Mixpanel events (forwarded). Prefer BigQuery over Mixpanel MCP for event queries.
5. Conversation transcripts (SQL-joinable) → BigQuery `content.messages`
6. Experiment exposures → BigQuery `statsig.*`
7. Cost / spend → BigQuery `costs.cost_lines` (AlloyDB `cost.*` is stale, stopped May 2025)
8. Precise timing (AlloyDB/BQ-anonymous timestamps are fuzzed) → BigQuery `ash.*` only
9. Semantic search → `sc semantic search` + `classify`
10. New signal extraction from transcripts → `sc` + LLM analysis

## Safety rules that apply to every query

- **Consent gate**: filter `data_collection_consent_given = TRUE` when joining user data
- **Discarded filter**: `discarded IS NOT TRUE` on sessions and messages
- **EXPLAIN before complex AlloyDB queries** on tables over 1M rows — shared instance with 1,024 conn limit; cascading exhaustion has taken down pipelines
- **Never full-scan `metadata.messages` (101M) or `cost.cost_lines` (435M) without a date range + at least one additional filter**
- **Two ID domains in BQ cannot be joined**: public (`ash.*`, `statsig.*`, `costs.*`) vs anonymous (`metadata.*`, `content.*`) — read `kb/id-graph.md` before cross-system work
- **Never silently substitute data sources** — if asked for Firestore, use Firestore; disclose if you use a mirror

## If the KB isn't reachable

If `~/src/slingshot-ai/slingshot-analyst/idris-config/kb/` doesn't exist at this path (e.g., repo not checked out here), say so explicitly and ask rather than improvising schema from memory.
