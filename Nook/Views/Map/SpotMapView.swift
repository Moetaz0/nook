import SwiftUI
import MapKit

private struct DraftPin: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: DraftPin, rhs: DraftPin) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct SpotMapView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: AppConfig.defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )
    @State private var selectedSpot: Spot?
    @State private var droppedPin: DraftPin?
    @State private var addCoordinate: CLLocationCoordinate2D?
    @State private var showAddSpot = false
    @State private var lastTouchPoint: CGPoint?

    var body: some View {
        @Bindable var vm = env.explorer
        NavigationStack {
            ZStack(alignment: .bottom) {
                MapReader { proxy in
                    Map(position: $camera, selection: $selectedSpot) {
                        UserAnnotation()

                        ForEach(vm.filtered) { spot in
                            Annotation(spot.name, coordinate: spot.coordinate, anchor: .bottom) {
                                PixelPin(type: spot.type, selected: selectedSpot?.id == spot.id)
                            }
                            .tag(spot)
                        }

                        if let pin = droppedPin {
                            Annotation("", coordinate: pin.coordinate, anchor: .bottom) {
                                DroppedPinCallout(
                                    coordinate: pin.coordinate,
                                    onAdd: {
                                        addCoordinate = pin.coordinate
                                        showAddSpot = true
                                    },
                                    onClear: {
                                        withAnimation(.snappy) { droppedPin = nil }
                                    }
                                )
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapPitchToggle()
                        MapScaleView()
                    }
                    .onTapGesture { point in
                        placePin(at: point, using: proxy)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                lastTouchPoint = value.location
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.45)
                            .onEnded { _ in
                                if let point = lastTouchPoint {
                                    placePin(at: point, using: proxy)
                                }
                            }
                    )
                }

                // Carte de détail rapide lorsqu'un spot existant est sélectionné
                if let spot = selectedSpot {
                    NavigationLink(value: spot) {
                        SpotRow(spot: spot, distance: spot.distance(from: vm.center))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: selectedSpot?.id)
            .animation(.snappy, value: droppedPin)
            .sensoryFeedback(.impact, trigger: droppedPin?.id)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey("tab.map"))
                        .pixelFont(14)
                        .foregroundStyle(PixelTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addCoordinate = droppedPin?.coordinate
                            ?? env.location.location?.coordinate
                            ?? env.explorer.center?.coordinate
                            ?? AppConfig.defaultCoordinate
                        showAddSpot = true
                    } label: {
                        Image(systemName: "plus.square.fill")
                            .font(.title2)
                            .foregroundStyle(PixelTheme.accent)
                    }
                    .accessibilityLabel(Text("addspot.button"))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Spot.self) { SpotDetailView(spot: $0) }
            .sheet(isPresented: $showAddSpot, onDismiss: {
                droppedPin = nil
            }) {
                AddSpotView(
                    start: addCoordinate
                        ?? env.location.location?.coordinate
                        ?? env.explorer.center?.coordinate
                        ?? AppConfig.defaultCoordinate
                )
            }
            .task {
                env.location.start()
                if let loc = env.location.location {
                    camera = .region(
                        MKCoordinateRegion(
                            center: loc.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                }
                await env.explorer.loadIfNeeded(location: env.location.location)
            }
        }
    }

    private func placePin(at point: CGPoint, using proxy: MapProxy) {
        guard let coord = proxy.convert(point, from: .local) else { return }
        selectedSpot = nil
        droppedPin = DraftPin(coordinate: coord)
    }
}

private struct DroppedPinCallout: View {
    let coordinate: CLLocationCoordinate2D
    let onAdd: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(PixelTheme.ink.opacity(0.75))
                    Button(action: onAdd) {
                        Label {
                            Text("addspot.title")
                        } icon: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .pixelFont(9)
                        .foregroundStyle(PixelTheme.midnight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .pixelFrame(fill: PixelTheme.accent, shadow: false)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(PixelTheme.ink.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .pixelFrame(fill: PixelTheme.surface, shadow: true)

            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundStyle(PixelTheme.accent)
                .background(Circle().fill(PixelTheme.midnight).padding(4))
        }
    }
}						
