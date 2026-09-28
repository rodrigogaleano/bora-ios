import SwiftUI

enum ShareCardLayout {
    static let size = CGSize(width: 360, height: 450)
}

struct ShareCardView: View {
    let content: ShareCardContent
    let mapImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            if let mapImage {
                Image(uiImage: mapImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: ShareViewModel.mapSize.width, height: ShareViewModel.mapSize.height)
                    .clipped()
            }
            ShareStats(content: content)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(width: ShareCardLayout.size.width, height: ShareCardLayout.size.height)
        .background(Color(.systemBackground))
        .environment(\.colorScheme, .light)
    }
}

struct ShareStickerView: View {
    let content: ShareCardContent
    let routePoints: [CGPoint]

    var body: some View {
        VStack(spacing: 24) {
            if !routePoints.isEmpty {
                RoutePath(points: routePoints)
                    .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: 220, height: 220)
            }
            ShareStats(content: content, alignment: .center)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
        .frame(width: ShareCardLayout.size.width, height: ShareCardLayout.size.height)
    }
}

private struct ShareStats: View {
    let content: ShareCardContent
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 12) {
            Text(verbatim: "\(content.title) · \(content.date)")
                .font(.subheadline.weight(.semibold))
            if content.hasDistance {
                Text(content.distance)
                    .font(.system(size: 48, weight: .bold).monospacedDigit())
            }
            HStack(spacing: 32) {
                stat(value: content.duration, title: String(localized: "Duration"))
                if content.hasDistance {
                    stat(value: content.pace, title: content.paceTitle)
                }
            }
        }
    }

    private func stat(value: String, title: String) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
            Text(title)
                .font(.caption)
                .opacity(0.8)
        }
    }
}

private struct RoutePath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            let scaled = points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
            guard let first = scaled.first else { return }
            path.move(to: first)
            path.addLines(Array(scaled.dropFirst()))
        }
    }
}
