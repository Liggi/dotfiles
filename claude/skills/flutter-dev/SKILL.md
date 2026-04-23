---
name: flutter-dev
description: Manage Flutter dev sessions for ash-mobile-app via tmux with hot-reload control. Use when working on the mobile app, starting/restarting the dev server, or triggering hot reload.
---

# Flutter Dev Skill

Manage Flutter development sessions for ash-mobile-app with tmux-controlled hot reload.

## When to Use

- Starting mobile app development
- After making code changes that need hot reload
- User asks to "reload", "hot reload", "start flutter"
- Working in `ash-mobile-app` directory

## Prerequisites

Before starting Flutter:

1. **Backend services** must be running:
   ```bash
   lsof -nP -iTCP:50051 -sTCP:LISTEN  # Should show java process
   ```

2. **Android emulator** - Use `Pixel_7_API34_PlayStore` (API 34 with Google Play)

3. **config.json** must exist in ash-mobile-app root (already checked in)

4. **PIN set on emulator** - Required for Google Sign-In (first-time setup only)

## Recommended AVD

Use `Pixel_7_API34_PlayStore` with system image `google_apis_playstore` for API 34.

**Why this AVD:**
- API 34 = App launches correctly (API 36 has activity resolution issues)
- PlayStore image = Full Google Play Services (required for Google Sign-In)
- State persists across restarts when closed properly

## Emulator Lifecycle

### CRITICAL: How to Close the Emulator

**✅ CORRECT: Click the X button** on the emulator window (graceful shutdown)
- Saves state properly
- PIN, accounts, and app data persist

**❌ WRONG: `adb emu kill`** (abrupt termination)
- Corrupts GMS state
- Results in FallbackHome on next boot
- Loses sign-in state

### Starting the Emulator

```bash
# Normal start (state preserved from previous session)
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_API34_PlayStore &

# First-time setup OR recovery from corruption
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_API34_PlayStore -wipe-data &
```

### Checking Emulator Health

```bash
adb -s emulator-5554 shell "dumpsys window | command grep mFocusedApp"

# Good: com.google.android.apps.nexuslauncher/.NexusLauncherActivity
# Bad:  com.android.settings/.FallbackHome (corrupted - needs wipe)
```

## Commands

### Start Dev Session

```bash
# Start emulator (if not running)
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_API34_PlayStore &

# Wait for boot, then run Flutter
flutter run --flavor development --dart-define-from-file=config.json -d emulator-5554
```

**Key flags:**
- `--flavor development` - Required! App has three flavors (development, staging, production)
- `--dart-define-from-file=config.json` - Loads local dev configuration
- `-d emulator-5554` - Target the Android emulator

### Hot Reload

After making code changes:

```bash
tmux send-keys -t flutter -l "r"
```

### Hot Restart

For changes that require full restart (state reset, provider changes):

```bash
tmux send-keys -t flutter -l "R"
```

### Stop Session

```bash
tmux send-keys -t flutter -l "q"
```

**To close emulator:** Click the X button (DO NOT use `adb emu kill`)

## Workflow

### Making Changes

1. Edit Dart files
2. Run: `tmux send-keys -t flutter -l "r"`
3. See changes in ~500ms on emulator

### When Hot Reload Isn't Enough

Use **Hot Restart** (`R`) when changing:
- Provider definitions
- Initial state
- Main app initialization
- Routes

### When Full Rebuild Needed

Kill and restart Flutter when changing:
- pubspec.yaml (dependencies)
- Native code (Android/iOS)
- Freezed classes (run `rps codegen` first)

## Troubleshooting

### FallbackHome / Black Screen on Boot

**Cause:** Emulator was closed with `adb emu kill` instead of X button, corrupting GMS state.

**Fix:** Wipe and start fresh:
```bash
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_API34_PlayStore -wipe-data &
# Then re-setup: PIN, Google account, Ash sign-in
# IMPORTANT: Close with X button to preserve state next time
```

### "Activity class does not exist"

**On API 34:** Usually means FallbackHome corruption (see above)

**On API 36:** Known incompatibility - use API 34 instead

### Google Sign-In Fails

1. Check backend is running: `lsof -nP -iTCP:50051 -sTCP:LISTEN`
2. Check PIN is set on emulator: Settings → Security → Screen lock
3. Check backend logs: `tail -50 ~/src/slingshot-ai/.logs/backend.log`

### "Gradle build failed to produce an .apk file"

Missing `--flavor development` flag.

## First-Time Setup

```bash
# 1. Start emulator with wipe (fresh state)
~/Library/Android/sdk/emulator/emulator -avd Pixel_7_API34_PlayStore -wipe-data &

# 2. Wait for boot (~45s)
sleep 45

# 3. On emulator: Set PIN (Settings → Security → Screen lock → PIN: 1234)

# 4. On emulator: Sign into Google (Settings → Accounts → Add account)

# 5. Run Flutter
cd ~/src/slingshot-ai/ash-mobile-app
flutter run --flavor development --dart-define-from-file=config.json -d emulator-5554

# 6. Sign into Ash in the app

# 7. IMPORTANT: When done, close emulator with X button (not adb emu kill)
```

After first-time setup, state persists across restarts as long as you close with the X button.

## Config Reference

**config.json for local dev:**
```json
{
  "ENVIRONMENT": "localdev",
  "BACKEND_SERVICE_HOSTNAME": "10.0.2.2",
  "BACKEND_SERVICE_PORT": 50051,
  "APP_CHECK_TOKEN_PROVIDER": "test"
}
```

- `10.0.2.2` - Android emulator's address for host machine localhost
