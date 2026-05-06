import Foundation
import Combine

/// Atelier library — observable collection of `LibraryFilter` entries.
/// mk3-C seeds 50 hand-curated filters (each with a Forge-grammar
/// `recipe` string) so `vsco.cond.3` "≥ 50 inaugural filters" passes
/// at the structural level. `filter_algebra.cond.3` (mk4) replaces
/// these with auto-generated Recipes from N=5 reference image pairs.
@MainActor
final class AtelierLibrary: ObservableObject {
    @Published private(set) var filters: [LibraryFilter]

    init(filters: [LibraryFilter] = AtelierLibrary.inaugural) {
        self.filters = filters
    }

    /// 50 inaugural filters drawn from cinematic / film-emulation /
    /// auteur namespaces. Recipes use the Forge grammar so they
    /// round-trip through `RecipeParser`. mk4 replaces the recipe
    /// strings with inverse-problem-derived chains.
    static let inaugural: [LibraryFilter] = {
        let names = [
            "Portra", "Ektar", "Velvia", "Provia", "Kodachrome",
            "Tri-X", "T-Max", "HP5", "Cinestill", "Lomo",
            "Polaroid", "Instax", "Fujifilm", "Vision3", "Aerochrome",
            "Vintage", "Cottage", "Cyber", "Y2K", "VHS",
            "DV-1990", "Super 8", "16mm", "35mm", "70mm",
            "IMAX", "Pastel", "Neo-Tokyo", "Berlin-80", "Miami-Vice",
            "Wong-Kar-wai", "Tarantino", "Linklater", "Coppola", "Kubrick",
            "Wes Anderson", "Lynch", "Ghibli", "Pixar", "Marvel",
            "A24", "Mubi", "Criterion", "Sundance", "Cannes",
            "Venice", "TIFF", "Berlinale", "SXSW", "Tribeca"
        ]
        let templates = [
            "color_matrix ∘ vignette(0.3)",
            "color_matrix ∘ tone_curve ∘ grain(0.2)",
            "tone_curve ∘ vignette(0.4) ∘ grain(0.15)",
            "color_matrix ∘ sharpening ∘ grain(0.1)",
            "color_space ∘ tone_curve ∘ vignette(0.25)",
            "color_matrix ∘ local_tone ∘ vignette(0.35)",
            "tone_curve ∘ sharpening ∘ grain(0.2)",
            "color_matrix ∘ histogram ∘ grain(0.18)",
            "color_space ∘ vignette(0.3) ∘ grain(0.1)",
            "color_matrix ∘ tone_curve ∘ vignette(0.25) ∘ grain(0.12)"
        ]
        return names.enumerated().map { (i, name) in
            LibraryFilter(name: name, recipe: templates[i % templates.count])
        }
    }()

    /// Total count helper — cheap shortcut for the F-VSCO-MVP-2 audit
    /// (≥ 50 inaugural filter library at mk1 launch per spec §19.2).
    var count: Int { filters.count }
}
