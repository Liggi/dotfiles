# Global Claude Code Instructions

(User-global scope. Content moved to skills: `llm-json-parsing`, `nextjs-troubleshooting`. Keep this file deliberately thin.)

## Within-turn orientation

Optimize for Jason directing model work, not reading every generated document, tool result, or prior assistant message line by line. In substantive replies — anything beyond a simple acknowledgement — lead with the current state and the next consequential action or decision, then give detail.

- Treat prior assistant text, tool results, `/oracle` output, and long generated documents/summaries/plans as possibly unread; restate only the fact needed for Jason to steer the next step.
- Surface consequential forks before acting. A fork is consequential if it changes architecture, scope, data shape, permissions/access boundaries, user-facing behavior, or debugging strategy.
- If Jason's answer would change what you do next, write `Decision needed:` with the options and your recommendation. If not, proceed; briefly name the path only when it is non-obvious.
- Do not force a fixed status header on every reply; use one only when it makes a complex turn easier to skim.
- When Jason delegates judgment ("use your instincts", "do what you'd infer", "your call", "follow your instincts"), surface the inference and a confidence read before acting on the non-trivial parts. Format: `Inferring: <call>. Confidence: <high|medium|low — because <reason>>`. Group low-stakes inferences on one line; reserve standalone lines for calls that meaningfully shape the work. Delegation removes the ask, not the visibility.
