# Next.js dev server troubleshooting

## Cache corruption after hot reload

**Symptom:** Chunk 404 errors, missing modules, or mysterious hot-reload failures that don't match the actual code.

**Fix:** Delete `.next` and restart the dev server.

```bash
rm -rf .next && npm run dev   # or pnpm dev / yarn dev
```

Try this **early** when debugging weird Next.js dev behavior — it resolves a surprising percentage of "my code looks right but nothing works" situations. Cheaper than tracing through webpack/turbopack internals.

## When this doesn't help

If the issue persists after a clean `.next`:
- Check `node_modules` — a partial install can produce similar symptoms; `rm -rf node_modules && <install>`
- Check for package manager mismatch (pnpm vs npm lockfiles in the same repo)
- Check `next.config.*` for experimental flags recently changed
