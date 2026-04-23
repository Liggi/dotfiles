---
name: create-analysis
description: Guide creation of conversation analysis definitions for ash-lab. Use when user wants to create/design a new analysis for therapy conversations, design analysis prompts, or asks to "create an analyzer" or "design an analysis". Collaborative workflow that incorporates domain expertise and testing.
---

# Create Analysis

Collaboratively design conversation analysis definitions that can be run at scale with `ash-lab analyze`.

## When to Use

- User wants to create a new conversation analysis
- User asks to "design an analyzer" or "create an analysis definition"
- User wants to analyze therapy conversations for specific signals/patterns
- User requests help designing prompts for conversation analysis

## What Is an Analysis?

An **analysis definition** is a JSON file containing:
- A prompt for analyzing conversations
- An output schema defining the structure
- Metadata (name, version, description)

It gets stored in `~/.config/ash-lab/analyses/` and can be run at scale:
```bash
ash-lab analyze <analysis-name> --sessions-file ids.txt --model gpt-5
```

## Collaborative Workflow

### 1. Understand the Goal

Ask clarifying questions:
- **What are we trying to detect/measure?** (signals, patterns, assessments)
- **What matters most?** (specific indicators, behaviors, outcomes)
- **How should it be structured?** (scores, categories, sequences, yes/no)

Examples:
- "I want to detect moments where users show vulnerability"
- "Rate how engaged the user seems throughout the conversation"
- "Find sequences where therapist reflection leads to deeper sharing"

### 2. Draft Prompt & Output Schema

**Show drafts early and often:**
Don't wait for a "complete" prompt. Show incremental drafts and get feedback:
1. Sketch out criteria first → get feedback
2. Show prompt + output structure → get feedback
3. Show formal JSON Schema → get feedback

**Key principles:**

**Numbered message references:** Always reference specific messages by number for evidence.
```
Evidence: In message 5, the user shares... In message 12, they elaborate...
```

**Clear criteria:** Be explicit about what counts and what doesn't.
```
Vulnerability includes: sharing struggles, expressing difficult emotions, admitting fears
Does NOT include: general complaints, surface-level sharing
```

**Output structure in prompt:** Specify the structure in the prompt itself (human-readable).
```
Output JSON:
{
  "vulnerability_score": number (1-10),
  "evidence": [{"message_number": number, "indicator": string}]
}
```

**Formal JSON Schema:** Also create the machine-validatable schema (used by ash-lab for validation).
```json
{
  "type": "object",
  "required": ["vulnerability_score", "evidence"],
  "properties": {
    "vulnerability_score": {"type": "number", "minimum": 1, "maximum": 10},
    "evidence": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["message_number", "indicator"],
        "properties": {
          "message_number": {"type": "number"},
          "indicator": {"type": "string"}
        }
      }
    }
  }
}
```

**Context awareness:** Remind the model this is therapy conversation analysis.

**Common schema patterns:**
- **Scores:** `{"type": "number", "minimum": 1, "maximum": 10}`
- **Confidence:** `{"type": "string", "enum": ["low", "medium", "high"]}`
- **Trends:** `{"type": "string", "enum": ["increasing", "stable", "decreasing", "mixed"]}`
- **Evidence arrays:** Always link to specific message numbers

**Drawing from existing work:**
- See `examples/alliance-detection.md` for signal detection patterns
- See `examples/issue-detection.md` for hierarchical classification
- See `examples/engagement-rating.md` for assessment scoring
- See `examples/sequence-detection.md` for pattern matching
- See `schema-guide.md` for more patterns

### 3. Test on a Real Session

**Critical step:** Test before scaling!

Use the `alloydb-analytics` skill to find an appropriate test session:
- Recent sessions (last 30 days)
- Reasonable length (10-30 messages)
- Completed conversations

Then fetch the session and run the analysis prompt on it, showing results.

**Look for:**
- ✅ Output matches schema
- ✅ Evidence cites specific messages
- ✅ Results seem accurate/meaningful
- ❌ Missing important signals
- ❌ False positives
- ❌ Vague explanations

### 4. Iterate

Based on test results, refine:
- **Tighten criteria** if too many false positives
- **Broaden criteria** if missing obvious cases
- **Add examples** to prompt for edge cases
- **Clarify output format** if schema violations

**Iterate multiple times** until results look good.

### 5. Save the Definition

Once satisfied, save to `~/.config/ash-lab/analyses/<name>.json`:

```json
{
  "name": "engagement",
  "version": "1.0",
  "description": "Measures user engagement in therapy conversations",
  "created_at": "2025-11-08T...",
  "prompt": "...",
  "output_schema": {...},
  "default_model": "gpt-5"
}
```

Tell user how to run it:
```bash
ash-lab analyze engagement --sessions-file ids.txt --model gpt-5
```

## Best Practices

**Prompt engineering:**
- See `best-practices.md` for detailed guidance
- Study examples in `examples/` directory
- Draw patterns from proven work (Luka's issues, Jason's alliance)

**Common pitfalls:**
- ❌ Forgetting to ask for message numbers (hard to verify later)
- ❌ Vague criteria (leads to inconsistent results)
- ❌ No testing (scales broken prompts)
- ❌ Over-complicated schemas (harder to validate)

**Quality checks:**
- ✅ Prompt includes numbered message references requirement
- ✅ Schema is specific and validatable (JSON Schema format)
- ✅ Tested on at least one real session
- ✅ Outputs are actionable and interpretable

## Domain Knowledge

**Therapy conversation analysis specifics:**

**Alliance signals** (Jason's work):
- User confirms feeling understood
- Therapist validates user experience
- Collaborative goal-setting moments
- Repair after ruptures

**Issue detection** (Luka's work):
- Hierarchical taxonomy of problems
- Confidence ratings (1-5)
- Severity ratings
- Message-level evidence

**Engagement indicators:**
- Elaboration depth (brief vs detailed)
- Emotional expression
- Self-disclosure
- Active participation vs passive responding

**Sequences:**
- Therapist reflection → User deeper share
- Question → Elaboration → Insight
- Validation → Disclosure

## Examples

See `examples/` directory for complete analysis definitions:
- `alliance-detection.md` - Detecting therapeutic alliance signals
- `issue-detection.md` - Hierarchical issue classification
- `engagement-rating.md` - Scoring user engagement
- `sequence-detection.md` - Finding conversational patterns

## After Creation

Once analysis is saved, user can:
```bash
# Test on single session
ash-lab analyze <name> --session <id> --model gpt-5

# Run at scale
ash-lab analyze <name> --sessions-file ids.txt --model gpt-5

# View/edit later
ash-lab analyses show <name>
ash-lab analyses edit <name>
```

## Remember

**This is a collaborative process.** Ask questions, show drafts, iterate based on feedback. The goal is a well-tested, reusable analysis that produces consistent, meaningful results at scale.
