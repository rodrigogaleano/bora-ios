import SwiftUI

struct DurationField: View {
    private let title: LocalizedStringKey
    @Binding private var seconds: Double
    private let maxMinutes: Int
    @State private var isExpanded = false

    init(_ title: LocalizedStringKey, seconds: Binding<Double>, maxMinutes: Int = 180) {
        self.title = title
        _seconds = seconds
        self.maxMinutes = maxMinutes
    }

    var body: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            LabeledContent(title) {
                Text(verbatim: RunFormatting.duration(seconds))
                    .monospacedDigit()
                    .foregroundStyle(isExpanded ? Color.accentColor : .secondary)
            }
        }
        .tint(.primary)

        if isExpanded {
            HStack(spacing: 0) {
                wheel(selection: minutes, range: 0...maxMinutes, unit: .minutes)
                wheel(selection: remainingSeconds, range: 0...59, unit: .seconds)
            }
        }
    }

    private func wheel(selection: Binding<Int>, range: ClosedRange<Int>, unit: UnitDuration) -> some View {
        Picker(title, selection: selection) {
            ForEach(Array(range), id: \.self) { value in
                Text(verbatim: value.formatted()).tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .overlay(alignment: .trailing) {
            Text(verbatim: unit.symbol)
                .foregroundStyle(.secondary)
                .padding(.trailing, 24)
        }
    }

    private var totalSeconds: Int {
        max(0, Int(seconds.rounded()))
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { min(totalSeconds / 60, maxMinutes) },
            set: { seconds = Double($0 * 60 + totalSeconds % 60) }
        )
    }

    private var remainingSeconds: Binding<Int> {
        Binding(
            get: { totalSeconds % 60 },
            set: { seconds = Double(min(totalSeconds / 60, maxMinutes) * 60 + $0) }
        )
    }
}
