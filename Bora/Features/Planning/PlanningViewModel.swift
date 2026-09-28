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
    private let lastWorkouts: LastWorkoutStoring
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

    var checkpoints: CheckpointConfig

    init(
        workoutType: WorkoutType,
        clock: ClockProviding,
        lastWorkouts: LastWorkoutStoring,
        onNext: @escaping (SessionPlan) -> Void
    ) {
        self.workoutType = workoutType
        self.clock = clock
        self.lastWorkouts = lastWorkouts
        self.onNext = onNext
        self.checkpoints = workoutType.defaultCheckpoints
        applyDefaults()
        if let saved = lastWorkouts.load(workoutType) {
            apply(saved)
        }
    }

    var title: String { workoutType.title }

    var showsGoal: Bool {
        workoutType == .easyRun || workoutType == .longRun
    }

    var goalKinds: [GoalKind] { [.distance, .time] }

    var showsHIIT: Bool { workoutType == .intervals }

    var showsProgressCheckpoints: Bool { showsGoal || showsHIIT }

    var showsRepSummary: Bool { showsHIIT }

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
            ) : nil,
            workoutType: workoutType,
            checkpoints: checkpoints
        )
    }

    var isValid: Bool { sessionPlan.isValid }

    func next() {
        guard isValid else { return }
        lastWorkouts.save(sessionPlan)
        onNext(sessionPlan)
    }

    func setProgressCheckpoint(_ checkpoint: ProgressCheckpoint, isOn: Bool) {
        if isOn {
            checkpoints.progress.insert(checkpoint)
        } else {
            checkpoints.progress.remove(checkpoint)
        }
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

    private func apply(_ plan: SessionPlan) {
        switch plan.goal {
        case .distance(let meters, let scope):
            goalKind = .distance
            goalDistanceMeters = meters
            goalDistanceScope = scope
        case .time(let seconds):
            goalKind = .time
            goalDurationSeconds = seconds
        case .free:
            goalKind = .free
        }

        isWarmupEnabled = plan.warmup != nil
        if let warmup = plan.warmup {
            Self.unpack(warmup, kind: &warmupKind, seconds: &warmupDurationSeconds, meters: &warmupDistanceMeters)
        }

        isHIITEnabled = plan.hiit != nil
        if let hiit = plan.hiit {
            hiitSets = hiit.sets
            Self.unpack(
                hiit.work,
                kind: &hiitWorkKind,
                seconds: &hiitWorkDurationSeconds,
                meters: &hiitWorkDistanceMeters
            )
            Self.unpack(
                hiit.rest,
                kind: &hiitRestKind,
                seconds: &hiitRestDurationSeconds,
                meters: &hiitRestDistanceMeters
            )
        }

        isCooldownEnabled = plan.cooldown != nil
        if let cooldown = plan.cooldown {
            Self.unpack(
                cooldown,
                kind: &cooldownKind,
                seconds: &cooldownDurationSeconds,
                meters: &cooldownDistanceMeters
            )
        }

        checkpoints = plan.checkpoints
    }

    private static func unpack(
        _ target: BlockTarget,
        kind: inout TargetKind,
        seconds: inout Double,
        meters: inout Double
    ) {
        switch target {
        case .duration(let value):
            kind = .duration
            seconds = value
        case .distance(let value):
            kind = .distance
            meters = value
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
