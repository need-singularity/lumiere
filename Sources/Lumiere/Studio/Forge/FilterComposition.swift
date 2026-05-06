import CoreImage
import Foundation

/// hexa-filter-algebra composition surface (spec §7 ring laws).
///
/// A `FilterComposition` is an ordered chain of `PrimitiveOpKernel`s. Per
/// the algebra `f = a ∘ b ∘ c` reads "apply c first, then b, then a"
/// (mathematical right-to-left composition). `apply(to:)` walks the
/// stored kernels in the order required to honor that convention.
///
/// mk3-C scope: the runtime closes the algebra at the type level. The
/// rewriter (M-fuse / K-FFT-fuse / non-commute warning) and Roofline
/// scheduler are still mk4 per `.roadmap.filter_algebra` cond.2.
struct FilterComposition {
    /// Stored in **right-to-left mathematical order**, i.e., `kernels[0]`
    /// is the **outermost** primitive (applied last). Use
    /// `compose(_:)` / `RecipeParser.parse(_:)` to build instances —
    /// they preserve the spec's `f = portra ∘ vignette ∘ grain` reading.
    let kernels: [any PrimitiveOpKernel]

    init(kernels: [any PrimitiveOpKernel]) {
        self.kernels = kernels
    }

    /// Apply the composition to a CIImage. Right-to-left order: the
    /// last kernel in the array is evaluated first (innermost), and
    /// the first kernel is evaluated last (outermost).
    func apply(to image: CIImage) -> CIImage {
        var current = image
        for kernel in kernels.reversed() {
            current = kernel.process(current)
        }
        return current
    }

    /// Serialize back into the plaintext Recipe form expected by the
    /// spec (`portra ∘ vignette(0.3) ∘ grain(0.2)`-style). mk3-C ships
    /// the round-trippable token form (no parameter rendering yet —
    /// the parser also ignores parameter values in mk3-C).
    func serialize() -> String {
        kernels
            .map(\.primitive.recipeToken)
            .joined(separator: " ∘ ")
    }

    /// Convenience constructor mirroring the spec's algebra notation.
    /// `compose(a, b, c)` returns the chain that, when applied, evaluates
    /// `a(b(c(image)))` — the same as `f = a ∘ b ∘ c`.
    static func compose(_ kernels: any PrimitiveOpKernel...) -> FilterComposition {
        FilterComposition(kernels: kernels)
    }
}
