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
            CheckpointsSection(viewModel: viewModel)
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

private struct CheckpointsSection: View {
    @Bindable var viewModel: PlanningViewModel

    var body: some View {
        Section {
            Toggle("Transition warning", isOn: $viewModel.checkpoints.isTransitionWarningEnabled)
            if viewModel.showsProgressCheckpoints {
                HStack {
                    Text("Progress")
                    Spacer()
                    ForEach(ProgressCheckpoint.allCases, id: \.self) { checkpoint in
                        Toggle(isOn: binding(for: checkpoint)) {
                            Text(verbatim: "\(checkpoint.rawValue)%")
                        }
                        .toggleStyle(.button)
                    }
                }
                Toggle("Final stretch", isOn: $viewModel.checkpoints.isFinalStretchEnabled)
            }
            Toggle("Kilometer splits", isOn: $viewModel.checkpoints.isKilometerSplitEnabled)
            if viewModel.showsRepSummary {
                Toggle("Rep summary", isOn: $viewModel.checkpoints.isRepSummaryEnabled)
            }
        } header: {
            Text("Checkpoints")
        } footer: {
            Text("Progress, final stretch, splits and rep summaries play during work blocks and free runs.")
        }
    }

    private func binding(for checkpoint: ProgressCheckpoint) -> Binding<Bool> {
        Binding(
            get: { viewModel.checkpoints.progress.contains(checkpoint) },
            set: { viewModel.setProgressCheckpoint(checkpoint, isOn: $0) }
        )
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
