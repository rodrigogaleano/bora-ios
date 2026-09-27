import SwiftUI

struct WorkoutTypeView: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var viewModel: WorkoutTypeViewModel
    @State private var isShowingSettings = false

    init(viewModel: WorkoutTypeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List(viewModel.types, id: \.self) { type in
            typeRow(type)
        }
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
            }
        }
        .sheet(isPresented: $isShowingSettings) { settingsSheet }
    }

    private func typeRow(_ type: WorkoutType) -> some View {
        Button {
            viewModel.select(type)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: type.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.title)
                    Text(type.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .tint(.primary)
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
