# TAPE-AUDIT — lumiere

**Date:** 2026-05-14 · **Lens:** `.tape` (typed events) — per spec "likely measurement pilot tapes" for physical-limit camera.

## A. Audit-class ledgers

**No `state/` markers directory** — distinct from every other repo in this audit (which all carry the dancinlab boot-hook marker cargo). No `.jsonl`, no `.hook-audit*`, no audit scripts. 6 `.roadmap.{camera,filter_algebra,parallel_self,release,studio,vsco}` design files — structured roadmap text, not event ledger. The only audit-shaped surface.

## B. Identity surface

`hexa.toml` no `[identity]`. **Real iOS/Xcode app** (`Lumiere.xcodeproj`, `Sources/Lumiere/`, `Tests/`, `fastlane/`, `Models/`, `project.yml`) — identity is the app bundle, not a swarm identity.

## C. Domain.md files

**1 UPPERCASE.md** — `SETUP.md`. Per spec convention not really adopted.

## D. Per-run / per-event history

**`docs/measurements/`** — the distinct surface: `F-CFA-MVP-1.md` through `F-CFA-MVP-5.md` + `F-MC-MVP-1.md` through `F-MC-MVP-5.md` + `_template.md` + `README.md`. These are **per-measurement-event spec stubs** — each MVP iteration is a numbered measurement-event slot. Closest to `.tape` `@H` history shape in this audit (numbered append-only by convention). Plus dated `.roadmap.*` design ledgers (per-subsystem: camera/filter_algebra/parallel_self/release/studio/vsco).

## E. Promotion candidates

- **`.tape` `@H` measurement-event stream** (HIGH per spec): `docs/measurements/F-CFA-MVP-N.md` is literally the measurement-event slot pattern — replace the per-file convention with a `LUMIERE.tape` `@H` measurement entries + `@R` results + `@?` open questions + `@D` decisions. Strongest match in this audit for "measurement pilot tape".
- **n6 atoms** (LIGHT): camera-filter-algebra n=6 (matches hexa-apps `HEXA-FILTER-ALGEBRA.md`); could be atom site.
- **hxc**: photo byte-stream encoding plausible.

## Verdict

**MEDIUM** — explicit per-measurement-event spec slot pattern (`docs/measurements/F-{CFA,MC}-MVP-1..5.md` + template) matches `.tape` `@H` measurement-event shape per spec ("likely measurement pilot tapes"). The only repo with a real app codebase (Swift/Xcode) in this audit. No live measurement ledger today but the *slot* is laid out.
