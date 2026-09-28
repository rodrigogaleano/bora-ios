import SwiftUI
import UniformTypeIdentifiers

struct ShareView: View {
    @State private var viewModel: ShareViewModel
    @State private var image: RenderedShareImage?
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ShareViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("Format", selection: $viewModel.format) {
                    ForEach(viewModel.availableFormats, id: \.self) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                preview
                    .frame(maxHeight: .infinity)

                shareButton
            }
            .padding()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await viewModel.loadMap() }
            .task(id: RenderKey(format: viewModel.format, hasMap: viewModel.mapImage != nil)) {
                image = render()
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch viewModel.format {
        case .text:
            ScrollView {
                Text(viewModel.text)
                    .font(.callout.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
        case .map, .sticker:
            if let image {
                Image(uiImage: image.uiImage)
                    .resizable()
                    .scaledToFit()
                    .background(
                        viewModel.format == .sticker ? Color(white: 0.15) : .clear,
                        in: .rect(cornerRadius: 12)
                    )
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        switch viewModel.format {
        case .text:
            ShareLink(item: viewModel.text) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        case .map, .sticker:
            if let image {
                ShareLink(
                    item: image,
                    preview: SharePreview(viewModel.content.title, image: Image(uiImage: image.uiImage))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func render() -> RenderedShareImage? {
        let renderer: ImageRenderer<AnyView>
        switch viewModel.format {
        case .map:
            guard let mapImage = viewModel.mapImage else { return nil }
            renderer = ImageRenderer(content: AnyView(ShareCardView(content: viewModel.content, mapImage: mapImage)))
        case .sticker:
            renderer = ImageRenderer(
                content: AnyView(ShareStickerView(content: viewModel.content, routePoints: viewModel.routePoints))
            )
        case .text:
            return nil
        }
        renderer.scale = 3
        renderer.isOpaque = viewModel.format == .map
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return nil }
        return RenderedShareImage(uiImage: uiImage, pngData: data)
    }
}

private struct RenderKey: Hashable {
    let format: ShareViewModel.Format
    let hasMap: Bool
}

struct RenderedShareImage: Transferable {
    let uiImage: UIImage
    let pngData: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.pngData }
            .suggestedFileName("Bora.png")
    }
}
