import Testing
import Foundation

@Suite("Physical-limit anchor invariants")
struct PhysicalLimitTests {

    @Test("Real-time frame budget = 1000/60 fps within 0.01 ms tolerance")
    func realTimeBudget() {
        let budgetMs = 1000.0 / 60.0
        #expect(abs(budgetMs - 16.667) < 0.01)
    }

    @Test("NPU budget at 50% headroom of A17 Pro 35 TOPS")
    func npuHeadroom() {
        let a17Pro: Double = 35.0
        let lumiereBudget: Double = 17.5
        #expect(lumiereBudget == a17Pro * 0.5)
    }

    @Test("Energy budget = 3 W * frame time (50 mJ at 60 fps)")
    func energyBudget() {
        let powerW: Double = 3.0
        let frameMs: Double = 1000.0 / 60.0
        let energyMj = powerW * frameMs
        #expect(abs(energyMj - 50.0) < 0.5)
    }
}
