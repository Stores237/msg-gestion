# Releasing MSG

MSG is developed and powered by **STORES** (mark: the letter **S**). The signature "Propulsé
par STORES" and the version appear on the app's login screen, at the bottom of Mon compte, and
in the back-office (sidebar and login page). `/healthz/` reports the server's version and the
deployed commit.

## Version numbers

One version for the whole platform, `MAJOR.MINOR.PATCH`, plus a build number for each APK.

| Where | What | Example |
|---|---|---|
| `app/pubspec.yaml` → `version:` | `X.Y.Z+BUILD`: the app's version and build number | `0.1.0+18` |
| `backend/config/version.py` → `VERSION` | `X.Y.Z` only, the same as the app | `0.1.0` |

- **BUILD** goes up by 1 for **every** APK handed to anyone, never reused, never reset (Android
  refuses to install a lower build over a higher one). Builds 1–17 were numbered on the command
  line; from build 18 the number lives in `pubspec.yaml`.
- **PATCH** (`0.1.0` → `0.1.1`): fixes only. **MINOR** (`0.1.x` → `0.2.0`): new features or a
  server change the app depends on. **MAJOR**: the first public release (`1.0.0`) and breaking
  changes after it.
- `backend/apps/core/test_version.py` fails if `VERSION` and the pubspec version differ: bump
  both in the same commit.
- The app shows `Version X.Y.Z (BUILD)`; the back-office shows `MSG X.Y.Z · <commit>`.

## Building the next APK

1. **Bump** `app/pubspec.yaml` (`+BUILD` always; `X.Y.Z` when it changes) and, if `X.Y.Z`
   changed, `backend/config/version.py`.
2. **Test** both sides:
   - `cd backend && .venv/bin/ruff check . && .venv/bin/python -m pytest -q`
   - `cd app && flutter analyze && flutter test`
3. **Record** the changes in `BETA_CHANGES.md` (one numbered section, with how to verify).
4. **Commit and tag**: `git commit` (message says the version), then
   `git tag app-X.Y.Z-buildN && git push && git push --tags`.
5. **Build** (the version comes from `pubspec.yaml`; don't pass `--build-number`):

   ```sh
   cd app
   tool/build_apk.sh            # staging; or: tool/build_apk.sh https://<production>/api
   ```

   It runs `flutter build apk --release --dart-define=API_BASE_URL=…` and fails if that address
   is not inside the APK. Never run a bare `flutter build apk`: without the address the app
   talks to the emulator's `10.0.2.2` and every phone says it can't connect (builds 27 and 28,
   withdrawn 2026-10-30).

   Production: the production API URL instead (`RENDER_PRODUCTION.md`). The release key is
   `app/android/key.properties` + `app/android/keystore/` (git-ignored; back them up).
6. **Publish** for testers: copy `build/app/outputs/flutter-apk/app-release.apk` to
   `~/msg-beta/msg-X.Y.Z-buildN.apk`, update `~/msg-beta/index.html` (version and file name),
   serve and tunnel it (`python3 -m http.server 8790` + `cloudflared tunnel --url
   http://127.0.0.1:8790`), and check the download's SHA-256 matches the file three times.
7. **Check** on a phone: login screen and Mon compte show `Version X.Y.Z (N)`.

## Deploying the server

Render deploys `main` (manual deploy). After it:

- `curl https://msg-staging.onrender.com/healthz/` → `{"status": "ok", "version": "X.Y.Z",
  "commit": "<short sha>"}`; the commit must be the one you deployed. If it isn't, the new
  container didn't start: read the `[start …]` markers in Render's Logs (`RENDER_STAGING.md` §5).
- The back-office footer shows the same version and commit.
- When a release needs the new server (new fields, new endpoints), deploy the server **before**
  handing out the APK.
