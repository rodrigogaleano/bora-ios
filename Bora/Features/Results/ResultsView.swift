import SwiftUI

struct ResultsView: View {
    @State private var viewModel: ResultsViewModel

    init(viewModel: ResultsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                summary
            }
            if !viewModel.splitRows.isEmpty {
                Section("Splits") {
                    ForEach(viewModel.splitRows) { row in
                        splitRow(row)
                    }
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarBackButtonHidden()
        .safeAreaInset(edge: .bottom) {
            Button("Done") { viewModel.done() }
                .buttonStyle(.borderedProminent)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
        }
    }

    private var summary: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(viewModel.totalDistance)
                    .font(.largeTitle.monospacedDigit())
                Text("Total distance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 16) {
                metricTile(title: "Duration", value: viewModel.totalDuration)
                metricTile(title: "Avg pace", value: viewModel.averagePace)
                metricTile(title: "Best pace", value: viewModel.bestPace)
            }
        }
        .padding(.vertical, 8)
    }

    private func splitRow(_ row: ResultsViewModel.SplitRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.title)
            Text(verbatim: "\(row.distance) · \(row.duration) · \(row.pace)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func metricTile(title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
