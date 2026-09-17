import SwiftUI

struct SummaryView: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var viewModel: SummaryViewModel
    @State private var isShowingRoute = false
    @State private var isShowingSettings = false

    init(viewModel: SummaryViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section { header }
            if let goalNote = viewModel.goalNote {
                Section { goalNoteRow(goalNote) }
            }
            Section {
                ForEach(viewModel.blockRows) { blockRow($0) }
            }
            Section { routeRow }
        }
        .navigationTitle("Summary")
        .safeAreaInset(edge: .bottom) { footer }
        .sheet(isPresented: $isShowingRoute) { routeSheet }
        .sheet(isPresented: $isShowingSettings) { settingsSheet }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title)
                .font(.title2.bold())
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func goalNoteRow(_ goalNote: SummaryViewModel.GoalNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goalNote.title)
                .font(.subheadline.weight(.semibold))
            Text(goalNote.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func blockRow(_ row: SummaryViewModel.BlockRow) -> some View {
        HStack(spacing: 16) {
            Text(row.badge)
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(width: 28, alignment: .leading)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                if let detail = row.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(row.trailing)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var routeRow: some View {
        Button {
            isShowingRoute = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Route")
                    Text(viewModel.routeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .tint(.primary)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button("Start run") { viewModel.start() }
                .buttonStyle(.borderedProminent)
            Button("Audio and feedback") { isShowingSettings = true }
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }

    private var routeSheet: some View {
        NavigationStack {
            RouteView(
                viewModel: RouteViewModel(
                    locationProvider: dependencies.locationProvider,
                    existingRoute: viewModel.route,
                    onDone: { route in
                        viewModel.routeChosen(route)
                        isShowingRoute = false
                    }
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isShowingRoute = false }
                }
            }
        }
    }

    private var settingsSheet: some View {
        SettingsView(
            viewModel: SettingsViewModel(
                store: dependencies.settingsStore,
                cuePlayer: dependencies.cuePlayer,
                onDone: { isShowingSettings = false }
            )
        )
    }
}
