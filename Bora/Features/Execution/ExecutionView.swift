import SwiftUI

struct ExecutionView: View {
    @State private var viewModel: ExecutionViewModel

    init(viewModel: ExecutionViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.title)
                .font(.title)
            Button("Next") {
                viewModel.next()
            }
        }
        .padding()
        .navigationTitle("Execution")
    }
}
