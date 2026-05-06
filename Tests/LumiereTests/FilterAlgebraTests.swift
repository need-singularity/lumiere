import Testing
import CoreImage
import Foundation
@testable import Lumiere

@Suite("FilterAlgebra — primitives + composition + Recipe parser")
struct FilterAlgebraTests {

    @Test("9 primitive operations declared per spec §7")
    func ninePrimitives() {
        #expect(FilterPrimitive.allCases.count == 9)
    }

    @Test("Recipe round-trip (parse -> serialize) preserves the token order")
    func recipeRoundTrip() {
        let input = "color_matrix ∘ vignette ∘ grain"
        switch RecipeParser.parse(input) {
        case .success(let comp):
            #expect(comp.serialize() == input)
        case .failure(let err):
            Issue.record("expected success, got \(err)")
        }
    }

    @Test("Recipe parser accepts spec sample `portra ∘ vignette(0.3) ∘ grain(0.2)`")
    func recipeSpecSample() {
        let input = "portra ∘ vignette(0.3) ∘ grain(0.2)"
        switch RecipeParser.parse(input) {
        case .success(let comp):
            #expect(comp.kernels.count == 3)
            // `portra` is sugar for `color_matrix` at mk3-C.
            #expect(comp.kernels[0].primitive == .colorMatrix)
            #expect(comp.kernels[1].primitive == .vignette)
            #expect(comp.kernels[2].primitive == .grain)
        case .failure(let err):
            Issue.record("expected success, got \(err)")
        }
    }

    @Test("Unknown primitive returns RecipeParseError.unknownPrimitive")
    func unknownPrimitiveFails() {
        let result = RecipeParser.parse("color_matrix ∘ not_a_primitive")
        switch result {
        case .success:
            Issue.record("expected failure for unknown primitive")
        case .failure(let err):
            #expect(err == .unknownPrimitive("not_a_primitive"))
        }
    }

    @Test("Empty Recipe returns RecipeParseError.empty")
    func emptyRecipeFails() {
        let result = RecipeParser.parse("   ")
        switch result {
        case .success:
            Issue.record("expected failure for empty input")
        case .failure(let err):
            #expect(err == .empty)
        }
    }

    @Test("Composition application is associative for ColorMatrix kernels")
    func colorMatrixAssociative() {
        // (a ∘ b) ∘ c == a ∘ (b ∘ c) ; mk3-C verifies at the structural
        // level — concatenating kernel lists in either grouping yields
        // the same flat sequence, which is the algebra's associativity
        // statement (spec §7 ring law L1).
        let a = ColorMatrixKernel(parameters: [:])
        let b = ColorMatrixKernel(parameters: [:])
        let c = ColorMatrixKernel(parameters: [:])

        let lhs = FilterComposition(
            kernels: FilterComposition(kernels: [a, b]).kernels + [c]
        )
        let rhs = FilterComposition(
            kernels: [a] + FilterComposition(kernels: [b, c]).kernels
        )
        #expect(lhs.kernels.count == rhs.kernels.count)
        #expect(lhs.kernels.count == 3)

        // And both lower to the same serialized recipe.
        #expect(lhs.serialize() == rhs.serialize())
    }

    @Test("FilterComposition.compose builds a chain of the expected length")
    func composeFactory() {
        let comp = FilterComposition.compose(
            ColorMatrixKernel(parameters: [:]),
            VignetteKernel(parameters: [:]),
            GrainKernel(parameters: [:])
        )
        #expect(comp.kernels.count == 3)
        #expect(comp.serialize() == "color_matrix ∘ vignette ∘ grain")
    }

    @Test("apply(to:) returns a CIImage of the same extent for an identity-ish chain")
    func applyKeepsExtent() {
        let input = CIImage(color: CIColor.red).cropped(to: CGRect(x: 0, y: 0, width: 32, height: 32))
        let comp = FilterComposition.compose(
            ColorMatrixKernel(parameters: [:])
        )
        let output = comp.apply(to: input)
        #expect(output.extent.width == 32)
        #expect(output.extent.height == 32)
    }
}
