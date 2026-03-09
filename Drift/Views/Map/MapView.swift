import SwiftUI
import MapKit

struct DriftMapView: View {
    @Environment(MapViewModel.self) private var viewModel
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        ZStack(alignment: .top) {
            // Map
            Map(position: Bindable(viewModel).cameraPosition) {
                // User location
                UserAnnotation()

                // Clustered event pins
                ForEach(viewModel.clusters) { cluster in
                    if cluster.isSingle, let event = cluster.event {
                        Annotation(event.title, coordinate: CLLocationCoordinate2D(
                            latitude: event.locationLat,
                            longitude: event.locationLng
                        )) {
                            EventPinView(
                                event: event,
                                isSelected: viewModel.selectedEvent?.id == event.id
                            )
                            .onTapGesture {
                                viewModel.selectEvent(event)
                            }
                        }
                    } else {
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: cluster.centerLat,
                            longitude: cluster.centerLng
                        )) {
                            ClusterPinView(count: cluster.count)
                                .onTapGesture {
                                    // Zoom into the cluster
                                    withAnimation {
                                        viewModel.cameraPosition = .region(
                                            MKCoordinateRegion(
                                                center: CLLocationCoordinate2D(latitude: cluster.centerLat, longitude: cluster.centerLng),
                                                span: MKCoordinateSpan(
                                                    latitudeDelta: viewModel.region.span.latitudeDelta * 0.4,
                                                    longitudeDelta: viewModel.region.span.longitudeDelta * 0.4
                                                )
                                            )
                                        )
                                    }
                                }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                viewModel.updateRegion(context.region)
            }
            .ignoresSafeArea(edges: .bottom)

            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChipView(
                        title: "All",
                        icon: "square.grid.2x2",
                        isSelected: viewModel.selectedCategory == nil,
                        color: AppConstants.Colors.accent
                    ) {
                        viewModel.selectCategory(nil)
                    }

                    ForEach(Category.allCases, id: \.self) { category in
                        CategoryChipView(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: viewModel.selectedCategory == category,
                            color: Color(hex: category.color)
                        ) {
                            viewModel.selectCategory(
                                viewModel.selectedCategory == category ? nil : category
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial)
        }
        .overlay(alignment: .bottom) {
            // Selected event card
            if let event = viewModel.selectedEvent {
                NavigationLink(value: AppDestination.event(event.id)) {
                    MapEventCardView(event: event)
                }
                .buttonStyle(.plain)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.selectedEvent?.id)
        .task {
            if viewModel.events.isEmpty {
                await viewModel.loadEvents()
            }
        }
        .onTapGesture {
            if viewModel.selectedEvent != nil {
                viewModel.selectEvent(nil)
            }
        }
    }
}
