import Foundation

@Observable
final class PlanningViewModel {
    enum GoalKind: CaseIterable, Hashable {
        case distance, time, free

        var label: String {
            switch self {
            case .distance: return "Distance"
            case .time: return "Time"
            case .free: return "Free"
            }
        }
    }

    enum TargetKind: CaseIterable, Hashable {
        case duration, distance

        var label: String {
            switch self {
            case .duration: return "Time"
            case .distance: return "Distance"
            }
        }
    }

    private let clock: ClockProviding
    private let onNext: (SessionPlan) -> Void

    var goalKind: GoalKind = .distance
    var goalDistanceMeters: Double = 5000
    var goalDurationMinutes: Double = 30
    var goalDistanceScope: DistanceScope = .totalSession

    var isWarmupEnabled = false
    var warmupKind: TargetKind = .duration
    var warmupDurationMinutes: Double = 5
    var warmupDistanceMeters: Double = 500

    var isHIITEnabled = false
    var hiitSets: Int = 4
    var hiitWorkKind: TargetKind = .duration
    var hiitWorkDurationSeconds: Double = 30
    var hiitWorkDistanceMeters: Double = 100
    var hiitRestKind: TargetKind = .duration
    var hiitRestDurationSeconds: Double = 30
    var hiitRestDistanceMeters: Double = 50

    var isCooldownEnabled = false
    var cooldownKind: TargetKind = .duration
    var cooldownDurationMinutes: Double = 5
    var cooldownDistanceMeters: Double = 500

    init(clock: ClockProviding, onNext: @escaping (SessionPlan) -> Void) {
        self.clock = clock
        self.onNext = onNext
    }

    var sessionPlan: SessionPlan {
        SessionPlan(
            goal: makeGoal(),
            warmup: isWarmupEnabled ? makeTarget(
                kind: warmupKind,
                durationMinutes: warmupDurationMinutes,
                distanceMeters: warmupDistanceMeters
            ) : nil,
            hiit: isHIITEnabled ? makeHIITPlan() : nil,
            cooldown: isCooldownEnabled ? makeTarget(
                kind: cooldownKind,
                durationMinutes: cooldownDurationMinutes,
                distanceMeters: cooldownDistanceMeters
            ) : nil
        )
    }

    var isValid: Bool { sessionPlan.isValid }

    func next() {
        guard isValid else { return }
        onNext(sessionPlan)
    }

    private func makeGoal() -> SessionGoal {
        switch goalKind {
        case .distance:
            return .distance(meters: goalDistanceMeters, scope: goalDistanceScope)
        case .time:
            return .time(goalDurationMinutes * 60)
        case .free:
            return .free
        }
    }

    private func makeTarget(kind: TargetKind, durationMinutes: Double, distanceMeters: Double) -> BlockTarget {
        kind == .duration ? .duration(durationMinutes * 60) : .distance(meters: distanceMeters)
    }

    private func makeHIITPlan() -> HIITPlan {
        HIITPlan(
            sets: hiitSets,
            work: makeHIITTarget(kind: hiitWorkKind, seconds: hiitWorkDurationSeconds, meters: hiitWorkDistanceMeters),
            rest: makeHIITTarget(kind: hiitRestKind, seconds: hiitRestDurationSeconds, meters: hiitRestDistanceMeters)
        )
    }

    private func makeHIITTarget(kind: TargetKind, seconds: Double, meters: Double) -> BlockTarget {
        kind == .duration ? .duration(seconds) : .distance(meters: meters)
    }
}
