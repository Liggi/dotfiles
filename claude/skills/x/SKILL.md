---
name: x
description: "X (Twitter) API — bookmarks, search, tweet lookup, post with media, threads. Uses OAuth tokens from ~/.lattice/config.json."
argument-hint: "<command> (bookmarks, search <query>, tweet <id>, post <text>, user <@handle>, me, status, delete <id>)"
---

# X (Twitter) API Skill

Access Jason's X account via the official API v2 with OAuth 2.0 tokens.

## Helper Script

All commands go through `~/.claude/skills/x/x-api.mjs`. It reads credentials from `~/.lattice/config.json` and auto-refreshes expired OAuth tokens.

## Commands

```bash
# Check auth status and scopes
node ~/.claude/skills/x/x-api.mjs status

# Get bookmarks (default 100, max 100 per page)
node ~/.claude/skills/x/x-api.mjs bookmarks
node ~/.claude/skills/x/x-api.mjs bookmarks --count 20

# Search recent tweets (7-day window)
node ~/.claude/skills/x/x-api.mjs search "claude code" --count 10

# Look up a specific tweet by ID
node ~/.claude/skills/x/x-api.mjs tweet 2021230659616854248

# Post a tweet (text only)
node ~/.claude/skills/x/x-api.mjs post "your tweet text here"

# Post with media (image, GIF, or video)
node ~/.claude/skills/x/x-api.mjs post "tweet text" --media /path/to/file.gif

# Post as a reply (for threading)
node ~/.claude/skills/x/x-api.mjs post "reply text" --reply-to 2021230659616854248

# Post with media AND as a reply
node ~/.claude/skills/x/x-api.mjs post "tweet text" --media /path/to/image.png --reply-to <id>

# Delete a tweet
node ~/.claude/skills/x/x-api.mjs delete 2021230659616854248

# Look up a user profile
node ~/.claude/skills/x/x-api.mjs user Liggi

# Get authenticated user info
node ~/.claude/skills/x/x-api.mjs me
```

## Media Upload Details

- **Images** (PNG, JPG, WEBP): Simple upload, under 5MB
- **GIFs**: Chunked upload via dedicated v2 endpoints (`/initialize`, `/{id}/append`, `/{id}/finalize`), max 5MB
- **Videos** (MP4): Chunked upload, async processing with status polling
- Progress is logged to stderr during upload
- Required OAuth scope: `media.write` (added Feb 2026)

**GIF size tips:** If a GIF is over 5MB, shrink it with ffmpeg before uploading:
```bash
ffmpeg -y -i input.mp4 -ss 2 -t 12 -vf "fps=12,scale=600:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=96[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" -loop 0 output.gif
```
Adjust `-t` (duration), `fps`, `scale`, and `max_colors` to hit the target size.

## Posting Threads

Threads are just replies to yourself. Post the first tweet, capture its ID, then reply to each subsequent one:

```bash
# Tweet 1 (with optional media)
node ~/.claude/skills/x/x-api.mjs post "first tweet" --media /path/to/image.gif
# Capture the ID from the response → e.g., 2021230659616854248

# Tweet 2 (reply to tweet 1)
node ~/.claude/skills/x/x-api.mjs post "second tweet" --reply-to 2021230659616854248
# Capture this ID → e.g., 2021230685202137286

# Tweet 3 (reply to tweet 2)
node ~/.claude/skills/x/x-api.mjs post "third tweet" --reply-to 2021230685202137286
# And so on...
```

**If you need to redo:** Delete all tweets in the thread (bottom-up is fine), then repost.

## Drafting Tweets and Threads

**ALWAYS read the voice document first:** `~/claudia-bot/self/twitter-voice.md`

Key voice rules:
- Lowercase everything, including "i"
- No hashtags, no thread numbering (1/, 2/), no "🧵 Thread:" openers
- No performative enthusiasm, no calls to action, no corporate speak
- Short declarative sentences, fragments are fine
- Describe what you built and let it speak — don't frame it as self-promotion
- Each tweet in a thread should be a self-contained thought

**Drafting workflow:**
1. Read the voice document
2. Gather material (sessions, git history, project files — whatever's relevant)
3. Draft the thread in Jason's voice
4. Show drafts to Jason for review and iteration
5. Only post after explicit approval

**Before posting, verify:**
- No broken @ mentions (check if usernames exist with `user <handle>`)
- No project-specific jargon outsiders won't understand
- Each tweet under 280 characters
- Media is appropriately sized (GIFs under 5MB)

## Handling the User's Request

Based on `$ARGUMENTS`:

1. **"bookmarks"** or no args → Fetch bookmarks, summarize grouped by theme
2. **"search <query>"** → Search recent tweets, present results
3. **"tweet <id>"** → Look up a specific tweet
4. **"post <text>"** → CONFIRM with user before posting, then post
5. **"delete <id>"** → CONFIRM with user before deleting
6. **"user <handle>"** → Look up profile, show stats
7. **"me"** or **"status"** → Show auth/account info
8. **"draft"** or **"thread"** → Start the drafting workflow above

## Important Notes

- **Token refresh is automatic.** If expired, the script refreshes using the stored refresh token.
- **If refresh fails**, re-authorize via Lattice: `http://localhost:3001/api/x/auth/start`
- **Pay-per-use API.** Don't make unnecessary calls. Fetch once and work with the data.
- **NEVER post or delete tweets without explicit user confirmation.**
- **Max 100 bookmarks per request.** Use `meta.next_token` for pagination if needed.
- **Search only covers 7 days.** For older tweets, use the user timeline API directly.
- **Rate limits:** Media upload has low limits on free tier (17 initialize/finalize, 85 append per 24h). Don't waste uploads on test runs.
