import CoreImage
import Foundation

/// hexa-filter-algebra mk3-C runtime — 9 primitive operations closed under
/// composition algebra (spec §10 Block A-G + §7 algebra ring laws).
///
/// Each primitive maps to a CIFilter (or composition of CIFilters) so the
/// Forge runtime can evaluate a `FilterComposition` end-to-end at the
/// 16.67 ms / 4-deep ceiling claimed by `.roadmap.filter_algebra` cond.2.
/// The actual NPU/GPU/ISP scheduling (Williams 2009 Roofline) and
/// inverse-problem auto-gen (cond.3) are deferred to mk4.

/// The 9 primitive operations of the filter algebra (spec §7).
/// Promoted from a `ForgeView`-private enum into the runtime layer at
/// mk3-C so kernels + composition + Recipe parser share a single SSOT.
enum FilterPrimitive: String, CaseIterable, Identifiable, Codable {
    case colorMatrix
    case toneCurve
    case convolution
    case colorSpace
    case grain
    case histogram
    case localTone
    case vignette
    case sharpening

    var id: String { rawValue }

    var name: String {
        switch self {
        case .colorMatrix: return "Color matrix (3×3)"
        case .toneCurve:   return "Tone curve (1D LUT)"
        case .convolution: return "Convolution (k×k)"
        case .colorSpace:  return "Color-space transform"
        case .grain:       return "Grain"
        case .histogram:   return "Histogram"
        case .localTone:   return "Local tone"
        case .vignette:    return "Vignette"
        case .sharpening:  return "Sharpening"
        }
    }

    var anchor: String {
        switch self {
        case .colorMatrix: return "linear · associative ✓"
        case .toneCurve:   return "function composition · associative"
        case .convolution: return "linear · associative ✓"
        case .colorSpace:  return "matrix · invertible"
        case .grain:       return "Cox 1955 · FFT match"
        case .histogram:   return "Shannon 1948 · DPI bound"
        case .localTone:   return "Reinhard-Devlin 2002"
        case .vignette:    return "cos⁴θ paraxial"
        case .sharpening:  return "unsharp mask · Wiener 1949"
        }
    }

    var symbol: String {
        switch self {
        case .colorMatrix: return "square.grid.3x3"
        case .toneCurve:   return "scribble.variable"
        case .convolution: return "square.dashed"
        case .colorSpace:  return "circle.hexagongrid"
        case .grain:       return "circle.grid.cross"
        case .histogram:   return "chart.bar"
        case .localTone:   return "sun.haze"
        case .vignette:    return "circle.dashed"
        case .sharpening:  return "rays"
        }
    }

    /// Stable lower-snake-case identifier used by the plaintext Recipe
    /// grammar (e.g., `color_matrix ∘ vignette(0.3)`).
    var recipeToken: String {
        switch self {
        case .colorMatrix: return "color_matrix"
        case .toneCurve:   return "tone_curve"
        case .convolution: return "convolution"
        case .colorSpace:  return "color_space"
        case .grain:       return "grain"
        case .histogram:   return "histogram"
        case .localTone:   return "local_tone"
        case .vignette:    return "vignette"
        case .sharpening:  return "sharpening"
        }
    }

    /// Build the matching kernel; param defaults are spec-sourced from
    /// the §10 ARCHITECTURE block.
    func makeKernel(parameters: [String: Any] = [:]) -> any PrimitiveOpKernel {
        switch self {
        case .colorMatrix: return ColorMatrixKernel(parameters: parameters)
        case .toneCurve:   return ToneCurveKernel(parameters: parameters)
        case .convolution: return ConvolutionKernel(parameters: parameters)
        case .colorSpace:  return ColorSpaceKernel(parameters: parameters)
        case .grain:       return GrainKernel(parameters: parameters)
        case .histogram:   return HistogramKernel(parameters: parameters)
        case .localTone:   return LocalToneKernel(parameters: parameters)
        case .vignette:    return VignetteKernel(parameters: parameters)
        case .sharpening:  return SharpeningKernel(parameters: parameters)
        }
    }
}

/// Kernel protocol — every primitive boils down to a `CIImage -> CIImage`
/// transform. Concrete implementations wrap the matching CIFilter.
protocol PrimitiveOpKernel {
    var primitive: FilterPrimitive { get }
    var parameters: [String: Any] { get }
    func process(_ image: CIImage) -> CIImage
}

// MARK: - Concrete kernels (CIFilter-backed)
//
// mk3-C ships pass-through-safe wrappers: each kernel attempts the
// CIFilter associated with the primitive; on `nil` parameter mismatch
// it returns the input unmodified rather than crashing. This matches
// the surrounding Studio FrameProcessor pattern (CoxGrainFrameProcessor,
// TealOrangeFrameProcessor) and keeps the algebra closed under
// composition even when a parameter is absent.

struct ColorMatrixKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .colorMatrix
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        if let r = parameters["rVector"] as? CIVector { filter.setValue(r, forKey: "inputRVector") }
        if let g = parameters["gVector"] as? CIVector { filter.setValue(g, forKey: "inputGVector") }
        if let b = parameters["bVector"] as? CIVector { filter.setValue(b, forKey: "inputBVector") }
        if let a = parameters["aVector"] as? CIVector { filter.setValue(a, forKey: "inputAVector") }
        return filter.outputImage ?? image
    }
}

struct ToneCurveKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .toneCurve
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIToneCurve") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        // 5-point default = identity curve.
        let defaults: [(String, CIVector)] = [
            ("inputPoint0", CIVector(x: 0.00, y: 0.00)),
            ("inputPoint1", CIVector(x: 0.25, y: 0.25)),
            ("inputPoint2", CIVector(x: 0.50, y: 0.50)),
            ("inputPoint3", CIVector(x: 0.75, y: 0.75)),
            ("inputPoint4", CIVector(x: 1.00, y: 1.00))
        ]
        for (key, def) in defaults {
            filter.setValue(parameters[key] as? CIVector ?? def, forKey: key)
        }
        return filter.outputImage ?? image
    }
}

struct ConvolutionKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .convolution
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        // mk3-C: select 3x3 vs 5x5 by parameter "size" (default 3).
        let size = (parameters["size"] as? Int) ?? 3
        let filterName = size >= 5 ? "CIConvolution5X5" : "CIConvolution3X3"
        guard let filter = CIFilter(name: filterName) else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        if let weights = parameters["weights"] as? CIVector {
            filter.setValue(weights, forKey: "inputWeights")
        }
        if let bias = parameters["bias"] as? NSNumber {
            filter.setValue(bias, forKey: "inputBias")
        }
        return filter.outputImage ?? image
    }
}

struct ColorSpaceKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .colorSpace
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        // CIColorCubeWithColorSpace requires both cubeData + colorSpace.
        // When neither is supplied we pass through (mk3-C scaffold).
        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        if let dim = parameters["cubeDimension"] as? NSNumber,
           let data = parameters["cubeData"] as? Data {
            filter.setValue(dim, forKey: "inputCubeDimension")
            filter.setValue(data, forKey: "inputCubeData")
            if let cs = parameters["colorSpace"] {
                filter.setValue(cs, forKey: "inputColorSpace")
            }
            return filter.outputImage ?? image
        }
        return image
    }
}

struct GrainKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .grain
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        // Cox 1955 cluster-Poisson approximated via random-noise overlay.
        let intensity = (parameters["intensity"] as? CGFloat) ?? 0.15
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator"),
              let noise = noiseFilter.outputImage?.cropped(to: image.extent),
              let alphaFilter = CIFilter(name: "CIColorMatrix") else {
            return image
        }
        alphaFilter.setValue(noise, forKey: kCIInputImageKey)
        alphaFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputRVector")
        alphaFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputGVector")
        alphaFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputBVector")
        alphaFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: intensity), forKey: "inputAVector")
        guard let scaled = alphaFilter.outputImage,
              let comp = CIFilter(name: "CISourceOverCompositing") else {
            return image
        }
        comp.setValue(scaled, forKey: kCIInputImageKey)
        comp.setValue(image, forKey: kCIInputBackgroundImageKey)
        return comp.outputImage ?? image
    }
}

struct HistogramKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .histogram
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        // CIHistogramDisplayFilter renders a histogram visualization;
        // for the algebra closure mk3-C ships the equalize-style proxy.
        guard let filter = CIFilter(name: "CIColorPolynomial") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
}

struct LocalToneKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .localTone
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        // Reinhard-Devlin 2002 photoreceptor operator surrogate via
        // CIHighlightShadowAdjust (closest stock CIFilter).
        guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        if let h = parameters["highlightAmount"] as? NSNumber {
            filter.setValue(h, forKey: "inputHighlightAmount")
        }
        if let s = parameters["shadowAmount"] as? NSNumber {
            filter.setValue(s, forKey: "inputShadowAmount")
        }
        return filter.outputImage ?? image
    }
}

struct VignetteKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .vignette
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        // cos⁴θ paraxial law — CIVignette intensity-defaults match
        // Jenkins-White §6.2 conventional darkening.
        guard let filter = CIFilter(name: "CIVignette") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        let intensity = (parameters["intensity"] as? NSNumber) ?? 0.5
        let radius = (parameters["radius"] as? NSNumber) ?? 1.0
        filter.setValue(intensity, forKey: "inputIntensity")
        filter.setValue(radius, forKey: "inputRadius")
        return filter.outputImage ?? image
    }
}

struct SharpeningKernel: PrimitiveOpKernel {
    let primitive: FilterPrimitive = .sharpening
    let parameters: [String: Any]

    func process(_ image: CIImage) -> CIImage {
        // Wiener 1949 minimum-noise inverse filter analog via unsharp mask.
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        if let r = parameters["radius"] as? NSNumber { filter.setValue(r, forKey: "inputRadius") }
        if let i = parameters["intensity"] as? NSNumber { filter.setValue(i, forKey: "inputIntensity") }
        return filter.outputImage ?? image
    }
}
