import Foundation
import UIKit

/// One entry in the Atelier filter library. mk3-C value type — the
/// real auto-generation from N=5 reference image pairs lands at
/// `filter_algebra.cond.3` (mk4). For now the library is hand-curated
/// (`AtelierLibrary.inaugural`) using the Forge `RecipeParser` grammar.
struct LibraryFilter: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let recipe: String
    let thumbnail: UIImage?

    init(name: String, recipe: String, thumbnail: UIImage? = nil, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.recipe = recipe
        self.thumbnail = thumbnail
    }

    static func == (lhs: LibraryFilter, rhs: LibraryFilter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
