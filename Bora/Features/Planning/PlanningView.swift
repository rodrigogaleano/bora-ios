import SwiftUI

struct PlanningView: View {
    @State private var viewModel: PlanningViewModel

    init(viewModel: PlanningViewModel) {
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
        .navigationTitle("Planning")
    }
}
