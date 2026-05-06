import SwiftUI

/// hexa-filter-algebra surface — AUTHORS verb.
/// mk3-C runtime scaffold landed:
///   • 9 PrimitiveOpKernel concrete structs (`Sources/Lumiere/Studio/Forge/`)
///   • FilterComposition with associative `apply(to:)` and `compose(_:)`
///   • Plaintext Recipe parser (split on `∘`, optional `(arg)`)
/// Still pending (mk4):
///   • 30-min auto-gen from N=5 reference image pairs (filter_algebra.cond.3)
///   • LPIPS ≤ 0.15 / SSIM ≥ 0.95 / PSNR ≥ 35 dB falsifier closure
///   • Roofline-bounded kernel-fusion rewriter
struct ForgeView: View {
    /// Demo Recipe round-tripped through the runtime so the view exercises
    /// `RecipeParser.parse` + `FilterComposition.serialize()` instead of
    /// rendering an empty stub.
    private let demoRecipeInput = "portra ∘ vignette(0.3) ∘ grain(0.2)"

    var body: some View {
        List {
            Section {
                primitiveRow(.colorMatrix)
                primitiveRow(.toneCurve)
                primitiveRow(.convolution)
                primitiveRow(.colorSpace)
                primitiveRow(.grain)
                primitiveRow(.histogram)
                primitiveRow(.localTone)
                primitiveRow(.vignette)
                primitiveRow(.sharpening)
            } header: {
                Text("9 primitive ops (algebra runtime · mk3-C)")
            } footer: {
                Text("filter_algebra.cond.2 — Swift FilterAlgebra runtime · partial closure")
                    .font(.caption2.monospaced())
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                    Text(demoRecipeInput)
                        .font(.body.monospaced())
                    Text("Round-tripped serialize()")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    Text(roundTrippedRecipe)
                        .font(.body.monospaced())
                        .foregroundStyle(.tint)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Recipe round-trip (live runtime demo)")
            } footer: {
                Text("RecipeParser.parse(input).map(\\.serialize) — exercises the algebra at mk3-C")
                    .font(.caption2.monospaced())
            }

            Section {
                placeholderRow(
                    icon: "wand.and.stars",
                    title: "Author from N=5 reference pairs",
                    subtitle: "30-min inverse-problem auto-gen vs VSCO's 1–2 weeks"
                )
                placeholderRow(
                    icon: "doc.plaintext",
                    title: "Recipe export",
                    subtitle: "f = portra ∘ vignette(0.3) ∘ grain(0.2)"
                )
            } header: {
                Text("Inverse problem (mk4)")
            } footer: {
                Text("filter_algebra.cond.3 + vsco.cond.3 (50 inaugural Recipes feed Atelier library)")
                    .font(.caption2.monospaced())
            }
        }
    }

    private var roundTrippedRecipe: String {
        switch RecipeParser.parse(demoRecipeInput) {
        case .success(let composition):
            return composition.serialize()
        case .failure(let error):
            return "parse error: \(error)"
        }
    }

    private func primitiveRow(_ op: FilterPrimitive) -> some View {
        HStack {
            Image(systemName: op.symbol)
                .frame(width: 28)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(op.name).font(.body)
                Text(op.anchor).font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            Text("mk3").font(.caption2.monospaced()).foregroundStyle(.tertiary)
        }
    }

    private func placeholderRow(icon: String, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle).font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            Text("mk4").font(.caption2.monospaced()).foregroundStyle(.tertiary)
        }
        .opacity(0.7)
    }
}
