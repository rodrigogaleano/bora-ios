import SwiftUI

struct PlanningView: View {
    @State private var viewModel: PlanningViewModel

    init(viewModel: PlanningViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            GoalSection(viewModel: viewModel)
            WarmupSection(viewModel: viewModel)
            HIITSection(viewModel: viewModel)
            CooldownSection(viewModel: viewModel)
            HStack {
                Spacer()
                Button("Next") { viewModel.next() }
                    .disabled(!viewModel.isValid)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Planning")
    }
}

private struct GoalSection: View {
    @Bindable var viewModel: PlanningViewModel

    var body: some View {
        Section("Goal") {
            Picker("Type", selection: $viewModel.goalKind) {
                ForEach(PlanningViewModel.GoalKind.allCases, id: \.self) { kind in
                    Text(LocalizedStringKey(kind.label)).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.goalKind {
            case .distance:
                TextField("Distance (m)", value: $viewModel.goalDistanceMeters, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Counts", selection: $viewModel.goalDistanceScope) {
                    Text("Total session").tag(DistanceScope.totalSession)
                    Text("Run only").tag(DistanceScope.runOnly)
                }
            case .time:
                TextField("Duration (min)", value: $viewModel.goalDurationMinutes, format: .number)
                    .keyboardType(.decimalPad)
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
                    durationValue: $viewModel.warmupDurationMinutes,
                    durationUnitLabel: "Duration (min)",
                    distanceMeters: $viewModel.warmupDistanceMeters
                )
            }
        }
    }
}

private struct HIITSection: View {
    @Bindable var viewModel: PlanningViewModel

    var body: some View {
        Section {
            Toggle("HIIT", isOn: $viewModel.isHIITEnabled)
            if viewModel.isHIITEnabled {
                Stepper("Sets: \(viewModel.hiitSets)", value: $viewModel.hiitSets, in: 1...20)
                TargetFieldsView(
                    kind: $viewModel.hiitWorkKind,
                    durationValue: $viewModel.hiitWorkDurationSeconds,
                    durationUnitLabel: "Work (s)",
                    distanceMeters: $viewModel.hiitWorkDistanceMeters
                )
                TargetFieldsView(
                    kind: $viewModel.hiitRestKind,
                    durationValue: $viewModel.hiitRestDurationSeconds,
                    durationUnitLabel: "Rest (s)",
                    distanceMeters: $viewModel.hiitRestDistanceMeters
                )
            }
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
                    durationValue: $viewModel.cooldownDurationMinutes,
                    durationUnitLabel: "Duration (min)",
                    distanceMeters: $viewModel.cooldownDistanceMeters
                )
            }
        }
    }
}

private struct TargetFieldsView: View {
    @Binding var kind: PlanningViewModel.TargetKind
    @Binding var durationValue: Double
    let durationUnitLabel: LocalizedStringKey
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
            TextField(durationUnitLabel, value: $durationValue, format: .number)
                .keyboardType(.decimalPad)
        case .distance:
            TextField("Distance (m)", value: $distanceMeters, format: .number)
                .keyboardType(.decimalPad)
        }
    }
}
