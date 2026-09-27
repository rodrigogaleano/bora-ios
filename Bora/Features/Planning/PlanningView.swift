import SwiftUI

struct PlanningView: View {
    @State private var viewModel: PlanningViewModel

    init(viewModel: PlanningViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            if viewModel.showsGoal {
                GoalSection(viewModel: viewModel)
            }
            WarmupSection(viewModel: viewModel)
            if viewModel.showsHIIT {
                HIITSection(viewModel: viewModel)
            }
            CooldownSection(viewModel: viewModel)
            HStack {
                Spacer()
                Button("Next") { viewModel.next() }
                    .disabled(!viewModel.isValid)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(viewModel.title)
    }
}

private struct GoalSection: View {
    @Bindable var viewModel: PlanningViewModel

    var body: some View {
        Section("Goal") {
            Picker("Type", selection: $viewModel.goalKind) {
                ForEach(viewModel.goalKinds, id: \.self) { kind in
                    Text(LocalizedStringKey(kind.label)).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.goalKind {
            case .distance:
                DistanceField("Distance", meters: $viewModel.goalDistanceMeters, initialUnit: .kilometers)
                Picker("Counts", selection: $viewModel.goalDistanceScope) {
                    Text("Total session").tag(DistanceScope.totalSession)
                    Text("Run only").tag(DistanceScope.runOnly)
                }
            case .time:
                DurationField("Duration", seconds: $viewModel.goalDurationSeconds, maxMinutes: 300)
            case .free:
                EmptyView()
            }
        }
    }
}

private struct WarmupSection: View {
    @Bindable var viewModel: PlanningViewModel

    var body: some View {
        Section {
            Toggle("Warmup", isOn: $viewModel.isWarmupEnabled)
            if viewModel.isWarmupEnabled {
                TargetFieldsView(
                    kind: $viewModel.warmupKind,
                    durationSeconds: $viewModel.warmupDurationSeconds,
                    durationTitle: "Duration",
                    distanceTitle: "Distance",
                    distanceMeters: $viewModel.warmupDistanceMeters
                )
            }
        }
    }
}

private struct HIITSection: View {
    @Bindable var viewModel: PlanningViewModel

    var body: some View {
        Section("Intervals") {
            Stepper("Sets: \(viewModel.hiitSets)", value: $viewModel.hiitSets, in: 1...20)
            TargetFieldsView(
                kind: $viewModel.hiitWorkKind,
                durationSeconds: $viewModel.hiitWorkDurationSeconds,
                durationTitle: "Work",
                distanceTitle: "Work",
                distanceMeters: $viewModel.hiitWorkDistanceMeters
            )
            TargetFieldsView(
                kind: $viewModel.hiitRestKind,
                durationSeconds: $viewModel.hiitRestDurationSeconds,
                durationTitle: "Rest",
                distanceTitle: "Rest",
                distanceMeters: $viewModel.hiitRestDistanceMeters
            )
        }
    }
}

private struct CooldownSection: View {
    @Bindable var viewModel: PlanningViewModel

    var body: some View {
        Section {
            Toggle("Cooldown", isOn: $viewModel.isCooldownEnabled)
            if viewModel.isCooldownEnabled {
                TargetFieldsView(
                    kind: $viewModel.cooldownKind,
                    durationSeconds: $viewModel.cooldownDurationSeconds,
                    durationTitle: "Duration",
                    distanceTitle: "Distance",
                    distanceMeters: $viewModel.cooldownDistanceMeters
                )
            }
        }
    }
}

private struct TargetFieldsView: View {
    @Binding var kind: PlanningViewModel.TargetKind
    @Binding var durationSeconds: Double
    let durationTitle: LocalizedStringKey
    let distanceTitle: LocalizedStringKey
    @Binding var distanceMeters: Double

    var body: some View {
        Picker("Configure by", selection: $kind) {
            ForEach(PlanningViewModel.TargetKind.allCases, id: \.self) { kind in
                Text(LocalizedStringKey(kind.label)).tag(kind)
            }
        }
        .pickerStyle(.segmented)

        switch kind {
        case .duration:
            DurationField(durationTitle, seconds: $durationSeconds)
        case .distance:
            DistanceField(distanceTitle, meters: $distanceMeters, initialUnit: .meters)
        }
    }
}
