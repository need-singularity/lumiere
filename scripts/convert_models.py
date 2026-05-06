#!/usr/bin/env python3
"""Convert pretrained vision models to Core ML INT8 .mlpackage.

Per spec §13 BOM (camera-filter-app + hexa-parallel-self), the runtime
inference stack uses three pretrained models, all quantized INT8:

  * resnet50    — torchvision ResNet-50 ImageNet classification backbone
  * clip_image  — openai/CLIP ViT-B/16 image encoder (512-dim latent;
                  Mirror identity-axis embedding source)
  * sam         — facebookresearch/segment-anything ViT-B mask decoder

Usage:
  scripts/convert_models.py resnet50    --out Models/ResNet50_INT8.mlpackage
  scripts/convert_models.py clip_image  --out Models/CLIP_Image_INT8.mlpackage
  scripts/convert_models.py sam         --out Models/SAM_ViT_B_INT8.mlpackage

Requires (one-time per maintainer machine; not in CI):
  pip install coremltools torch torchvision
  pip install git+https://github.com/openai/CLIP.git           # for clip_image
  pip install git+https://github.com/facebookresearch/segment-anything.git

Output sizes (approximate, INT8):
  ResNet-50         ~25 MB  → Models/
  CLIP-Image ViT-B  ~85 MB  → Models/  (git-ignored, ship via App Store
  SAM ViT-B         ~95 MB  → Models/   asset catalog or on-demand fetch)

camera.cond.2 + parallel_self.cond.2 closure depends on these outputs
landing in Models/. See Models/README.md for distribution policy.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def _quantize_int8(mlmodel):
    """Apply INT8 weight quantization via coremltools.optimize.coreml.

    Spec §13 Block C requires INT8 to keep CLIP+SAM+ResNet-50 stack
    within the 17.5 TOPS NPU budget × Roofline 50 FLOPs/byte ceiling.
    """
    from coremltools.optimize.coreml import (
        OpLinearQuantizerConfig,
        OptimizationConfig,
        linear_quantize_weights,
    )
    op_config = OpLinearQuantizerConfig(mode="linear_symmetric", weight_threshold=512)
    config = OptimizationConfig(global_config=op_config)
    return linear_quantize_weights(mlmodel, config=config)


def convert_resnet50(out_path: Path) -> None:
    import torch
    import torchvision.models as models
    import coremltools as ct

    model = models.resnet50(weights=models.ResNet50_Weights.DEFAULT).eval()
    example = torch.randn(1, 3, 224, 224)
    traced = torch.jit.trace(model, example)

    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=example.shape, scale=1 / 255.0)],
        compute_precision=ct.precision.FLOAT16,
        minimum_deployment_target=ct.target.iOS18,
    )
    mlmodel = _quantize_int8(mlmodel)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    mlmodel.save(str(out_path))
    size_mb = sum(f.stat().st_size for f in out_path.rglob("*") if f.is_file()) / 1e6
    print(f"✓ Wrote {out_path} (~{size_mb:.1f} MB)")


def convert_clip_image(out_path: Path) -> None:
    raise NotImplementedError(
        "CLIP image branch conversion: pip install git+https://github.com/openai/CLIP.git, "
        "load ViT-B/16, trace the .visual module on a (1,3,224,224) tensor, "
        "ct.convert with ImageType input + 512-dim FloatType output, then "
        "apply _quantize_int8(). Mirror (hexa-parallel-self) consumes the "
        "512-dim CLIP-Image latent for identity-axis steering."
    )


def convert_sam(out_path: Path) -> None:
    raise NotImplementedError(
        "SAM mask-decoder conversion: pip install "
        "git+https://github.com/facebookresearch/segment-anything.git, "
        "load sam_vit_b_01ec64.pth, trace the mask predictor "
        "(point + box prompt → mask), ct.convert with multi-input "
        "(image + prompt) + mask output, then _quantize_int8(). Camera "
        "uses SAM masks to spatially scope filter application "
        "(content-aware filtering)."
    )


CONVERTERS = {
    "resnet50": convert_resnet50,
    "clip_image": convert_clip_image,
    "sam": convert_sam,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("model", choices=list(CONVERTERS.keys()))
    parser.add_argument(
        "--out",
        type=Path,
        required=True,
        help="output .mlpackage path (parent dirs auto-created)",
    )
    args = parser.parse_args()
    try:
        CONVERTERS[args.model](args.out)
    except NotImplementedError as e:
        print(f"⚠ {args.model}: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
