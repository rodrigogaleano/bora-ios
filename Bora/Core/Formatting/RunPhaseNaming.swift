import Foundation

extension RunPhase.Kind {
    var displayName: String {
        switch self {
        case .warmup:
            return String(localized: "Warmup")
        case .work(let setIndex):
            return String(localized: "Work \(setIndex + 1)")
        case .rest(let setIndex):
            return String(localized: "Rest \(setIndex + 1)")
        case .freeRun:
            return String(localized: "Run")
        case .cooldown:
            return String(localized: "Cooldown")
        }
    }
}
