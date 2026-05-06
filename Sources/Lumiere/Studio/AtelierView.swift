import SwiftUI

/// hexa-vsco surface — EDITS · LIBRARY · DISCOVER verb.
/// mk3-C ships the structural runtime: AtelierLibrary 50-inaugural
/// observable, PhysicsTool 7-case enum, RecipeShareCodec live demo.
/// Full editor (HSL panel / tone curve UI / Recipe Studio / Discover
/// tab / Free vs Pro tier) lands at `vsco.cond.2` (mk4).
struct AtelierView: View {
    @StateObject private var library = AtelierLibrary()
    private let physicsTools: [PhysicsTool] = PhysicsTool.allCases

    private let demoRecipe = "color_matrix ∘ vignette(0.3) ∘ grain(0.2)"

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .frame(width: 28)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(library.count) inaugural filters").font(.body)
                        Text("Forge-grammar recipes · F-VSCO-MVP-2 ≥ 50 ✓")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("mk3").font(.caption2.monospaced()).foregroundStyle(.green)
                }
            } header: {
                Text("Library")
            } footer: {
                Text("vsco.cond.3 — auto-gen from N=5 ref pairs lands at mk4 (filter_algebra.cond.3)")
                    .font(.caption2.monospaced())
            }

            Section {
                ForEach(physicsTools) { tool in
                    HStack {
                        Image(systemName: tool.symbol)
                            .frame(width: 28)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tool.displayName).font(.body)
                            Text(tool.anchor).font(.caption2.monospaced()).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("mk4").font(.caption2.monospaced()).foregroundStyle(.tertiary)
                    }
                    .opacity(0.7)
                }
            } header: {
                Text("7 physics tools (mk4 kernel impls)")
            } footer: {
                Text("vsco.cond.5 — CIFilter/Metal kernel lands at mk4")
                    .font(.caption2.monospaced())
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input recipe")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                    Text(demoRecipe)
                        .font(.body.monospaced())
                    Text("RecipeShareCodec.encode →")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    Text(RecipeShareCodec.encode(demoRecipe).absoluteString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.tint)
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Text("→ decode roundtrip")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    Text(roundTripped)
                        .font(.body.monospaced())
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Recipe URL share-load (live runtime · mk3-C)")
            } footer: {
                Text("vsco.cond.4 + F-VSCO-MVP-3 — codec ships, 1000-transaction reliability test is mk4")
                    .font(.caption2.monospaced())
            }

            Section {
                placeholderRow(
                    icon: "person.2",
                    title: "Discover",
                    subtitle: "70% creator royalty marketplace (vsco.cond.6 · mk5)"
                )
                placeholderRow(
                    icon: "creditcard",
                    title: "Free vs Pro tier gate",
                    subtitle: "vsco.cond.2 · mk4"
                )
            } header: {
                Text("Studio · Discover · Tiers (mk4+)")
            }
        }
    }

    private var roundTripped: String {
        let url = RecipeShareCodec.encode(demoRecipe)
        switch RecipeShareCodec.decode(url) {
        case .success(let s): return s
        case .failure(let e): return "decode error: \(e)"
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
