import Foundation

@Observable
final class SummaryViewModel {
    struct BlockRow: Identifiable {
        let id: Int
        let badge: String
        let title: String
        let detail: String?
        let trailing: String
    }

    struct GoalNote {
        let title: String
        let detail: String
    }

    /// Shown where a block has no estimate to give — an open-ended run.
    private static let openEndedTrailing = "—"

    let plan: SessionPlan
    private(set) var route: PlannedRoute?
    private let onStart: (SessionPlan, PlannedRoute?) -> Void

    private let estimate: SessionEstimate

    init(plan: SessionPlan, route: PlannedRoute? = nil, onStart: @escaping (SessionPlan, PlannedRoute?) -> Void) {
        self.plan = plan
        self.route = route
        self.onStart = onStart
        estimate = SessionEstimator.estimate(for: plan)
    }

    var title: String {
        let hasIntervals = plan.hiit != nil
        switch plan.goal {
        case .distance(let meters, _):
            let distance = RunFormatting.distance(meters: meters)
            return hasIntervals
                ? String(localized: "\(distance) with intervals")
                : String(localized: "\(distance) continuous")
        case .time(let seconds):
            let duration = RunFormatting.compactDuration(seconds)
            return hasIntervals
                ? String(localized: "\(duration) with intervals")
                : String(localized: "\(duration) continuous")
        case .free:
            return String(localized: "Free session")
        }
    }

    var subtitle: String {
        guard !estimate.isOpenEnded else { return String(localized: "Open-ended run") }
        let duration = RunFormatting.compactDuration(estimate.duration)
        let distance = RunFormatting.distance(meters: estimate.totalDistanceMeters)
        return String(localized: "Estimated \(duration) · ≈ \(distance)")
    }

    /// Only a distance goal needs explaining: it either counts the whole session or the
    /// running blocks alone, and with intervals it doesn't gate anything at all.
    var goalNote: GoalNote? {
        guard case .distance(let meters, let scope) = plan.goal else { return nil }
        let goal = RunFormatting.distance(meters: meters)
        let total = RunFormatting.distance(meters: estimate.totalDistanceMeters)
        let running = RunFormatting.distance(meters: estimate.runDistanceMeters)

        guard plan.hiit == nil else {
            return GoalNote(
                title: String(localized: "Goal: \(goal)"),
                detail: String(localized: "Intervals run to their block targets; the goal is just a reference.")
            )
        }
        switch scope {
        case .runOnly:
            return GoalNote(
                title: String(localized: "Goal: \(goal) — run only"),
                detail: String(localized: "Estimated \(running) of running, \(total) once the other blocks are added.")
            )
        case .totalSession:
            return GoalNote(
                title: String(localized: "Goal: \(goal) — whole session"),
                detail: String(localized: "Estimated \(total) in total, \(running) of it running.")
            )
        }
    }

    /// One row per planned block, with the whole HIIT ladder collapsed into a single row —
    /// eight work/rest lines is a wall, not a summary.
    var blockRows: [BlockRow] {
        var rows: [BlockRow] = []
        if let warmup = plan.warmup {
            rows.append(
                BlockRow(
                    id: rows.count,
                    badge: "\(rows.count + 1)",
                    title: RunPhase.Kind.warmup.displayName,
                    detail: nil,
                    trailing: targetText(warmup)
                )
            )
        }
        if let hiit = plan.hiit {
            rows.append(
                BlockRow(
                    id: rows.count,
                    badge: "\(hiit.sets)×",
                    title: String(localized: "Intervals"),
                    detail: String(localized: "\(targetText(hiit.work)) hard / \(targetText(hiit.rest)) easy"),
                    trailing: RunFormatting.compactDuration(intervalsDuration)
                )
            )
        } else {
            rows.append(
                BlockRow(
                    id: rows.count,
                    badge: "\(rows.count + 1)",
                    title: RunPhase.Kind.freeRun.displayName,
                    detail: nil,
                    trailing: freeRunTrailing
                )
            )
        }
        if let cooldown = plan.cooldown {
            rows.append(
                BlockRow(
                    id: rows.count,
                    badge: "\(rows.count + 1)",
                    title: RunPhase.Kind.cooldown.displayName,
                    detail: nil,
                    trailing: targetText(cooldown)
                )
            )
        }
        return rows
    }

    var routeSummary: String {
        guard let route, route.isValid else { return String(localized: "No route set") }
        let distance = RunFormatting.distance(meters: route.totalDistanceMeters)
        return String(localized: "Out and back · \(distance)")
    }

    func routeChosen(_ route: PlannedRoute) {
        self.route = route
    }

    func start() {
        onStart(plan, route)
    }

    private var intervalsDuration: TimeInterval {
        estimate.blocks.reduce(0) { total, block in
            switch block.kind {
            case .work, .rest: return total + block.duration
            case .warmup, .cooldown, .freeRun: return total
            }
        }
    }

    private var freeRunTrailing: String {
        guard
            !estimate.isOpenEnded,
            let freeRun = estimate.blocks.first(where: { $0.kind == .freeRun })
        else { return Self.openEndedTrailing }

        switch plan.goal {
        case .distance:
            return RunFormatting.distance(meters: freeRun.distanceMeters)
        case .time, .free:
            return RunFormatting.compactDuration(freeRun.duration)
        }
    }

    private func targetText(_ target: BlockTarget) -> String {
        switch target {
        case .duration(let seconds):
            return RunFormatting.compactDuration(seconds)
        case .distance(let meters):
            return RunFormatting.distance(meters: meters)
        }
    }
}
