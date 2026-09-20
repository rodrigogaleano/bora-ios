import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                AudioSection(viewModel: viewModel)
                MetronomeSection(viewModel: viewModel)
                HapticsSection(viewModel: viewModel)
                GPSSection(viewModel: viewModel)
                Section {
                    Button("Test cues") { viewModel.testCues() }
                    Button("Stop") { viewModel.stopTestCues() }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { viewModel.done() }
                }
            }
        }
    }
}

private struct AudioSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Section("Audio") {
            Toggle("Voice cues", isOn: $viewModel.isVoiceCueEnabled)
            Toggle("Beeps", isOn: $viewModel.isBeepEnabled)
        }
    }
}

private struct MetronomeSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Section {
            Toggle("Metronome", isOn: $viewModel.isMetronomeEnabled)
            if viewModel.isMetronomeEnabled {
                Stepper(
                    value: $viewModel.metronomeBPM,
                    in: RunSettings.bpmRange,
                    step: 5
                ) {
                    Text("\(viewModel.metronomeBPM) BPM")
                        .monospacedDigit()
                }
            }
        } footer: {
            Text("Cadence guide, in steps per minute. Pauses during rest blocks.")
        }
    }
}

private struct HapticsSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Section {
            Toggle("Haptics", isOn: $viewModel.isHapticsEnabled)
        } footer: {
            Text("Vibration only reaches you while the screen is on.")
        }
    }
}

private struct GPSSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Section {
            Picker("GPS accuracy", selection: $viewModel.gpsAccuracy) {
                ForEach(GPSAccuracy.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
        } footer: {
            Text("More accuracy tracks distance and pace better but uses more battery. Applies to your next run.")
        }
    }
}
