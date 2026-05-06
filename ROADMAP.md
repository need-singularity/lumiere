# Lumière Roadmap

mk1 — pre-MVP physical-limit scaffold. Falsifier gates `F-CFA-MVP-1..5` + `F-MC-MVP-1..5` due 2026-08-30 / 2026-09-30 against iPhone 15 Pro reference.

---

## ✅ Done (2026-05-06)

| Stage | Outcome | Commit |
|---|---|---|
| Repo bootstrap | Public MIT repo at `need-singularity/lumiere`, README + LICENSE + .gitignore + spec docs/ seeds | `075e208` |
| GitHub meta | 8 topics, 2 milestones (Aug-30 / Sep-30), 3 labels, 10 F-gate issues #1–10 | — |
| Lineage | `n6-architecture/domains/apps/_standalone_repos.md` forward pointer | `04b2eed2` (n6-arch) |
| iOS scaffold | SwiftUI app with TabView (Camera + Studio), AVFoundation preview, Swift Testing, xcodegen + macOS-15 GitHub Actions CI | `982e0f2` · `fa40253` |

---

## 🚧 Next 4 stages (skipping repo-hygiene 🔧)

### 🥇 Stage A — Core ML scaffold + frame timing
**Goal**: F-CFA-MVP-1 measurement infrastructure (real-time latency p95).
- `FrameProcessor` protocol + `IdentityFrameProcessor` placeholder
- `FrameTimingRecorder` (rolling p50 / p95 over last 600 frames = 10 s @ 60 fps)
- `AVCaptureVideoDataOutputSampleBufferDelegate` wiring on background queue
- Live HUD on Camera preview showing p50 / p95 / sample count
- Tests for percentile math

### 🥈 Stage B — Studio anamorphic 2.39:1 effect
**Goal**: F-MC-MVP-1 measurement starting point (first cinematic effect of 9).
- Studio mode gets its own AVCaptureSession or shares Camera mode's
- Toggle `Anamorphic 2.39` letterbox overlay (top + bottom black bars, 2.39:1 aspect)
- CIFilter or Metal crop transform as a `FrameProcessor` impl
- Visual demo: SwiftUI overlay first; Metal pipeline after Stage A

### 🥉 Stage C — TestFlight + fastlane
**Goal**: 100-user TestFlight beta path (Phase 1 of `mk1 → mk2 EMPIRICAL` upgrade per spec §6).
- `fastlane/Fastfile` + `Appfile` for `match` + `gym` + `pilot`
- `.github/workflows/release.yml` triggered on `v*` tag
- Required repo secrets documented in `SETUP.md`:
  - `APP_STORE_CONNECT_API_KEY_{ID,ISSUER_ID,CONTENT}`
  - `DEVELOPMENT_TEAM_ID`
  - `MATCH_PASSWORD` + `MATCH_GIT_URL`
- One-time manual: Apple Developer enrollment, App ID `com.need-singularity.lumiere`, App Store Connect record

### 📊 Stage D — F-gate measurement scripts
**Goal**: Reproducible measurement of all 10 F-gates against iPhone 15 Pro reference.
- `scripts/measure_latency.swift` — XCTest signposts → p50/p95 JSON
- `scripts/measure_npu.sh` — `xctrace` Instruments NPU sampling
- `scripts/measure_jpeg_size.swift` — encode 100 sample images at qf 85
- `scripts/measure_energy.sh` — `MetricKit` energy diagnostic capture
- `docs/measurements/F-CFA-MVP-{1..5}.md` + `docs/measurements/F-MC-MVP-{1..5}.md` templates
- `workflow_dispatch` CI hook to run measurement suite on demand
- Each issue #1–10 gets a final measurement comment closing or escalating the gate

---

## 🔭 Beyond mk1 (mk2 + 100-user beta)

- Real Core ML model (CLIP+SAM+ResNet-50 INT8 stack per spec)
- Sister apps-axis domains may join later: `hexa-filter-algebra`, `hexa-parallel-self`, `hexa-vsco`
- mk2 promotion criterion: F-CFA-MVP + F-MC-MVP all 10 gates closed `does-not-fire` per spec §6 EVOLVE
- App Store public release is mk3 (post-empirical 100-user validation)

---

## 🚫 Explicitly out of scope

- 🔧 branch protection / PR templates / CODEOWNERS — deferred (single-maintainer phase)
- Android / cross-platform — iOS-only by design (Apple A17 Pro + Core ML 8 anchor)
- Cloud inference — on-device only (per spec privacy anchor)

---

*Updated 2026-05-06.*
