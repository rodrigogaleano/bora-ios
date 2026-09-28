import Foundation

enum ResultsShareText {
    static func text(plan: SessionPlan, metrics: SessionMetrics, locale: Locale = .current) -> String {
        let content = ShareCardContent(plan: plan, metrics: metrics, locale: locale)
        var lines = ["\(content.title) · \(content.date)"]
        if let hiit = plan.hiit {
            lines.append(hiitLine(hiit))
        }
        lines.append(summaryLine(content))

        let rows = metrics.isIntervalSession ? repRows(metrics) : kilometerRows(metrics)
        if !rows.isEmpty {
            let listTitle = metrics.isIntervalSession ? String(localized: "Reps") : String(localized: "Splits")
            lines += ["", listTitle] + rows
        }
        return lines.joined(separator: "\n")
    }

    private static func hiitLine(_ hiit: HIITPlan) -> String {
        String(localized: "\(hiit.sets) × \(target(hiit.work)) · rest \(target(hiit.rest))")
    }

    private static func target(_ target: BlockTarget) -> String {
        switch target {
        case .duration(let seconds):
            return RunFormatting.duration(seconds)
        case .distance(let meters):
            return RunFormatting.distance(meters: meters)
        }
    }

    private static func summaryLine(_ content: ShareCardContent) -> String {
        guard content.hasDistance else { return content.duration }
        return [content.distance, content.duration, "\(content.paceTitle) \(content.pace)"]
            .joined(separator: " · ")
    }

    private static func repRows(_ metrics: SessionMetrics) -> [String] {
        guard metrics.totalDistanceMeters > 0 else { return [] }
        let reps = metrics.splits.filter { split in
            if case .work = split.phase {
                return true
            }
            return false
        }
        return reps.enumerated().map { index, split in
            let distance = RunFormatting.distance(meters: split.distanceMeters)
            let duration = RunFormatting.duration(split.duration)
            let pace = RunFormatting.pace(secondsPerKm: split.averagePaceSecondsPerKm)
            return "\(index + 1). \(distance) · \(duration) · \(pace)"
        }
    }

    private static func kilometerRows(_ metrics: SessionMetrics) -> [String] {
        metrics.kilometerSplits.enumerated().map { index, split in
            let pace = RunFormatting.pace(secondsPerKm: split.duration / (split.distanceMeters / 1000))
            let label = split.distanceMeters >= 1000
                ? String(localized: "Km \(index + 1)")
                : RunFormatting.distance(meters: split.distanceMeters)
            return "\(label) · \(pace)"
        }
    }
}
