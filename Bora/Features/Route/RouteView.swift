import MapKit
import SwiftUI

struct RouteView: View {
    private static let mapSpace = "routeMap"
    /// How close a drag needs to start to the marker's projected screen position to count as
    /// repositioning it, rather than falling through to the map's own pan gesture.
    private static let startMarkerHitRadius: CGFloat = 32

    @State private var viewModel: RouteViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isDraggingStart = false

    init(viewModel: RouteViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Route")
            .task { await viewModel.requestInitialLocation() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .loadingInitialFix:
            ProgressView("Getting your location…")
        case .failed:
            ContentUnavailableView(
                "Couldn't get your location",
                systemImage: "location.slash",
                description: Text("Check your location permission and try again.")
            )
            .safeAreaInset(edge: .bottom) {
                Button("Try again") {
                    Task { await viewModel.requestInitialLocation() }
                }
                .padding()
            }
        case .ready:
            mapContent
        }
    }

    private var mapContent: some View {
        MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: isDraggingStart ? [] : .all) {
                if let start = viewModel.start {
                    Annotation("Start", coordinate: start.clLocationCoordinate) {
                        startMarker
                    }
                    .annotationTitles(.hidden)
                }
                if let route = viewModel.route, !route.outboundPoints.isEmpty {
                    MapPolyline(coordinates: route.outboundPath.map(\.clLocationCoordinate))
                        .stroke(.blue, lineWidth: 3)
                    MapPolyline(coordinates: route.returnPath.map(\.clLocationCoordinate))
                        .stroke(.blue.opacity(0.35), lineWidth: 3)
                }
            }
            .coordinateSpace(.named(Self.mapSpace))
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard let coordinate = proxy.convert(value.location, from: .local) else { return }
                        viewModel.addPoint(RouteCoordinate(coordinate))
                    }
            )
            // A `DragGesture` attached to the marker's own annotation content never wins against
            // the Map's native pan gesture in SwiftUI's MapKit wrapper, so dragging is observed
            // here instead, as a `simultaneousGesture` on the `Map` itself. It only takes over
            // (and disables the map's own interaction modes for the duration, via
            // `isDraggingStart`) when the touch begins within `startMarkerHitRadius` of the
            // marker's current projected screen position.
            .simultaneousGesture(startMarkerDragGesture(proxy: proxy))
        }
        .safeAreaInset(edge: .bottom) { controls }
    }

    private func startMarkerDragGesture(proxy: MapProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.mapSpace))
            .onChanged { value in
                if !isDraggingStart {
                    guard
                        let start = viewModel.start,
                        let startScreenPoint = proxy.convert(start.clLocationCoordinate, to: .named(Self.mapSpace)),
                        hypot(
                            value.startLocation.x - startScreenPoint.x,
                            value.startLocation.y - startScreenPoint.y
                        ) <= Self.startMarkerHitRadius
                    else { return }
                    isDraggingStart = true
                }
                guard let coordinate = proxy.convert(value.location, from: .named(Self.mapSpace)) else { return }
                viewModel.moveStartPoint(to: RouteCoordinate(coordinate))
            }
            .onEnded { _ in
                isDraggingStart = false
            }
    }

    private var startMarker: some View {
        Circle()
            .fill(.blue)
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(.white, lineWidth: 2))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Text(
                Measurement(value: viewModel.totalDistanceMeters, unit: UnitLength.meters)
                    .formatted(.measurement(width: .abbreviated))
            )
            .font(.headline)
            HStack {
                Button("Redo") { viewModel.redo() }
                Spacer()
                Button("Use this route") { viewModel.next() }
                    .disabled(!viewModel.isValid)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
}
