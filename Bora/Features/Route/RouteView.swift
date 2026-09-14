import SwiftUI

struct RouteView: View {
    @State private var viewModel: RouteViewModel

    init(viewModel: RouteViewModel) {
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
        .navigationTitle("Route")
    }
}
