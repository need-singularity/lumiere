import Foundation

/// Errors produced by `RecipeParser.parse`. mk3-C surfaces only the
/// failure modes the parser can already detect; structural malformations
/// (mismatched parens, depth > 4, etc.) gain dedicated cases at mk4.
enum RecipeParseError: Error, Equatable {
    case empty
    case unknownPrimitive(String)
    case malformedToken(String)
}

/// Plaintext Recipe parser — splits on `∘`, recognises a registered
/// primitive token + an optional `(arg)`, returns a `FilterComposition`
/// of ordered kernels. mk3-C ships the parser shell only; argument
/// **type-checking** (e.g., `vignette(0.3)` → `CGFloat`) lands at mk4
/// alongside the auto-generation pipeline (filter_algebra.cond.3).
///
/// Grammar (mk3-C subset):
///   recipe       ::= primitive ('∘' primitive)*
///   primitive    ::= ident ('(' arg ')')?
///   ident        ::= one of FilterPrimitive.recipeToken
///   arg          ::= any non-')' run (parsed but discarded in mk3-C)
struct RecipeParser {

    static let primitiveTokens: [String: FilterPrimitive] = {
        var dict: [String: FilterPrimitive] = [:]
        for p in FilterPrimitive.allCases {
            dict[p.recipeToken] = p
        }
        // Spec also names a few sugar tokens (e.g., `portra`) which expand
        // to a default Recipe at mk4. For mk3-C we accept `portra` as a
        // synonym of `color_matrix` so the hexa-doc-shaped sample
        // `portra ∘ vignette ∘ grain` round-trips through the parser.
        dict["portra"] = .colorMatrix
        return dict
    }()

    /// Parse a Recipe string. Whitespace around `∘` is ignored.
    /// Returns `.failure(.empty)` on an empty/whitespace-only string,
    /// `.failure(.unknownPrimitive)` on a token that doesn't resolve,
    /// `.failure(.malformedToken)` on a token whose paren block is
    /// unterminated.
    static func parse(_ recipe: String) -> Result<FilterComposition, RecipeParseError> {
        let trimmed = recipe.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        let parts = trimmed.split(separator: "∘", omittingEmptySubsequences: false)
        var kernels: [any PrimitiveOpKernel] = []
        for raw in parts {
            let token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { return .failure(.malformedToken(String(raw))) }

            // Split off optional "(arg)" suffix.
            let nameToken: String
            let argToken: String?
            if let openIdx = token.firstIndex(of: "(") {
                guard token.hasSuffix(")") else {
                    return .failure(.malformedToken(token))
                }
                nameToken = String(token[..<openIdx])
                let afterOpen = token.index(after: openIdx)
                let beforeClose = token.index(before: token.endIndex)
                argToken = String(token[afterOpen..<beforeClose])
            } else {
                nameToken = token
                argToken = nil
            }

            guard let primitive = primitiveTokens[nameToken] else {
                return .failure(.unknownPrimitive(nameToken))
            }

            // mk3-C: parse the arg into a single intensity-style float
            // when the token suggests one (`vignette`, `grain`); ignore
            // otherwise. Real per-primitive parameter schemas land mk4.
            var parameters: [String: Any] = [:]
            if let argToken, let value = Double(argToken.trimmingCharacters(in: .whitespaces)) {
                if primitive == .vignette {
                    parameters["intensity"] = NSNumber(value: value)
                } else if primitive == .grain {
                    parameters["intensity"] = CGFloat(value)
                }
            }

            kernels.append(primitive.makeKernel(parameters: parameters))
        }

        return .success(FilterComposition(kernels: kernels))
    }
}
