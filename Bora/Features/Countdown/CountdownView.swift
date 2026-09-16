import SwiftUI

struct CountdownView: View {
    @State private var viewModel: CountdownViewModel

    init(viewModel: CountdownViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(viewModel.count, format: .number)
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
            Spacer()
            Button("Cancel") {
                viewModel.cancel()
            }
        }
        .padding()
        .navigationBarBackButtonHidden()
        .task { viewModel.start() }
    }
}
