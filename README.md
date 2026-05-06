# Lumière ✨

> 빛으로 찍고, 빛으로 연출하다 — *Capture in light, direct in light*

**Lumière** is a physical-limit iOS camera + cinematic studio app, anchored at the 16.67 ms real-time budget (60 fps Nyquist) and the Airy diffraction limit.

---

## Two modes

| Mode | Verb | Surface | Anchor |
|---|---|---|---|
| 📸 **Lumière Camera** | APPLIES | Real-time filter capture | 16.67 ms · 17.5 TOPS NPU · Roofline · Airy + Poisson |
| 🎬 **Lumière Studio** | DIRECTS | 9-effect cinematic post | 2.39:1 anamorphic · teal-orange · Lucas-Kanade slow-mo · Cox grain |

Both share the same 16.67 ms hard real-time budget and 50 mJ/frame energy ceiling.

## Physical-limit anchors

- **Real-time** — 1000/60 fps = 16.67 ms (Nyquist visual perception)
- **Compute** — 17.5 TOPS (50% of Apple A17 Pro headroom)
- **Memory** — Williams-Waterman-Patterson 2009 Roofline (50 FLOPs/byte × 51.2 GB/s DRAM)
- **Optics** — Airy 1835 diffraction limit · θ_min = 1.22 λ/D
- **Sensor** — Poisson photon shot noise · σ_shot = √N_photons
- **Codec** — Wallace 1991 JPEG · Rec.2020 wide gamut
- **Energy** — 50 mJ/frame (3 W × 16.67 ms)

## Camera mode — 9 reference effects

Anamorphic 2.39:1 · teal-orange grading · Lucas-Kanade 1981 optical-flow slow-mo · depth-bokeh · hexagonal-aperture Snell+Fresnel lens flare · Cox 1955 Kodak Vision3 5219 grain · decisive-moment freeze · Wu 2023 CLAP scene-music · Reinhard-Devlin 2002 tone

## Status

`mk1` — pre-MVP. Falsifier gates **F-CFA-MVP-1..5** + **F-MC-MVP-1..5** declared against iPhone 15 Pro reference (latency p95 / NPU utilization / JPEG size / MOS / energy per frame), deadlines **2026-08-30 / 2026-09-30**.

## Specs

- [docs/camera/camera-filter-app.md](docs/camera/camera-filter-app.md) — 21-section spec, own#15 template
- [docs/studio/hexa-main-character.md](docs/studio/hexa-main-character.md) — 21-section spec, own#15 template

## Lineage

Extracted from the [n6-architecture](https://github.com/) **apps axis** (13th axis, registered 2026-05-01) where 5 sibling domains share verb-distinction:
APPLIES (camera) · AUTHORS (filter-algebra) · GENERATES (parallel-self) · DIRECTS (studio) · EDITS-LIBRARY-DISCOVER (vsco).

Lumière is the camera ⊕ studio integration.

## Build

Prerequisites: **macOS 15+ · Xcode 26+ · iOS 18+ deployment target**

```sh
brew install xcodegen          # one-time
xcodegen generate              # regenerate Lumiere.xcodeproj from project.yml
open Lumiere.xcodeproj
```

CLI build / test:
```sh
xcodebuild -project Lumiere.xcodeproj -scheme Lumiere \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## Repo layout

```
lumiere/
├── project.yml                 ← xcodegen spec (single source of truth)
├── Sources/Lumiere/
│   ├── LumiereApp.swift        @main · SwiftUI App
│   ├── ContentView.swift       TabView (Camera / Studio)
│   ├── Camera/                 AVFoundation real-time pipeline
│   │   ├── CameraSession.swift
│   │   ├── CameraView.swift
│   │   └── CameraPreviewView.swift  UIViewRepresentable
│   ├── Studio/
│   │   └── StudioView.swift    9 cinematic effects (mk1 placeholder)
│   └── Assets.xcassets/        AppIcon · AccentColor
├── Tests/LumiereTests/         Swift Testing
│   ├── CinematicEffectTests.swift
│   └── PhysicalLimitTests.swift
├── docs/
│   ├── camera/camera-filter-app.md
│   └── studio/hexa-main-character.md
└── .github/workflows/ios.yml   GitHub Actions (build + test)
```

`Lumiere.xcodeproj` is git-ignored — regenerated from `project.yml` on every build.

## License

MIT — see [LICENSE](LICENSE).
