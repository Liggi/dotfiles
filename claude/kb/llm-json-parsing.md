# Parsing LLM JSON responses

LLMs frequently wrap JSON output in markdown code fences even when explicitly instructed to output raw JSON. Handle this defensively.

## The pattern

```javascript
const cleaned = content.replace(/^```json\n?|\n?```$/g, "");
const parsed = JSON.parse(cleaned);
```

## Why

- `instructor`, `response_format: json`, and structured output hints all reduce but don't eliminate fence-wrapping behavior.
- It's cheap to strip defensively and expensive to debug a failed `JSON.parse` in a pipeline that ran 500 calls.
- Also handles ` ``` ` without the `json` tag, which some models emit.

## Stronger alternative

For production pipelines, prefer provider-native structured output when available:
- Anthropic: tool use with a forced schema
- OpenAI: `response_format: { type: "json_schema", ... }`

Fall back to the regex strip only when structured output isn't available or the caller is model-agnostic.
