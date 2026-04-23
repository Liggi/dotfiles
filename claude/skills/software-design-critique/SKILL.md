---
name: software-design-critique
description: Critique code, APIs, architecture, or design proposals using Ousterhout's "A Philosophy of Software Design" (complexity, deep modules, information leakage, red flags). Use when user asks to review design or evaluate structural decisions.
---

# Software Design Critique (Ousterhout's Philosophy)

Apply John Ousterhout's design philosophy from "A Philosophy of Software Design" to evaluate code, APIs, architecture, or design proposals.

## When to Use

Invoke when user requests:
- "Review this design"
- "Critique this code/API"
- "Check for design red flags"
- "Analyze complexity"
- "Is this well-designed?"
- "Apply Ousterhout's principles"
- Or similar requests for design evaluation

## Analysis Workflow

### 1. Determine What to Analyze

**If not specified by user, ask:**
```
What should I analyze?
1. Unstaged changes (git diff)
2. Current branch vs main (git diff main...HEAD)
3. Specific files/modules (you specify)
4. A design proposal (describe it)
```

**If analyzing code changes:**
- Use git diff to see what changed
- Understand before/after state
- Focus on design impact, not just syntax

### 2. Determine Appropriate Scope

Based on what's being analyzed, apply principles at the right level:

**Code-level** (classes, methods, functions):
- Module depth
- Information hiding
- Error handling
- Naming precision

**API-level** (interfaces, service boundaries):
- Interface size vs value
- General vs special-purpose
- Complexity location (up/down)
- Temporal decomposition

**Architecture-level** (services, components):
- Abstraction layers
- Dependencies and coupling
- What matters (emphasis)
- Information leakage across boundaries

**Design proposals** (not yet code):
- Interface design (design it twice)
- Complexity strategy
- Error model
- What's being hidden/exposed

### 3. Apply Ousterhout's Principles

Use these as lenses for analysis:

**Core Principles:**
1. **Minimize complexity** - Is this making the system harder to understand/modify?
2. **Deep modules** - Small interface, lots of functionality hidden?
3. **Information hiding** - Are implementation details leaking?
4. **Pull complexity downward** - Who suffers: module author or all callers?
5. **General-purpose (within reason)** - Is this too specific or appropriately general?
6. **Define errors out of existence** - Could we eliminate this error case?
7. **Decide what matters** - Is this organized around what's important?

**Red Flags to Check:**
- ☐ Shallow module (big interface, little value)
- ☐ Information leakage (design decision appears in multiple places)
- ☐ Temporal decomposition (API mirrors execution order)
- ☐ Overexposure (users must learn internals for common use)
- ☐ Pass-through methods/variables (just forwarding)
- ☐ Repetition (same logic multiple places)
- ☐ Special-general mixture (general mechanism polluted with special cases)
- ☐ Conjoined pieces (can't understand one without the other)
- ☐ Vague/hard-to-name entities
- ☐ Comments repeat code or are missing for non-obvious aspects

### 4. Provide Narrative Analysis

**Structure:**

**1) What Matters Here**
Identify the core design decision or central concern. What's the leverage point?

**2) Red Flags Observed**
Call out specific issues with references to code/design:
```
❌ Pass-through pattern in ServiceWrapper
   - Takes 5 params, forwards all to wrapped service
   - Adds no value, just noise in call chain
   - See: src/services/wrapper.ts:42-55
```

**3) Complexity Analysis**
Where is complexity located? Who pays the cost?
- Change amplification: Would small changes require many edits?
- Cognitive load: Must caller know too much?
- Unknown unknowns: Are there hidden dependencies?

**4) Depth Assessment**
For key modules/interfaces:
- Interface size: How much must caller learn?
- Value provided: What does it hide? What can you do?
- Balance: Is this deep (good) or shallow (bad)?

**5) Specific Recommendations**
Actionable improvements with rationale:
```
✅ Recommendation: Collapse ServiceWrapper into Service

   Rationale: Pass-through methods create shallow layers with no
   abstraction benefit. Direct Service interface would be simpler.

   Impact: -50 LOC, -1 file, clearer call paths
```

**6) What's Working Well**
Don't just critique - highlight good design decisions:
```
✅ ErrorHandler.normalize() defines errors out of existence
   Multiple error types → single RecoverableError
   Callers handle one case instead of five
```

### 5. Prioritize by Impact

**Emphasize issues that:**
- Would cause change amplification
- Create high cognitive load
- Hide important things or expose unimportant things
- Make future changes risky

**De-emphasize:**
- Style nitpicks
- Theoretical problems with no evidence
- Minor naming quibbles
- Optimization without measurement

## Analysis Principles

**Be specific:**
- Reference actual code with line numbers
- Quote relevant sections
- Show concrete before/after examples

**Be constructive:**
- Explain *why* something is a problem
- Suggest *how* to improve it
- Acknowledge tradeoffs

**Be balanced:**
- Note what's well-designed
- Distinguish major vs minor issues
- Consider context (prototypes vs production)

**Think in systems:**
- Who pays the complexity cost?
- What would make this obvious?
- Where does knowledge live?
- What would future changes look like?

## Focus Areas (If User Specifies)

User can request targeted analysis:

**"Check module depth"**
→ Focus on interface size vs value, information hiding

**"Look for complexity pushup"**
→ Focus on config, options, error handling pushed to callers

**"Review error handling"**
→ Focus on error definition, masking, aggregation

**"Check for red flags"**
→ Systematic scan of all 12 red flags

**"Design it twice analysis"**
→ Suggest alternative designs, compare interfaces

**"Naming review"**
→ Precision, consistency, mental model clarity

**"Comment quality"**
→ Are non-obvious aspects documented? Do comments add value?

## Git Diff Analysis Tips

When analyzing changes:

**Look for:**
- New abstractions (are they deep?)
- Changed interfaces (complexity up or down?)
- Repeated patterns (missing abstraction?)
- Error handling changes (defined away or pushed up?)
- Documentation (added for non-obvious?)

**Ask:**
- Is this change making the system more or less obvious?
- Who will pay the cost of this complexity?
- What would break if requirements change?
- Can you understand this without reading multiple files?

## Examples of Good Critique

**Example 1: API Design**
```
❌ fetchUserData() forces temporal decomposition

The API requires callers to:
1. Call validateToken()
2. Call fetchUserData(token)
3. Call parseUserResponse(data)

Problem: Knowledge about the token→data→parse sequence is
now in every caller. If we add caching or change validation,
all callers must change.

✅ Recommendation: Hide sequence in getUserData(userId)

Let the module handle token validation, fetching, parsing
internally. Caller just wants user data, doesn't care how.

Depth: Current = shallow (3 methods, 0 value hiding)
       Proposed = deep (1 method, hides 3 steps + future changes)
```

**Example 2: Error Handling**
```
✅ RetryPolicy.execute() defines errors out of existence

Old: Every caller manually implemented retry + backoff
     5 places with slightly different logic
     Transient failures → visible errors callers must handle

New: RetryPolicy wraps operations, handles transient failures
     Callers get: success, or truly unrecoverable failure
     Complexity pulled down, error case eliminated for common failures

This is exactly the "define errors out of existence" pattern.
Well done.
```

## Quick Reference: Ousterhout's Heuristics

**Deep modules:**
- Small/simple interface
- Lots of functionality behind it
- Hides decisions likely to change

**Pull complexity down:**
- Simple interfaces > simple implementations
- Fewer knobs, better defaults
- Module author suffers so users don't

**General-purpose (somewhat):**
- Fits multiple uses with sensible defaults
- Not hyper-specific to one case
- Not over-generalized either

**Define errors out:**
- Design away (idempotent, empty is valid)
- Mask at low level (retry, absorb)
- Aggregate multiple modes → one
- Crash if truly unrecoverable

**Design it twice:**
- Sketch ≥2 different designs
- Compare interface simplicity
- Pick simpler, more general one

**Comments = design:**
- Document non-obvious
- What/why, not how
- Units, invariants, error behavior

**Decide what matters:**
- Organize around what's important
- Minimize what isn't
- Emphasize in interfaces/names/docs

## Remember

Software design is about **making systems obvious and easy to change**.

Focus on:
- Who pays complexity cost?
- Can you understand this without reading multiple files?
- Would small requirements change cause large code changes?
- Is important stuff emphasized, unimportant stuff hidden?

The goal isn't perfect code—it's code that reveals its intent and hides its complexity behind clean interfaces.
