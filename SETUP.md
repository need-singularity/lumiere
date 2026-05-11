# Lumière — one-time setup for TestFlight delivery

This guide covers the manual steps required before `.github/workflows/release.yml` can ship a build to TestFlight. None of these can be automated by Claude / fastlane — they require human action in Apple Developer / App Store Connect / a private Git remote.

Roadmap reference: [`.roadmap.release`](.roadmap.release) blockers `release.blk.1` + `release.blk.2`.

---

## 1. Apple Developer Program enrollment

- Enroll at [developer.apple.com/programs](https://developer.apple.com/programs/) — $99/yr, individual or organization.
- After enrollment, note your **Team ID** (10-char alphanumeric, e.g. `ABCDE12345`).

→ Save as repo secret `DEVELOPMENT_TEAM_ID`.

## 2. App Store Connect record

- Sign in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
- **My Apps → +** → New App.
  - Platform: **iOS**
  - Name: **Lumière**
  - Primary language: English (U.S.)
  - Bundle ID: register `com.dancinlab.lumiere` first under Certificates, Identifiers & Profiles → Identifiers, then select it here.
  - SKU: `lumiere-mk1`
  - User Access: Full Access

## 3. App Store Connect API key

- App Store Connect → **Users and Access → Keys** (App Store Connect API tab).
- Click **+** to generate a key with role **App Manager**.
- Download the `.p8` file **once** (cannot redownload). Save the **Key ID** (10 chars) and **Issuer ID** (UUID).

Encode the `.p8` for CI:

```sh
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

→ Save as repo secrets:
- `APP_STORE_CONNECT_API_KEY_ID` — the 10-char Key ID
- `APP_STORE_CONNECT_API_KEY_ISSUER_ID` — the UUID Issuer ID
- `APP_STORE_CONNECT_API_KEY_CONTENT` — base64-encoded `.p8` content

## 4. fastlane match — code signing storage

`match` keeps signing certificates and provisioning profiles in a private Git repo, encrypted with a passphrase. CI fetches read-only.

- Create a private repo for cert storage, e.g. `dancinlab/lumiere-match` (do NOT make this public).
- Generate a long random passphrase: `openssl rand -base64 32`.
- One-time on a maintainer's Mac (NOT in CI):

  ```sh
  cd ~/core/lumiere
  bundle install
  bundle exec fastlane match init     # answer git, paste private repo URL
  bundle exec fastlane match appstore # generate appstore certs + push to match repo
  ```

- For HTTPS access in CI, also generate a basic-auth token:

  ```sh
  echo -n "github-username:github-pat-with-repo-scope" | base64
  ```

→ Save as repo secrets:
- `MATCH_GIT_URL` — `https://github.com/dancinlab/lumiere-match.git`
- `MATCH_PASSWORD` — the passphrase from `openssl rand`
- `MATCH_GIT_BASIC_AUTHORIZATION` — the base64 `user:pat` blob

## 5. Repo secrets summary

After steps 1–4, GitHub repo `dancinlab/lumiere` → **Settings → Secrets and variables → Actions** must contain all six:

| Secret | Source |
|---|---|
| `DEVELOPMENT_TEAM_ID` | step 1 |
| `APP_STORE_CONNECT_API_KEY_ID` | step 3 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | step 3 |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | step 3 (base64) |
| `MATCH_GIT_URL` | step 4 |
| `MATCH_PASSWORD` | step 4 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | step 4 |

## 6. Trigger a release

Two paths:

### Tag push (recommended)

```sh
git tag v0.1.0-mk1
git push origin v0.1.0-mk1
```

GitHub Actions `Release (TestFlight)` runs `fastlane ios beta` → archive → upload → TestFlight processing.

### Manual

GitHub → Actions → **Release (TestFlight)** → **Run workflow** with optional changelog input.

## 7. mk1 → mk2 promotion

Per spec §6 EVOLVE, the `mk1 PHYSICAL-LIMIT` → `mk2 EMPIRICAL` promotion requires:
- 100-user TestFlight beta cohort with telemetry stream
- F-CFA-MVP-1..5 + F-MC-MVP-1..5 all 10 gates closed `does-not-fire` per the falsifier deadlines (2026-08-30 / 2026-09-30)

Then App Store public release becomes mk3.
