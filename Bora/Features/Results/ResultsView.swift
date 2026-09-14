import SwiftUI

struct ResultsView: View {
    @State private var viewModel: ResultsViewModel

    init(viewModel: ResultsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)
                .font(.title)
            Button("Done") {
                viewModel.done()
            }
        }
        .padding()
        .navigationTitle("Results")
    }
}
