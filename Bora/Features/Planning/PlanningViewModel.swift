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

    let workoutType: WorkoutType
    private let clock: ClockProviding
    private let onNext: (SessionPlan) -> Void

    var goalKind: GoalKind = .distance
    var goalDistanceMeters: Double = 5000
    var goalDurationSeconds: Double = 1_800
    var goalDistanceScope: DistanceScope = .totalSession

    var isWarmupEnabled = false
    var warmupKind: TargetKind = .duration
    var warmupDurationSeconds: Double = 300
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
    var cooldownDurationSeconds: Double = 300
    var cooldownDistanceMeters: Double = 500

    init(workoutType: WorkoutType, clock: ClockProviding, onNext: @escaping (SessionPlan) -> Void) {
        self.workoutType = workoutType
        self.clock = clock
        self.onNext = onNext
        applyDefaults()
    }

    var title: String { workoutType.title }

    var showsGoal: Bool {
        workoutType == .easyRun || workoutType == .longRun
    }

    var goalKinds: [GoalKind] { [.distance, .time] }

    var showsHIIT: Bool { workoutType == .intervals }

    var sessionPlan: SessionPlan {
        SessionPlan(
            goal: makeGoal(),
            warmup: isWarmupEnabled ? makeTarget(
                kind: warmupKind,
                seconds: warmupDurationSeconds,
                meters: warmupDistanceMeters
            ) : nil,
            hiit: isHIITEnabled && showsHIIT ? makeHIITPlan() : nil,
            cooldown: isCooldownEnabled ? makeTarget(
                kind: cooldownKind,
                seconds: cooldownDurationSeconds,
                meters: cooldownDistanceMeters
            ) : nil
        )
    }

    var isValid: Bool { sessionPlan.isValid }

    func next() {
        guard isValid else { return }
        onNext(sessionPlan)
    }

    private func applyDefaults() {
        switch workoutType {
        case .easyRun:
            goalKind = .time
            goalDurationSeconds = 2_400
        case .longRun:
            goalKind = .distance
            goalDistanceMeters = 10_000
        case .intervals:
            goalKind = .free
            isHIITEnabled = true
            hiitSets = 6
            hiitWorkKind = .distance
            hiitWorkDistanceMeters = 400
            hiitRestKind = .duration
            hiitRestDurationSeconds = 90
            isWarmupEnabled = true
            warmupDurationSeconds = 600
            isCooldownEnabled = true
            cooldownDurationSeconds = 600
        case .freeRun:
            goalKind = .free
        }
    }

    private func makeGoal() -> SessionGoal {
        guard showsGoal else { return .free }
        switch goalKind {
        case .distance:
            return .distance(meters: goalDistanceMeters, scope: goalDistanceScope)
        case .time:
            return .time(goalDurationSeconds)
        case .free:
            return .free
        }
    }

    private func makeHIITPlan() -> HIITPlan {
        HIITPlan(
            sets: hiitSets,
            work: makeTarget(kind: hiitWorkKind, seconds: hiitWorkDurationSeconds, meters: hiitWorkDistanceMeters),
            rest: makeTarget(kind: hiitRestKind, seconds: hiitRestDurationSeconds, meters: hiitRestDistanceMeters)
        )
    }

    private func makeTarget(kind: TargetKind, seconds: Double, meters: Double) -> BlockTarget {
        kind == .duration ? .duration(seconds) : .distance(meters: meters)
    }
}
