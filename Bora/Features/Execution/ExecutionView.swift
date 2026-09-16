import SwiftUI

struct ExecutionView: View {
    @State private var viewModel: ExecutionViewModel

    init(viewModel: ExecutionViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isShowingUpcomingTransitionBanner, let nextPhase = viewModel.nextPhase {
                Label("Coming up: \(Self.title(for: nextPhase.kind))", systemImage: "arrow.right.circle")
                    .font(.subheadline)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            if let currentPhase = viewModel.currentPhase {
                Text(Self.title(for: currentPhase.kind))
                    .font(.title)
            }

            Text(Self.formatted(viewModel.elapsedInPhase))
                .font(.system(size: 48, weight: .semibold, design: .rounded).monospacedDigit())

            HStack(spacing: 24) {
                metricTile(
                    title: "Distance",
                    value: Measurement(value: viewModel.totalDistanceMeters, unit: UnitLength.meters)
                        .formatted(.measurement(width: .abbreviated))
                )
                metricTile(title: "Pace", value: Self.paceLabel(viewModel.currentSpeedMetersPerSecond))
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Execution")
        .navigationBarBackButtonHidden()
        .task { viewModel.start() }
        .safeAreaInset(edge: .bottom) { controls }
    }

    private var controls: some View {
        HStack {
            Button(viewModel.runState == .paused ? "Resume" : "Pause") {
                if viewModel.runState == .paused {
                    viewModel.resume()
                } else {
                    viewModel.pause()
                }
            }
            .buttonStyle(.bordered)
            Spacer()
            Button("Finish", role: .destructive) {
                viewModel.finish()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title2.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private static func title(for kind: RunPhase.Kind) -> String {
        switch kind {
        case .warmup:
            return "Warmup"
        case .work(let setIndex):
            return "Work \(setIndex + 1)"
        case .rest(let setIndex):
            return "Rest \(setIndex + 1)"
        case .freeRun:
            return "Run"
        case .cooldown:
            return "Cooldown"
        }
    }

    private static func formatted(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private static func paceLabel(_ speedMetersPerSecond: Double) -> String {
        guard speedMetersPerSecond > 0 else { return "--:--" }
        let secondsPerKm = 1000 / speedMetersPerSecond
        let totalSeconds = Int(secondsPerKm)
        return String(format: "%02d:%02d /km", totalSeconds / 60, totalSeconds % 60)
    }
}
