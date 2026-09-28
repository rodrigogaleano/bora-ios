import Foundation
import Testing
@testable import Bora

struct ResultsShareTextTests {
    private let locale = Locale(identifier: "en_US")
    private let startedAt = Date(timeIntervalSince1970: 1_790_510_400)

    private var date: String {
        startedAt.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }

    private func split(_ phase: RunPhase.Kind, seconds: TimeInterval, meters: Double) -> SessionMetrics.BlockSplit {
        SessionMetrics.BlockSplit(
            phase: phase,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(seconds),
            duration: seconds,
            distanceMeters: meters,
            averagePaceSecondsPerKm: meters > 0 ? seconds / (meters / 1000) : nil
        )
    }

    @Test func intervalsListTheRepsUnderThePlan() {
        let plan = SessionPlan(
            goal: .free,
            hiit: HIITPlan(sets: 2, work: .distance(meters: 400), rest: .duration(90)),
            workoutType: .intervals
        )
        let metrics = SessionMetrics(
            startedAt: startedAt,
            totalDistanceMeters: 1_000,
            totalDuration: 360,
            splits: [
                split(.work(setIndex: 0), seconds: 92, meters: 400),
                split(.rest(setIndex: 0), seconds: 90, meters: 150),
                split(.work(setIndex: 1), seconds: 96, meters: 400)
            ]
        )

        let lines = ResultsShareText.text(plan: plan, metrics: metrics, locale: locale)
            .components(separatedBy: "\n")

        let rep = RunFormatting.distance(meters: 400)
        #expect(lines == [
            "Intervals · \(date)",
            "2 × \(rep) · rest 01:30",
            "\(RunFormatting.distance(meters: 1_000)) · 06:00 · Work pace 03:55 /km",
            "",
            "Reps",
            "1. \(rep) · 01:32 · 03:50 /km",
            "2. \(rep) · 01:36 · 04:00 /km"
        ])
    }

    @Test func continuousRunsListTheKilometers() {
        let plan = SessionPlan(goal: .time(2_400), workoutType: .easyRun)
        let metrics = SessionMetrics(
            startedAt: startedAt,
            totalDistanceMeters: 2_500,
            totalDuration: 780,
            averagePaceSecondsPerKm: 312,
            kilometerSplits: [
                SessionMetrics.KilometerSplit(distanceMeters: 1_000, duration: 300),
                SessionMetrics.KilometerSplit(distanceMeters: 1_000, duration: 320),
                SessionMetrics.KilometerSplit(distanceMeters: 500, duration: 160)
            ]
        )

        let lines = ResultsShareText.text(plan: plan, metrics: metrics, locale: locale)
            .components(separatedBy: "\n")

        #expect(lines == [
            "Easy run · \(date)",
            "\(RunFormatting.distance(meters: 2_500)) · 13:00 · Avg pace 05:12 /km",
            "",
            "Splits",
            "Km 1 · 05:00 /km",
            "Km 2 · 05:20 /km",
            "\(RunFormatting.distance(meters: 500)) · 05:20 /km"
        ])
    }

    @Test func planWithoutTypeFallsBackToItsTitle() {
        let plan = SessionPlan(goal: .free)
        let metrics = SessionMetrics(startedAt: startedAt, totalDuration: 600)

        let text = ResultsShareText.text(plan: plan, metrics: metrics, locale: locale)

        #expect(text == "\(SessionPlanFormatting.title(for: plan)) · \(date)\n10:00")
    }
}
