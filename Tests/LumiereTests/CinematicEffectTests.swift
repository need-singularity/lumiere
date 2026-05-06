import Testing
@testable import Lumiere

@Suite("CinematicEffect catalog")
struct CinematicEffectTests {

    @Test("9 effects per spec §19.2 / hexa-main-character")
    func nineEffects() {
        #expect(CinematicEffect.allCases.count == 9)
    }

    @Test("All effects have non-empty name and anchor")
    func nameAndAnchorPresent() {
        for effect in CinematicEffect.allCases {
            #expect(!effect.name.isEmpty)
            #expect(!effect.anchor.isEmpty)
            #expect(!effect.symbol.isEmpty)
        }
    }

    @Test("Effect IDs are unique")
    func uniqueIDs() {
        let ids = CinematicEffect.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
