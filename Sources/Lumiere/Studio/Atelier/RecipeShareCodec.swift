import Foundation

/// Plaintext-Recipe ↔ URL codec for the Atelier share-load surface.
/// mk3-C ships the codec; the empirical 1000-transaction roundtrip
/// reliability test (F-VSCO-MVP-3 ≥ 95% pass rate) is mk4 once the
/// editor surface (`vsco.cond.2`) lands.
///
/// URL form: `lumiere://recipe?r=<base64url>` where `<base64url>` is
/// the UTF-8 Recipe string base64-encoded with URL-safe alphabet
/// (RFC 4648 §5: `+`→`-`, `/`→`_`, padding `=` stripped).
enum RecipeShareCodec {
    static let scheme = "lumiere"
    static let host = "recipe"
    static let queryKey = "r"

    enum CodecError: Error, Equatable {
        case malformedURL
        case missingRecipe
        case decodingFailed
    }

    /// Encode a recipe string into a `lumiere://recipe?r=<base64url>` URL.
    /// Always succeeds (URLComponents.url is non-nil for our fixed schema).
    static func encode(_ recipe: String) -> URL {
        let b64 = Data(recipe.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: queryKey, value: b64)]
        // url is force-unwrappable for our fixed schema (scheme + host + a
        // base64url query value all lie within unreserved URL chars).
        return components.url!
    }

    /// Decode a URL back into the recipe string.
    static func decode(_ url: URL) -> Result<String, CodecError> {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == scheme,
              components.host == host else {
            return .failure(.malformedURL)
        }
        guard let raw = components.queryItems?.first(where: { $0.name == queryKey })?.value,
              !raw.isEmpty else {
            return .failure(.missingRecipe)
        }
        var padded = raw
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let mod = padded.count % 4
        if mod != 0 {
            padded += String(repeating: "=", count: 4 - mod)
        }
        guard let data = Data(base64Encoded: padded),
              let str = String(data: data, encoding: .utf8) else {
            return .failure(.decodingFailed)
        }
        return .success(str)
    }
}
