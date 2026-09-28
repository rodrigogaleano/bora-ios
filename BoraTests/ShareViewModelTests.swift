import Foundation
import Testing
import UIKit
@testable import Bora

struct ShareViewModelTests {
    private struct SnapshotError: Error {}

    private struct FakeSnapshotter: RouteSnapshotProviding {
        var fails = false

        func snapshot(route: [RouteCoordinate], size: CGSize) async throws -> UIImage {
            if fails {
                throw SnapshotError()
            }
            return UIImage()
        }
    }

    private let route = [
        RouteCoordinate(latitude: 0, longitude: 0),
        RouteCoordinate(latitude: 0, longitude: 0.01)
    ]

    private func makeViewModel(route: [RouteCoordinate], fails: Bool = false) -> ShareViewModel {
        ShareViewModel(
            plan: SessionPlan(goal: .free, workoutType: .freeRun),
            metrics: SessionMetrics(startedAt: .now, route: route),
            snapshotter: FakeSnapshotter(fails: fails)
        )
    }

    @Test func runWithoutRouteHasNoMap() {
        let viewModel = makeViewModel(route: [])

        #expect(viewModel.availableFormats == [.sticker, .text])
        #expect(viewModel.format == .sticker)
    }

    @Test func mapLoadsForARoute() async {
        let viewModel = makeViewModel(route: route)

        await viewModel.loadMap()

        #expect(viewModel.format == .map)
        #expect(viewModel.mapImage != nil)
    }

    @Test func failedSnapshotFallsBackToTheSticker() async {
        let viewModel = makeViewModel(route: route, fails: true)

        await viewModel.loadMap()

        #expect(viewModel.availableFormats == [.sticker, .text])
        #expect(viewModel.format == .sticker)
    }

    @Test func intervalCardShowsTheWorkPace() {
        let metrics = SessionMetrics(
            startedAt: .now,
            totalDistanceMeters: 400,
            splits: [
                SessionMetrics.BlockSplit(
                    phase: .work(setIndex: 0),
                    startedAt: .now,
                    endedAt: .now,
                    duration: 90,
                    distanceMeters: 400,
                    averagePaceSecondsPerKm: 225
                )
            ]
        )

        let content = ShareCardContent(plan: SessionPlan(goal: .free), metrics: metrics)

        #expect(content.paceTitle == "Work pace")
        #expect(content.pace == "03:45 /km")
    }
}
