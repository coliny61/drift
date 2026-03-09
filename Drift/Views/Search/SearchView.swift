import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSearching {
                    ProgressView("Searching...")
                        .tint(AppConstants.Colors.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else if !viewModel.results.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(viewModel.results) { event in
                                NavigationLink(value: AppDestination.event(event.id)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if event.id == viewModel.results.suffix(5).first?.id {
                                        Task { await viewModel.loadMoreResults() }
                                    }
                                }
                            }

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(AppConstants.Colors.accent)
                                    .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                } else {
                    ContentUnavailableView("Search Drift", systemImage: "magnifyingglass", description: Text("Find events, run clubs, sound baths, and more across DFW"))
                }
            }
            .background(AppConstants.Colors.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: Bindable(viewModel).query, prompt: "Events, places, vibes...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showFilters = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? AppConstants.Colors.accent : AppConstants.Colors.textSecondary)
                    }
                    .accessibilityLabel("Filters")
                    .accessibilityHint(hasActiveFilters ? "Filters active" : "No filters applied")
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .event(let id): EventDetailView(eventId: id)
                case .organizer(let id): OrganizerDetailView(organizerId: id)
                case .conversation(let id): DMThreadView(otherUserId: id)
                }
            }
            .sheet(isPresented: Bindable(viewModel).showFilters) {
                FilterSheetView()
            }
        }
    }

    private var hasActiveFilters: Bool {
        !viewModel.selectedCategories.isEmpty || viewModel.selectedCity != nil ||
        viewModel.alcoholFreeOnly || viewModel.freeOnly ||
        viewModel.dateRange != .anytime || viewModel.timeOfDay != .anytime
    }
}
