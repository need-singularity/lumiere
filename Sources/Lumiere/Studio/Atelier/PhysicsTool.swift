import Foundation

/// 7 physics-based tools per spec §10 hexa-vsco ARCHITECTURE — these
/// distinguish Atelier from commodity editors that lean on perceptual
/// presets without principled bounds. Each tool is anchored to a
/// 19th-/20th-century physics result; mk3-C ships the catalog +
/// metadata, the actual CIFilter/Metal kernel implementations land at
/// `vsco.cond.5` (mk4).
enum PhysicsTool: String, CaseIterable, Identifiable, Sendable, Codable {
    case hAndDCurve
    case wienerDeconvolution
    case coxGrain
    case planckBlackbody
    case paraxialVignette
    case macAdamColor
    case cieObserver

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hAndDCurve:          return "H&D curves"
        case .wienerDeconvolution: return "Wiener deconvolution"
        case .coxGrain:            return "Cox grain"
        case .planckBlackbody:     return "Planck WB"
        case .paraxialVignette:    return "cos⁴θ vignette"
        case .macAdamColor:        return "MacAdam color ellipse"
        case .cieObserver:         return "CIE 1931 observer"
        }
    }

    var anchor: String {
        switch self {
        case .hAndDCurve:          return "Hurter-Driffield 1890"
        case .wienerDeconvolution: return "Wiener 1949"
        case .coxGrain:            return "Cox 1955 · D50 1.4 µm"
        case .planckBlackbody:     return "Planck 1900 · 2000-12000 K"
        case .paraxialVignette:    return "cos⁴θ paraxial"
        case .macAdamColor:        return "MacAdam 1942"
        case .cieObserver:         return "CIE 1931 standard observer"
        }
    }

    var symbol: String {
        switch self {
        case .hAndDCurve:          return "scribble.variable"
        case .wienerDeconvolution: return "waveform.path"
        case .coxGrain:            return "circle.grid.cross"
        case .planckBlackbody:     return "thermometer.medium"
        case .paraxialVignette:    return "circle.dashed"
        case .macAdamColor:        return "paintpalette"
        case .cieObserver:         return "eye"
        }
    }
}
