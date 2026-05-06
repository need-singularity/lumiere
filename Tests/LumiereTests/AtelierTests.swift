import Testing
import Foundation
@testable import Lumiere

@Suite("Atelier — Library + RecipeShareCodec + PhysicsTool")
struct AtelierTests {

    @Test("Inaugural library has at least 50 filters (F-VSCO-MVP-2 threshold)")
    @MainActor
    func fiftyInaugural() {
        let library = AtelierLibrary()
        #expect(library.count >= 50)
    }

    @Test("LibraryFilter IDs are unique across the inaugural set")
    @MainActor
    func uniqueIDs() {
        let library = AtelierLibrary()
        let ids = Set(library.filters.map(\.id))
        #expect(ids.count == library.count)
    }

    @Test("Every inaugural filter carries a non-empty recipe + name")
    @MainActor
    func nonEmptyMetadata() {
        let library = AtelierLibrary()
        for f in library.filters {
            #expect(!f.name.isEmpty)
            #expect(!f.recipe.isEmpty)
        }
    }

    @Test("PhysicsTool.allCases.count == 7")
    func sevenPhysicsTools() {
        #expect(PhysicsTool.allCases.count == 7)
    }

    @Test("PhysicsTool entries match the spec §10 hexa-vsco anchor list")
    func physicsToolAnchors() {
        let names = Set(PhysicsTool.allCases.map(\.displayName))
        #expect(names.contains("H&D curves"))
        #expect(names.contains("Wiener deconvolution"))
        #expect(names.contains("Cox grain"))
        #expect(names.contains("Planck WB"))
        #expect(names.contains("cos⁴θ vignette"))
        #expect(names.contains("MacAdam color ellipse"))
        #expect(names.contains("CIE 1931 observer"))
    }

    @Test("RecipeShareCodec roundtrip preserves 10 sample recipes")
    func codecRoundTrip10() {
        let samples = [
            "color_matrix",
            "color_matrix ∘ vignette",
            "color_matrix ∘ vignette(0.3)",
            "color_matrix ∘ vignette(0.3) ∘ grain(0.2)",
            "tone_curve ∘ sharpening",
            "color_space ∘ tone_curve ∘ histogram",
            "color_matrix ∘ local_tone ∘ vignette(0.5)",
            "convolution ∘ vignette(0.1) ∘ grain(0.05)",
            "color_matrix ∘ tone_curve ∘ vignette(0.25) ∘ grain(0.12)",
            "tone_curve ∘ vignette(0.4) ∘ grain(0.15)"
        ]
        for s in samples {
            let url = RecipeShareCodec.encode(s)
            let decoded = RecipeShareCodec.decode(url)
            switch decoded {
            case .success(let out):
                #expect(out == s, "roundtrip should preserve `\(s)` (got `\(out)`)")
            case .failure(let err):
                Issue.record("decode failed for `\(s)`: \(err)")
            }
        }
    }

    @Test("RecipeShareCodec.decode rejects malformed URLs")
    func codecMalformedURL() {
        let bad = URL(string: "https://example.com/?r=abc")!
        let result = RecipeShareCodec.decode(bad)
        switch result {
        case .success: Issue.record("expected failure")
        case .failure(let err): #expect(err == .malformedURL)
        }
    }

    @Test("RecipeShareCodec.decode reports missing recipe on empty query")
    func codecMissingRecipe() {
        let bad = URL(string: "lumiere://recipe?other=foo")!
        let result = RecipeShareCodec.decode(bad)
        switch result {
        case .success: Issue.record("expected failure")
        case .failure(let err): #expect(err == .missingRecipe)
        }
    }

    @Test("Encoded URL uses lumiere scheme + recipe host")
    func encodedURLShape() {
        let url = RecipeShareCodec.encode("color_matrix")
        #expect(url.scheme == "lumiere")
        #expect(url.host == "recipe")
    }
}
