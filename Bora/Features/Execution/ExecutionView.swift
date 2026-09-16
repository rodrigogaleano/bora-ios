import SwiftUI

struct ExecutionView: View {
    @State private var viewModel: ExecutionViewModel

    init(viewModel: ExecutionViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isShowingUpcomingTransitionBanner, let nextPhase = viewModel.nextPhase {
                Label("Coming up: \(nextPhase.kind.displayName)", systemImage: "arrow.right.circle")
                    .font(.subheadline)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            if let currentPhase = viewModel.currentPhase {
                Text(currentPhase.kind.displayName)
                    .font(.title)
            }

            Text(RunFormatting.duration(viewModel.elapsedInPhase))
                .font(.system(size: 48, weight: .semibold, design: .rounded).monospacedDigit())

            HStack(spacing: 24) {
                metricTile(
                    title: "Distance",
                    value: RunFormatting.distance(meters: viewModel.totalDistanceMeters)
                )
                metricTile(
                    title: "Pace",
                    value: RunFormatting.pace(speedMetersPerSecond: viewModel.currentSpeedMetersPerSecond)
                )
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

    private func metricTile(title: LocalizedStringKey, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title2.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
