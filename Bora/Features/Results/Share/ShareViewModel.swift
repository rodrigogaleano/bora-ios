import CoreGraphics
import UIKit

@Observable
final class ShareViewModel {
    enum Format: CaseIterable, Hashable {
        case map
        case sticker
        case text

        var title: LocalizedStringResource {
            switch self {
            case .map:
                return "Map"
            case .sticker:
                return "Sticker"
            case .text:
                return "Text"
            }
        }
    }

    static let mapSize = CGSize(width: 360, height: 270)

    let content: ShareCardContent
    let text: String
    let routePoints: [CGPoint]
    private let route: [RouteCoordinate]
    private let snapshotter: RouteSnapshotProviding

    var format: Format
    private(set) var mapImage: UIImage?
    private(set) var isMapUnavailable: Bool

    init(plan: SessionPlan, metrics: SessionMetrics, snapshotter: RouteSnapshotProviding) {
        self.content = ShareCardContent(plan: plan, metrics: metrics)
        self.text = ResultsShareText.text(plan: plan, metrics: metrics)
        self.routePoints = RouteShape.normalized(metrics.route)
        self.route = metrics.route
        self.snapshotter = snapshotter
        let isMapUnavailable = metrics.route.count < 2
        self.isMapUnavailable = isMapUnavailable
        self.format = isMapUnavailable ? .sticker : .map
    }

    var availableFormats: [Format] {
        isMapUnavailable ? [.sticker, .text] : Format.allCases
    }

    func loadMap() async {
        guard !isMapUnavailable, mapImage == nil else { return }
        do {
            mapImage = try await snapshotter.snapshot(route: route, size: Self.mapSize)
        } catch {
            isMapUnavailable = true
            if format == .map {
                format = .sticker
            }
        }
    }
}
