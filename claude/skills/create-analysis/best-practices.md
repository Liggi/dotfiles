# Prompt Engineering Best Practices for Conversation Analysis

Guidance distilled from production conversation analyzers (Luka's issue detection, Jason's alliance taxonomy work).

## Core Principles

### 1. Always Require Message References

**Why:** Without message numbers, results can't be verified or traced back to actual conversation moments.

**Pattern:**
```
For each detection/signal, cite specific message numbers as evidence.

Example output:
{
  "signal": "user_vulnerability",
  "messages": [5, 12, 18],
  "explanation": "In message 5, user shares..."
}
```

**In your prompt:**
```
Analyze the numbered conversation transcript below.
For each signal detected, reference specific message numbers.

Message numbers appear as [1], [2], [3] etc. in the transcript.
```

### 2. Define What Counts AND What Doesn't

**Why:** LLMs need explicit boundaries to avoid false positives.

**Bad example:**
```
Detect when users show vulnerability.
```

**Good example:**
```
Detect vulnerability signals including:
✅ Sharing personal struggles or fears
✅ Expressing difficult emotions (shame, grief, anxiety)
✅ Admitting weaknesses or mistakes
✅ Asking for help with sensitive issues

NOT including:
❌ General complaints about daily life
❌ Surface-level sharing without emotional depth
❌ Hypothetical scenarios or third-person stories
```

### 3. Embed Output Schema in Prompt

**Why:** Makes validation easier and reduces schema violations.

**Pattern:**
```
Output JSON matching this exact structure:
{
  "score": number (1-10),
  "confidence": "low" | "medium" | "high",
  "evidence": [
    {
      "message_number": number,
      "indicator": string,
      "explanation": string
    }
  ]
}
```

### 4. Provide Context About the Domain

**Why:** Therapy conversations have specific dynamics LLMs should understand.

**Useful context:**
```
You are analyzing therapy conversation transcripts.

In these conversations:
- "therapist" messages are from an AI therapy assistant
- "user" messages are from a person seeking support
- Conversations often involve sensitive personal topics
- Therapeutic alliance (trust, collaboration) is crucial
- Look for both explicit and implicit signals
```

### 5. Use Examples for Edge Cases

**Why:** Examples clarify ambiguous cases better than descriptions.

**Pattern:**
```
Examples of vulnerability signals:

✅ "I've been avoiding my family because I'm ashamed"
✅ "I don't know if I can handle this anymore"
✅ "It's hard to admit, but I think I need help"

NOT vulnerability:
❌ "Work was annoying today"
❌ "I might try meditation sometime"
```

## Common Pitfalls (from Production Experience)

### Pitfall 1: Forgetting to Request Confidence Levels

**Problem:** All detections treated equally, hard to filter low-confidence results.

**Solution:** Always include confidence rating:
```json
{
  "confidence": "low" | "medium" | "high",
  "confidence_explanation": "string (why this rating)"
}
```

### Pitfall 2: Vague Evidence Descriptions

**Problem:** "User seems engaged in message 5" - What specifically?

**Solution:** Require specific indicators:
```json
{
  "message_number": 5,
  "indicator": "detailed_elaboration",  // Specific label
  "explanation": "User provides 3-sentence detailed response with personal examples"
}
```

### Pitfall 3: Missing Negative Cases

**Problem:** Only finding what you're looking for, missing absence of signals.

**Solution:** Consider asking for explicit "not detected" cases:
```
If the signal is NOT present in this conversation, output:
{
  "detected": false,
  "explanation": "No instances of X because..."
}
```

### Pitfall 4: Ignoring Context from Earlier Messages

**Problem:** Analyzing each message in isolation.

**Solution:** Remind model to consider conversation flow:
```
Consider the full conversation context when analyzing.
Signals may build across multiple messages.

Example: Therapist reflection in message 3 → User deeper share in message 4
This sequence matters, not just individual messages.
```

### Pitfall 5: Inconsistent Scoring

**Problem:** "Engagement: 7/10" - compared to what baseline?

**Solution:** Provide anchors:
```
Engagement scoring guidelines:
1-3: Minimal engagement (one-word answers, deflecting)
4-6: Moderate engagement (some elaboration, surface-level)
7-9: Strong engagement (detailed sharing, emotional depth)
10: Exceptional engagement (sustained depth, insight generation)
```

### Pitfall 6: False-Positive Pressure for Rare Signals

**Problem:** When analyzing for rare signals (low base-rate phenomena), LLMs face pressure from RLHF training to be "helpful" by reporting SOMETHING rather than returning empty results. This leads to false positives - finding weak/ambiguous signals just to avoid saying "none found."

**Why this happens:**
1. **Reward modeling** - "I found nothing" feels unhelpful during training
2. **Pattern matching pressure** - Given a pattern, models find it even in noise
3. **Loss aversion** - Models perceive more risk in missing something than over-reporting

**Counter-strategies:**

**1. Explicit permission to return empty results**

Reframe empty as success, not failure:
```
Most conversations will have ZERO instances of [SIGNAL].
This is NORMAL and EXPECTED. Do not feel pressure to report something.
Returning an empty list is a valid and valuable result.
```

**2. Use conceptual boundaries, not exhaustive lists**

✅ **Good:** High-level conceptual clarity
```
[SIGNAL] is when [core defining characteristic].

Ask yourself: [Key distinguishing question]?
```

❌ **Avoid:** Exhaustive pattern matching lists that over-constrain the model and miss valid variations.

**Why:** Trust the model's ability to understand concepts. Over-specification trades one problem (false positives) for another (false negatives from brittleness).

**3. Confidence thresholds**

Let the model self-regulate:
```
For each instance, rate your confidence (1-10).
Only report instances where confidence ≥ 8.
When uncertain whether something counts, it doesn't count.
```

**4. Reframe the cost function**

Change what "success" means:
```
False positives are WORSE than false negatives.
Your goal is PRECISION, not recall.
When in doubt, don't report it.
```

**5. Adversarial self-questioning**

Build in falsification:
```
Before reporting, ask yourself:
- Could this be explained by [common alternative]?
- Is the evidence unambiguous?
- Would a skeptical reviewer agree?
```

**Recommended pattern for rare signals:**

```markdown
CRITICAL: Most conversations will have ZERO instances of [SIGNAL].
Empty results are expected and valid.

[Brief conceptual definition of signal]

[Key distinguishing criteria - conceptual, not exhaustive]

Requirements for reporting:
- Confidence ≥ 8/10
- Evidence must be unambiguous
- False positives worse than false negatives
- When uncertain, don't report
```

**Testing for false positives:**

Red flags:
- Every session returns results
- Flagged examples feel ambiguous
- You're defending borderline cases

Fix: Tighten confidence threshold, strengthen empty-is-valid framing.

## Prompt Structure Template

**Proven structure from production analyzers:**

```markdown
# Role & Context
You are analyzing therapy conversation transcripts to detect [SIGNALS].

# Conversation Format
The transcript is numbered [1], [2], [3]...
- "therapist" = AI therapy assistant
- "user" = person seeking support

# Detection Criteria
[SIGNAL_NAME] includes:
✅ [Specific indicator 1]
✅ [Specific indicator 2]
✅ [Specific indicator 3]

Does NOT include:
❌ [Common false positive 1]
❌ [Common false positive 2]

# Examples
[Show 2-3 concrete examples of what counts]

# Output Format
Output JSON matching this schema:
{
  // Schema here
}

# Transcript
{transcript}
```

## Testing Strategies

### Test on Diverse Cases

**Strategy:** Don't just test on "typical" conversations.

**Test set should include:**
- ✅ Clear positive cases (signal definitely present)
- ✅ Clear negative cases (signal definitely absent)
- ✅ Ambiguous cases (edge cases, borderline)
- ✅ Long conversations (40+ messages)
- ✅ Short conversations (5-10 messages)

### Validate Message References

**Check:** Do referenced messages actually contain the claimed signal?

**How:**
```
1. Run analysis
2. For each detection, look up the actual message
3. Verify: Does message content support the claim?
4. If not → refine prompt criteria
```

### Look for False Positives

**Common false positive patterns:**
- Detecting "agreement" as "insight"
- Detecting "politeness" as "alliance"
- Detecting "topic change" as "deflection"

**Fix:** Add explicit negative examples to prompt.

### Check Score Consistency

**For assessments (1-10 scales):**
```
Run on 10 similar conversations.
Are scores roughly consistent?
Or wildly different for similar conversations?
```

If inconsistent → Add scoring rubric with anchors.

## Model-Specific Notes

### OpenAI (GPT-4, GPT-5)

**Strengths:**
- Good at following complex instructions
- Reliable JSON output
- Handles long transcripts well

**Watch out for:**
- Sometimes over-confident (marks "high confidence" too freely)
- Can miss subtle signals without explicit examples

### Anthropic (Claude)

**Strengths:**
- Nuanced understanding of context
- Good at detecting implicit signals
- Conservative confidence ratings

**Watch out for:**
- May refuse some legitimate analyses (perceived sensitivity)
- Can be verbose in explanations (trim output format)

## Domain-Specific Patterns

### Alliance Signal Detection

**Key indicators:**
- Collaborative language ("we", "together", "our plan")
- Repair after misunderstanding
- User confirms feeling understood
- Therapist validates without judgment

**Common miss:** Confusing politeness with alliance.

### Issue Detection

**Pattern:** Hierarchical taxonomy with confidence levels.

**Structure:**
```json
{
  "issue_id": "1.2.3",  // From taxonomy
  "issue_title": "Therapist provides premature solutions",
  "confidence": 4,  // 1-5
  "severity": 3,  // 1-5
  "messages": [5, 12]
}
```

### Engagement Assessment

**Multi-dimensional:**
- Elaboration depth
- Emotional expression
- Self-disclosure
- Active vs passive responding

**Better than single score:** Break into subscores.

### Sequence Detection

**Pattern:** A → B temporal patterns.

**Format:**
```json
{
  "pattern": ["therapist_reflection", "user_deeper_share"],
  "instances": [
    {"start": 3, "end": 4},
    {"start": 10, "end": 11}
  ],
  "confidence": "high"
}
```

## Schema Validation

**Always test schema validity:**

```bash
# Use JSON Schema validator
python -m jsonschema -i output.json schema.json
```

**Common schema errors:**
- Missing required fields
- Wrong types (string instead of number)
- Values outside enum constraints
- Array items don't match item schema

**Prevention:** Embed schema in prompt with example output.

## Cost Optimization

**From production experience:**

**Expensive patterns:**
- Very long prompts (>10k tokens)
- Many examples in prompt
- Requesting extensive explanations

**Cheaper alternatives:**
- Concise criteria instead of many examples
- Optional detailed explanations (only when confidence is low)
- Split long analyses into stages

**Rule of thumb:**
- Simple detection: ~$0.05-0.15 per session
- Complex analysis with reasoning: ~$0.30-0.50 per session

## When to Use Two-Step Analysis

**Pattern from Luka's work:**
1. **Reasoning step (GPT-5):** Deep analysis → markdown output
2. **Formatting step (GPT-4.1-mini):** Markdown → structured JSON

**Use when:**
- ✅ Complex reasoning required (nuanced signals, ambiguous cases)
- ✅ High accuracy more important than cost
- ✅ Want to see LLM's reasoning process

**Skip when:**
- ❌ Simple binary detection (yes/no)
- ❌ Cost is primary concern
- ❌ Speed matters more than depth

## Final Checklist

Before saving an analysis definition:

- [ ] Prompt requires message number references
- [ ] Clear criteria with positive AND negative examples
- [ ] Output schema defined explicitly in prompt
- [ ] Tested on at least 3 diverse sessions
- [ ] False positive rate acceptable (<20%)
- [ ] Output consistently matches schema
- [ ] Evidence can be traced to actual messages
- [ ] Results are actionable and interpretable

## Resources

- `examples/alliance-detection.md` - Full example of signal detection
- `examples/issue-detection.md` - Hierarchical classification pattern
- `examples/engagement-rating.md` - Assessment scoring approach
- `examples/sequence-detection.md` - Temporal pattern matching
- `schema-guide.md` - Output schema design patterns
