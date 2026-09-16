import CoreLocation
import Foundation

@Observable
final class ExecutionViewModel {
    enum RunState: Equatable {
        case running
        case paused
        case finished
    }

    private static let preTransitionWarningWindow: TimeInterval = 10
    private static let tickInterval: Duration = .milliseconds(500)

    private let clock: ClockProviding
    private let locationProvider: LocationProviding
    let plan: SessionPlan
    let plannedRoute: PlannedRoute
    private let onNext: (SessionMetrics) -> Void

    private let phases: [RunPhase]
    private(set) var currentPhaseIndex = 0
    private(set) var runState: RunState = .running

    private var sessionStartedAt: Date?
    private var phaseStartedAt: Date?
    private var pausedAccumulatedSeconds: TimeInterval = 0
    private var phasePausedAccumulatedSeconds: TimeInterval = 0
    private var pauseStartedAt: Date?

    private(set) var elapsedInPhase: TimeInterval = 0
    private(set) var elapsedTotal: TimeInterval = 0

    private(set) var traveledPath: [RouteCoordinate] = []
    private(set) var totalDistanceMeters: Double = 0
    private(set) var phaseDistanceMeters: Double = 0
    private(set) var currentSpeedMetersPerSecond: Double = 0
    private(set) var maxSpeedMetersPerSecond: Double = 0
    private var lastLocationTimestamp: Date?

    private(set) var splits: [SessionMetrics.BlockSplit] = []

    private var tickTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?

    init(
        clock: ClockProviding,
        locationProvider: LocationProviding,
        plan: SessionPlan,
        route: PlannedRoute,
        onNext: @escaping (SessionMetrics) -> Void
    ) {
        self.clock = clock
        self.locationProvider = locationProvider
        self.plan = plan
        self.plannedRoute = route
        self.onNext = onNext
        self.phases = plan.runPhases
    }

    var currentPhase: RunPhase? {
        phases.indices.contains(currentPhaseIndex) ? phases[currentPhaseIndex] : nil
    }

    var nextPhase: RunPhase? {
        phases.indices.contains(currentPhaseIndex + 1) ? phases[currentPhaseIndex + 1] : nil
    }

    /// Only meaningful for phases gated by `.duration`/`.time` — nil for distance-gated
    /// phases and for a `.free` goal, which have no time bound to count down.
    var remainingInPhase: TimeInterval? {
        guard let currentPhase else { return nil }
        switch currentPhase {
        case .warmup(.duration(let seconds)), .cooldown(.duration(let seconds)),
             .work(_, .duration(let seconds)), .rest(_, .duration(let seconds)):
            return max(0, seconds - elapsedInPhase)
        case .freeRun(.time(let seconds)):
            return max(0, seconds - elapsedInPhase)
        default:
            return nil
        }
    }

    var isShowingUpcomingTransitionBanner: Bool {
        guard let remaining = remainingInPhase else { return false }
        return remaining > 0 && remaining <= Self.preTransitionWarningWindow
    }

    func start() {
        guard sessionStartedAt == nil else { return }
        beginTiming()

        locationTask = Task { [weak self] in
            guard let self else { return }
            for await coordinate in locationProvider.startLocationUpdates() {
                self.recordLocation(coordinate)
            }
        }

        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.tick()
                try? await Task.sleep(for: Self.tickInterval)
            }
        }
    }

    /// Initializes timing state without spawning the background tick/location tasks. Production
    /// code should call `start()`; this exists so tests can drive `tick()`/`recordLocation(_:)`
    /// manually against a fake clock without a real polling `Task` racing the test's own calls.
    func beginTiming() {
        guard sessionStartedAt == nil else { return }
        let now = clock.now
        sessionStartedAt = now
        phaseStartedAt = now
    }

    func tick() {
        guard runState == .running, let phaseStartedAt, let sessionStartedAt, let currentPhase else { return }
        let now = clock.now
        elapsedInPhase = now.timeIntervalSince(phaseStartedAt) - phasePausedAccumulatedSeconds
        elapsedTotal = now.timeIntervalSince(sessionStartedAt) - pausedAccumulatedSeconds
        if currentPhase.isComplete(
            elapsed: elapsedInPhase,
            phaseDistanceMeters: phaseDistanceMeters,
            sessionDistanceMeters: totalDistanceMeters
        ) {
            advanceToNextPhase()
        }
    }

    func pause() {
        guard runState == .running else { return }
        runState = .paused
        pauseStartedAt = clock.now
    }

    func resume() {
        guard runState == .paused, let pauseStartedAt else { return }
        let pausedDuration = clock.now.timeIntervalSince(pauseStartedAt)
        pausedAccumulatedSeconds += pausedDuration
        phasePausedAccumulatedSeconds += pausedDuration
        self.pauseStartedAt = nil
        runState = .running
    }

    func finish() {
        finishRun()
    }

    func recordLocation(_ coordinate: RouteCoordinate) {
        guard runState == .running else { return }
        if let last = traveledPath.last {
            let delta = last.clLocation.distance(from: coordinate.clLocation)
            totalDistanceMeters += delta
            phaseDistanceMeters += delta
            if let lastTimestamp = lastLocationTimestamp {
                let elapsed = clock.now.timeIntervalSince(lastTimestamp)
                if elapsed > 0 {
                    currentSpeedMetersPerSecond = delta / elapsed
                    maxSpeedMetersPerSecond = max(maxSpeedMetersPerSecond, currentSpeedMetersPerSecond)
                }
            }
        }
        lastLocationTimestamp = clock.now
        traveledPath.append(coordinate)
    }

    private func advanceToNextPhase() {
        recordSplit()
        guard currentPhaseIndex + 1 < phases.count else {
            completeRun()
            return
        }
        currentPhaseIndex += 1
        phaseStartedAt = clock.now
        elapsedInPhase = 0
        phaseDistanceMeters = 0
        phasePausedAccumulatedSeconds = 0
    }

    private func recordSplit() {
        guard let currentPhase, let phaseStartedAt else { return }
        let pace = phaseDistanceMeters > 0
            ? elapsedInPhase / (phaseDistanceMeters / 1000)
            : nil
        splits.append(
            SessionMetrics.BlockSplit(
                phase: currentPhase.kind,
                startedAt: phaseStartedAt,
                endedAt: clock.now,
                distanceMeters: phaseDistanceMeters,
                averagePaceSecondsPerKm: pace
            )
        )
    }

    private func finishRun() {
        guard runState != .finished else { return }
        recordSplit()
        completeRun()
    }

    private func completeRun() {
        guard runState != .finished else { return }
        runState = .finished
        tickTask?.cancel()
        locationTask?.cancel()
        locationProvider.stopLocationUpdates()

        let averagePace = totalDistanceMeters > 0
            ? elapsedTotal / (totalDistanceMeters / 1000)
            : nil
        let metrics = SessionMetrics(
            startedAt: sessionStartedAt ?? clock.now,
            endedAt: clock.now,
            totalDistanceMeters: totalDistanceMeters,
            totalDuration: elapsedTotal,
            averagePaceSecondsPerKm: averagePace,
            maxSpeedMetersPerSecond: maxSpeedMetersPerSecond,
            splits: splits
        )
        onNext(metrics)
    }
}
