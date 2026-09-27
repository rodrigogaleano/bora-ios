import SwiftUI

struct DistanceField: View {
    private let title: LocalizedStringKey
    @Binding private var meters: Double
    @State private var unit: DistanceUnit

    init(_ title: LocalizedStringKey, meters: Binding<Double>, initialUnit: DistanceUnit) {
        self.title = title
        _meters = meters
        _unit = State(initialValue: initialUnit)
    }

    var body: some View {
        LabeledContent(title) {
            HStack {
                TextField(title, value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Picker(title, selection: $unit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(verbatim: unit.symbol).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
            }
        }
    }

    private var value: Binding<Double> {
        Binding(
            get: { unit.value(fromMeters: meters) },
            set: { meters = unit.meters(from: $0) }
        )
    }
}
