import Foundation

struct ShareCardContent: Equatable {
    var title: String
    var date: String
    var distance: String
    var duration: String
    var paceTitle: String
    var pace: String
    var hasDistance: Bool
}

extension ShareCardContent {
    init(plan: SessionPlan, metrics: SessionMetrics, locale: Locale = .current) {
        var paceTitle = metrics.headlinePaceTitle
        paceTitle.locale = locale
        self.init(
            title: SessionPlanFormatting.workoutName(for: plan),
            date: metrics.startedAt.formatted(.dateTime.day().month(.abbreviated).locale(locale)),
            distance: RunFormatting.distance(meters: metrics.totalDistanceMeters),
            duration: RunFormatting.duration(metrics.totalDuration),
            paceTitle: String(localized: paceTitle),
            pace: RunFormatting.pace(secondsPerKm: metrics.headlinePaceSecondsPerKm),
            hasDistance: metrics.totalDistanceMeters > 0
        )
    }
}
