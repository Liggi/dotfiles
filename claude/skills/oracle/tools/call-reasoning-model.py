#!/usr/bin/env python3
"""Call a frontier reasoning model via the OpenAI Responses API.

ZDR-safe: rebuilds conversation inline as a messages array. Does NOT use
`previous_response_id` (which fails on Zero Data Retention orgs).

Usage:
    # Single-turn call
    python call-reasoning-model.py \\
        --model gpt-5.5-pro \\
        --prompt /tmp/round1-prompt.md \\
        --out /tmp/round1-review.md

    # Multi-turn call (replay prior turns + new prompt)
    python call-reasoning-model.py \\
        --model gpt-5.5-pro \\
        --history /tmp/history.json \\
        --prompt /tmp/round5-prompt.md \\
        --out /tmp/round5-review.md

History file format (JSON array alternating user/assistant):
    [
      {"role": "user",      "text": "..."},
      {"role": "assistant", "text": "..."},
      ...
    ]

The new prompt is appended as a final user turn. The script saves:
    <out>            — extracted text (markdown)
    <out>.json       — full Responses API payload (for debugging / replay)
"""
import argparse
import json
import os
import sys
import time
import urllib.request
import urllib.error


def build_messages(history_path: str | None, prompt_path: str) -> list[dict]:
    messages: list[dict] = []
    if history_path:
        with open(history_path) as f:
            history = json.load(f)
        for turn in history:
            role = turn["role"]
            text = turn["text"]
            content_type = "input_text" if role == "user" else "output_text"
            messages.append({
                "role": role,
                "content": [{"type": content_type, "text": text}],
            })
    with open(prompt_path) as f:
        prompt = f.read()
    messages.append({
        "role": "user",
        "content": [{"type": "input_text", "text": prompt}],
    })
    return messages


def call(model: str, messages: list[dict], effort: str, timeout: int) -> dict:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        sys.exit("error: OPENAI_API_KEY not set")

    body = {"model": model, "input": messages, "reasoning": {"effort": effort}}
    req = urllib.request.Request(
        "https://api.openai.com/v1/responses",
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    total_chars = sum(len(m["content"][0]["text"]) for m in messages)
    print(
        f"[{time.strftime('%H:%M:%S')}] {model} effort={effort} "
        f"input={total_chars:,} chars (~{total_chars // 4:,} tokens)",
        file=sys.stderr,
    )
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode()
    except urllib.error.HTTPError as e:
        err = e.read().decode()
        sys.exit(f"HTTP {e.code}: {err}")
    dt = time.time() - t0
    print(f"[{time.strftime('%H:%M:%S')}] response in {dt:.1f}s", file=sys.stderr)
    return json.loads(raw)


def extract_text(data: dict) -> str:
    parts = []
    for item in data.get("output", []):
        if item.get("type") == "message":
            for c in item.get("content", []):
                if c.get("type") == "output_text":
                    parts.append(c.get("text", ""))
    return "\n\n".join(parts) or "(no output_text found)"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", required=True, help="e.g. gpt-5.5-pro, gpt-5-pro, o4-high")
    ap.add_argument("--prompt", required=True, help="path to markdown file with the new user prompt")
    ap.add_argument("--history", help="path to JSON array of prior {role, text} turns")
    ap.add_argument("--out", required=True, help="output path for extracted markdown text")
    ap.add_argument("--effort", default="high", choices=["low", "medium", "high"])
    ap.add_argument("--timeout", type=int, default=1800, help="seconds (default: 1800)")
    args = ap.parse_args()

    messages = build_messages(args.history, args.prompt)
    data = call(args.model, messages, args.effort, args.timeout)

    with open(args.out + ".json", "w") as f:
        json.dump(data, f, indent=2)
    text = extract_text(data)
    with open(args.out, "w") as f:
        f.write(text)

    print(f"text     -> {args.out} ({len(text):,} chars)", file=sys.stderr)
    print(f"raw json -> {args.out}.json", file=sys.stderr)
    usage = data.get("usage", {})
    if usage:
        print(f"usage    -> {json.dumps(usage)}", file=sys.stderr)


if __name__ == "__main__":
    main()
