---
name: source-triangulation
description: Structured intake and synthesis from multiple sources (Slack, Notion, bookmarks, branches, research links, meeting notes). Use when user drops a batch of links to process, triage, or synthesize into actionable output.
---

# Source Triangulation

Synthesize scattered inputs into structured, actionable output. Biased toward producing reusable artifacts (docs, tests, helpers) over one-off scripts.

## Workflow

### 1. Inventory sources

List every source provided. For each, note:
- **Type**: Slack thread, Notion page, bookmark, branch, meeting note, research link, other
- **Accessibility**: Can you fetch/read it directly, or do you need the user to paste content?
- **Staleness risk**: How old is it? Could it be outdated?

Surface any sources you can't access and ask the user to provide the content.

### 2. Extract and classify claims

For each source, pull out discrete claims and classify each as:
- **Fact**: Directly verifiable (code exists, metric shows X, doc says Y)
- **Inference**: Reasonable conclusion drawn from evidence, but not directly stated
- **Unknown**: Gap that matters but isn't answered by any source

Present this as a flat list grouped by source before proceeding. The user should sanity-check before you cluster.

### 3. Cluster repeated themes

Group claims across sources by theme. A theme is real when it appears in 2+ independent sources or is strongly supported by one authoritative source. Call out:
- **Convergence**: Multiple sources agree
- **Tension**: Sources disagree or contradict
- **Solo signals**: Interesting but only from one source — flag confidence level

### 4. Map to active context

Connect themes to the user's active projects, decisions, or open questions. Ask if the mapping is unclear rather than guessing. If no active context is obvious, ask: "What decision or project should this feed into?"

### 5. Classify artifacts

For each theme or finding, recommend one of:
- **Adopt**: Worth acting on now. Specify the artifact: doc update, test, helper/utility, design decision, ticket.
- **Reference**: Worth keeping accessible but no immediate action. Specify where it should live.
- **Reject**: Not useful or superseded. State why briefly.

**Bias**: Prefer reusable artifacts (docs, tests, shared helpers, design records) over local scripts or one-off notes. If a finding improves a shared workflow or prevents a repeated mistake, it's an adopt candidate.

### 6. Produce output

Deliver a concise summary:
- **Adopt** items with specific next steps
- **Reject** items with brief rationale
- **Open questions** that need resolution before more items can move to adopt

## Examples

### Research synthesis

User drops 4 links about auth patterns (blog post, library README, Slack discussion, competitor's docs).

1. Inventory: 4 sources, all accessible via web fetch
2. Extract: "PKCE is required for SPAs" (fact, 3 sources), "refresh token rotation prevents replay" (fact, 2 sources), "silent refresh via iframe is deprecated in Safari" (inference from one blog post)
3. Cluster: Strong convergence on PKCE + rotation. Safari iframe claim is a solo signal — needs verification.
4. Map: Connects to the auth refactor project
5. Classify: PKCE migration guide → adopt (doc + implementation ticket). Safari iframe → reference (add to known-risks doc, verify before acting). Competitor's specific token format → reject (not applicable).
6. Output: 2 adopt items, 1 reference, 1 reject, 1 open question (verify Safari behavior)

### Branch intake

User has 3 stale branches and wants to decide what to keep.

1. Inventory: 3 branches, all readable via git
2. Extract: Branch A has a working utility that duplicates a pattern elsewhere. Branch B is a half-finished feature with useful test fixtures. Branch C is exploratory and outdated.
3. Cluster: Branches A and B both touch the data-processing layer. Branch C is independent.
4. Map: Data-processing work connects to the current sprint goal
5. Classify: Branch A's utility → adopt (extract and merge as shared helper). Branch B's test fixtures → adopt (cherry-pick fixtures into test suite). Branch B's feature code → reference (park for later). Branch C → reject (outdated, no reusable parts).
6. Output: 2 adopt items with specific git commands, 1 reference, 1 reject

## Principles

- Don't flatten nuance prematurely — tension between sources is signal, not noise
- Ask the user to verify your fact/inference/unknown classifications before building on them
- When in doubt about whether something is adopt vs reference, ask: "Would this prevent a repeated mistake or save time on a known-upcoming task?" If yes, adopt.
