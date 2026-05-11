<!-- @created: 2026-05-12 -->
<!-- @sister: LATTICE_POLICY.md §1.2 -->
---
project: lumiere
domain: iOS app absorbing CANON's apps axis — 5 surfaces (Camera+Mirror+Studio+Atelier+Forge) under 16.67 ms hard real-time budget and Airy diffraction limit
limits_audited: 8
breakthrough_candidates: 3
hard_walls: 4
soft_walls: 3
unclear: 1
---

# LIMIT_BREAKTHROUGH.md — lumiere

## §1 Domain identification

Lumière is a physical-limit-anchored iOS camera/studio app. Five verb-distinct
surfaces — Camera (APPLIES), Mirror (GENERATES), Studio Director (DIRECTS),
Studio Atelier (EDITS · LIBRARY · DISCOVER), Forge (AUTHORS) — collapse into
2 iOS tabs. The README is unusually explicit about which real physical
limits anchor the design: 16.67 ms hard real-time budget (60 fps Nyquist),
17.5 TOPS compute budget (50% A17 Pro headroom), 50 FLOPs/byte Roofline, Airy
diffraction θ_min = 1.22 λ/D, Poisson photon shot noise √N, Wallace 1991 JPEG,
Rec.2020 gamut, 50 mJ/frame energy ceiling.

This is the *cleanest* of the 7 repos for limit analysis — the project's own
README already names the binding physical limits. The audit's job is to (a)
confirm which are HARD vs SOFT, (b) identify breakthrough vectors where the
project does NOT already sit at the wall, (c) flag any over-claim.

mk4 is shipped with 25 falsifier gates (5 per mode) targeting iPhone 15 Pro
reference; deadlines 2026-08-30 / 2026-09-30. mk5 is gated on external
blockers (Apple Developer enrollment, device delivery, weight conversion).

## §2 Real limits applicable to this project

| # | Limit | Class | Source / value | Applicability to lumiere |
|---|-------|-------|----------------|--------------------------|
| L1 | 60 fps frame budget (Nyquist) | physics / engineering | 1000/60 = 16.67 ms hard real-time per frame | The headline hard wall — already pinned at p95 ≤ 16.67 ms for Camera mk1. |
| L2 | Airy diffraction limit | physics | θ_min = 1.22 λ/D; for λ = 550 nm, D = 5.7 mm (iPhone) → 1.43 μrad | Bounds achievable lens resolution; iPhone 15 Pro f/1.78 is already at or near the wall. |
| L3 | Poisson photon shot noise | physics | σ_shot = √N_photons | Bounds achievable SNR in low light; cannot be beaten without longer exposure (motion blur) or larger pixel pitch (sensor size). |
| L4 | Roofline (compute-vs-memory) | physics / engineering | 50 FLOPs/byte × 51.2 GB/s LPDDR5 = 2.56 TFLOPs at memory roof; A17 NPU 35 TOPS | At 17.5 TOPS budget (50% A17 NPU), Roofline binds before NPU saturates for memory-heavy ops. |
| L5 | Energy budget per frame | physics / engineering | 50 mJ/frame = 3 W × 16.67 ms | Thermal-throttle wall: sustained 3 W with 50 mJ/frame is iPhone-handheld sustainable. |
| L6 | Codec / colour-gamut bounds | engineering / mathematical | Wallace 1991 JPEG quality–bits curve; Rec.2020 75% of CIE 1931 visible gamut | Output-quality wall for JPEG; HEIC + raw bypass JPEG ceiling. |
| L7 | iOS / App Store throughput | engineering / regulatory | App Review median ≈ 1-2 days; TestFlight 100-internal / 10K-external | TestFlight 100-user cohort is an explicit `release.cond.4` blocker. |
| L8 | NPU model-conversion completeness (CoreML coverage) | engineering | Subset of PyTorch ops convert to CoreML cleanly; LoRA / SD-v3 conversion non-trivial | `parallel_self.cond.2-5` mk5 blocker; SD-v3 + LoRA weight pipeline. |

(Skipped: any "5 surfaces → 2 tabs because n=6 / σ(6)=12" framing per LATTICE_POLICY.md §1.3. The 5-verb decomposition is product structure, not a limit fit.)

## §3 Per-limit breakthrough assessment

| Limit | Class | Current state | Breakthrough vector | Trigger metric |
|-------|-------|---------------|---------------------|----------------|
| L1 60 fps Nyquist | HARD_WALL | Already at 16.67 ms p95 for Camera mk1 | Widen budget = lower fps (no), or 120 fps target (requires ProMotion + 8.33 ms budget) | F-CFA-MVP gate at 8.33 ms p95 for 120 fps mode (post-mk5) |
| L2 Airy diffraction | HARD_WALL | iPhone 15 Pro hardware-bound | None on-device; only via super-resolution (multi-frame, ML) — bounded by L3 shot noise | Multi-frame SR gain ≥ +1 stop at fixed sensor |
| L3 Poisson shot noise | HARD_WALL | √N — physical quantum limit | None; only mitigated by longer exposure (motion blur) or burst-stacking | F-CFA-MVP low-light SNR ≥ √16 = 4× single-shot at burst-16 |
| L4 Roofline | BREAKABLE_WITH_TECH | 17.5 TOPS budget vs 35 TOPS A17 NPU peak | Quantize INT8 / INT4; Apple BNNS fused ops; cache atlas in unified memory | All 9 reference effects sustained at 16.67 ms p95 simultaneously |
| L5 50 mJ/frame energy | SOFT_WALL | Spec ceiling; not yet measured on device (F-gate pending) | Per-effect energy profile; disable expensive effects in low-power mode | Measured ≤ 50 mJ/frame on iPhone 15 Pro across all 9 effects |
| L6 Codec gamut | BREAKABLE_WITH_TECH | JPEG used for thumbnails; HEIC + raw for output | Default to HEIC + Rec.2020; expose raw export | 90% of saves are HEIC; raw export option in Atelier |
| L7 App Store / TestFlight | UNCLEAR | Apple Developer enrollment is manual user action | None engineering; only timing | Enrollment landed; TestFlight 100 cohort recruited |
| L8 CoreML conversion | SOFT_WALL | SD-v3 + LoRA pipeline is mk5 work | Apple coremltools 8+ now covers more ops; or distill to smaller model | SD-v3 + LoRA running on-device at acceptable latency |

## §4 Top-3 breakthrough opportunities (this project)

1. **L4 — INT8 / INT4 quantization for all 9 effects on A17 NPU.** Roofline is the binding compute limit. INT8 already cuts memory pressure 4× vs FP32; INT4 cuts another 2× where precision permits (e.g. teal-orange grading, tone mapping). This is the lever that lets all 9 effects run simultaneously inside 16.67 ms. Trigger: p95 ≤ 16.67 ms for the fullCinematic 5-effect preset *plus* 4 more concurrent.
2. **L2 + L3 — Multi-frame super-resolution to extend the Airy / shot-noise frontier.** Burst-stack with optical-flow alignment gains roughly √N in shot-noise SNR and can recover sub-pixel detail beyond single-frame Airy. Apple already does this in ProRAW; lumière's Camera mk2+ can match-or-beat. Trigger: low-light SNR +1 stop at burst-16; measurable detail beyond single-frame Airy.
3. **L5 — Energy profile per effect.** The 50 mJ/frame ceiling is asserted but not yet measured (F-gate pending). Per-effect energy instrumentation lets users (or auto-mode) drop expensive effects in Low Power Mode. Trigger: measured 50 mJ/frame budget held with full effect stack on iPhone 15 Pro.

## §5 Honest caveats (raw#10 C3)

- Lumière is the *only* repo in this batch where the README already names its physical limits explicitly — most of this audit is confirming the project's own framing. That is a good sign, not a deficiency.
- HARD walls L1, L2, L3 are real physical limits — Nyquist, Airy, Poisson. The project sits at them by design. No "breakthrough" along these axes is possible; the breakthroughs are *engineering* ones inside the boundary (multi-frame, quantization, codec choice).
- L7 (App Store) and L8 (CoreML conversion) are *external* engineering blockers, not physics — they will fall on a calendar, not on a code change.
- The "50 mJ/frame" energy ceiling is a spec, not yet a measured fact. Until F-gate measurement on iPhone 15 Pro lands, the L5 verdict is provisional.
- The 5-surfaces / 2-tabs decomposition is a product decision; this audit does NOT treat it as a real-limit fact (per LATTICE_POLICY.md §1.3).
- The audit does NOT verify any specific Swift source file or Core ML model — only the architecture-level limit picture.

## §6 References

- `LATTICE_POLICY.md` §1.2 (universal real-limits standard, 2026-05-12)
- `README.md` — Lumière physical-limit anchors, mk4 status, F-gates
- `docs/camera/`, `docs/studio/`, `docs/filter_algebra/`, `docs/parallel_self/`, `docs/vsco/`
- Nyquist (1928), Airy (1835), Wallace (1991 JPEG), Williams-Waterman-Patterson (2009 Roofline), Apple A17 Pro NPU datasheet, Apple coremltools docs, ITU-R BT.2020 (Rec.2020)
