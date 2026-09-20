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
    private let cuePlayer: RunCueProviding
    private let runActivity: RunActivityProviding
    private let settings: RunSettings
    let plan: SessionPlan
    let plannedRoute: PlannedRoute?
    private let onNext: (SessionMetrics) -> Void

    private let phases: [RunPhase]
    private(set) var currentPhaseIndex = 0
    private(set) var runState: RunState = .running
    private var hasWarnedCurrentPhase = false

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
    private var gpsSignal: GPSSignalMonitor?
    private(set) var isAudioUnavailable = false

    private(set) var splits: [SessionMetrics.BlockSplit] = []

    private var tickTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?

    private var lastPublishedState: RunActivityAttributes.ContentState?
    private var lastPublishedAt: Date?

    init(
        clock: ClockProviding,
        locationProvider: LocationProviding,
        cuePlayer: RunCueProviding,
        runActivity: RunActivityProviding,
        settings: RunSettings,
        plan: SessionPlan,
        route: PlannedRoute?,
        onNext: @escaping (SessionMetrics) -> Void
    ) {
        self.clock = clock
        self.locationProvider = locationProvider
        self.cuePlayer = cuePlayer
        self.runActivity = runActivity
        self.settings = settings
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

    var isGPSSignalLost: Bool { gpsSignal?.isLost ?? false }

    var isShowingUpcomingTransitionBanner: Bool {
        guard let remaining = remainingInPhase else { return false }
        return remaining > 0 && remaining <= Self.preTransitionWarningWindow
    }

    func start() {
        guard sessionStartedAt == nil else { return }
        beginTiming()

        locationTask = Task { [weak self] in
            guard let self else { return }
            for await sample in locationProvider.startLocationUpdates(accuracy: settings.gpsAccuracy) {
                self.recordLocation(sample)
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
        gpsSignal = GPSSignalMonitor(startedAt: now)

        cuePlayer.prepare(settings: settings)
        announceCurrentPhase()
        startActivity()
    }

    func tick() {
        guard runState == .running, let phaseStartedAt, let sessionStartedAt, let currentPhase else { return }
        let now = clock.now
        elapsedInPhase = now.timeIntervalSince(phaseStartedAt) - phasePausedAccumulatedSeconds
        elapsedTotal = now.timeIntervalSince(sessionStartedAt) - pausedAccumulatedSeconds
        // The run keeps going (a timed workout doesn't need GPS); the runner just needs to
        // know distance stopped counting.
        if gpsSignal?.checkTimeout(now: now) == true {
            cuePlayer.play(.gpsLost)
        }
        isAudioUnavailable = !cuePlayer.isAudioAvailable
        warnAboutUpcomingTransitionIfNeeded()
        if currentPhase.isComplete(
            elapsed: elapsedInPhase,
            phaseDistanceMeters: phaseDistanceMeters,
            sessionDistanceMeters: totalDistanceMeters
        ) {
            advanceToNextPhase()
        } else {
            publishActivity(force: false)
        }
    }

    func pause() {
        guard runState == .running else { return }
        runState = .paused
        pauseStartedAt = clock.now
        cuePlayer.stopMetronome()
        publishActivity(force: true)
    }

    func resume() {
        guard runState == .paused, let pauseStartedAt else { return }
        let pausedDuration = clock.now.timeIntervalSince(pauseStartedAt)
        pausedAccumulatedSeconds += pausedDuration
        phasePausedAccumulatedSeconds += pausedDuration
        self.pauseStartedAt = nil
        gpsSignal?.resume(at: clock.now)
        runState = .running
        startMetronomeIfNeeded()
        publishActivity(force: true)
    }

    func finish() {
        finishRun()
    }

    func recordLocation(_ sample: LocationSample) {
        guard runState == .running else { return }
        let elapsedSinceLastFix = lastLocationTimestamp.map { clock.now.timeIntervalSince($0) } ?? 0
        guard LocationQualityFilter.accepts(
            sample,
            after: traveledPath.last,
            elapsed: elapsedSinceLastFix,
            accuracy: settings.gpsAccuracy
        ) else { return }
        if gpsSignal?.recordValidFix(at: clock.now) == true {
            cuePlayer.play(.gpsRecovered)
        }
        let coordinate = sample.coordinate
        if let last = traveledPath.last {
            let delta = last.clLocation.distance(from: coordinate.clLocation)
            totalDistanceMeters += delta
            phaseDistanceMeters += delta
            if elapsedSinceLastFix > 0 {
                currentSpeedMetersPerSecond = delta / elapsedSinceLastFix
                maxSpeedMetersPerSecond = max(maxSpeedMetersPerSecond, currentSpeedMetersPerSecond)
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
        hasWarnedCurrentPhase = false
        announceCurrentPhase()
        publishActivity(force: true)
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
        cuePlayer.play(.runFinished)
        cuePlayer.stopMetronome()
        cuePlayer.teardown()

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
        endActivity(metrics: metrics)
        onNext(metrics)
    }
}

// MARK: - Cues

private extension ExecutionViewModel {
    func announceCurrentPhase() {
        guard let currentPhase else { return }
        cuePlayer.play(.phaseStarted(currentPhase.kind.displayName))
        startMetronomeIfNeeded()
    }

    /// The metronome is a cadence guide, so it stays quiet while the runner is resting.
    func startMetronomeIfNeeded() {
        guard settings.isMetronomeEnabled, runState == .running, let currentPhase else { return }
        if case .rest = currentPhase.kind {
            cuePlayer.stopMetronome()
            return
        }
        cuePlayer.startMetronome(bpm: settings.metronomeBPM)
    }

    /// Fires once per phase: `tick()` runs every 500 ms, and the warning window is 10 s wide.
    func warnAboutUpcomingTransitionIfNeeded() {
        guard !hasWarnedCurrentPhase, isShowingUpcomingTransitionBanner, let nextPhase else { return }
        hasWarnedCurrentPhase = true
        cuePlayer.play(.upcomingTransition(nextPhase.kind.displayName))
    }
}

// MARK: - Live Activity

private extension ExecutionViewModel {
    func startActivity() {
        let state = activityState()
        runActivity.start(planTitle: SessionPlanFormatting.title(for: plan), state: state)
        markPublished(state)
    }

    /// `force` is for the moments the lock screen must be right at once — a phase change,
    /// a pause, a resume. Everything else goes through the throttle.
    func publishActivity(force: Bool) {
        let state = activityState()
        let secondsSinceLastPublish = lastPublishedAt.map { clock.now.timeIntervalSince($0) } ?? .infinity
        guard force || RunActivityStateBuilder.shouldPublish(
            previous: lastPublishedState,
            next: state,
            secondsSinceLastPublish: secondsSinceLastPublish
        ) else {
            return
        }
        runActivity.update(state)
        markPublished(state)
    }

    /// The finished run freezes on the lock screen with the session totals, not the last
    /// block's — that is what the runner wants to read when they stop.
    func endActivity(metrics: SessionMetrics) {
        let averageSpeed = metrics.totalDuration > 0 ? metrics.totalDistanceMeters / metrics.totalDuration : 0
        let progress = RunActivityProgress(
            phaseTitle: String(localized: "Run finished"),
            phaseNumber: phases.count,
            phaseCount: phases.count,
            elapsedInPhase: metrics.totalDuration,
            remainingInPhase: nil,
            pausedAt: clock.now,
            distanceMeters: metrics.totalDistanceMeters,
            speedMetersPerSecond: averageSpeed,
            upcomingPhaseTitle: nil
        )
        runActivity.end(RunActivityStateBuilder.state(from: progress, now: clock.now))
    }

    func activityState() -> RunActivityAttributes.ContentState {
        let progress = RunActivityProgress(
            phaseTitle: currentPhase?.kind.displayName ?? "",
            phaseNumber: currentPhaseIndex + 1,
            phaseCount: phases.count,
            elapsedInPhase: elapsedInPhase,
            remainingInPhase: remainingInPhase,
            pausedAt: runState == .paused ? pauseStartedAt : nil,
            distanceMeters: totalDistanceMeters,
            speedMetersPerSecond: currentSpeedMetersPerSecond,
            upcomingPhaseTitle: nextPhase?.kind.displayName
        )
        return RunActivityStateBuilder.state(from: progress, now: clock.now)
    }

    func markPublished(_ state: RunActivityAttributes.ContentState) {
        lastPublishedState = state
        lastPublishedAt = clock.now
    }
}
