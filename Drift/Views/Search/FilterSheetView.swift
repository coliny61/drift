import SwiftUI

struct FilterSheetView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline)
                            .foregroundStyle(.white)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(Category.allCases, id: \.self) { category in
                                let isSelected = viewModel.selectedCategories.contains(category)
                                Button {
                                    if isSelected {
                                        viewModel.selectedCategories.remove(category)
                                    } else {
                                        viewModel.selectedCategories.insert(category)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                        Text(category.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? Color(hex: category.color).opacity(0.2) : Color(hex: "2A2A2A"))
                                    .foregroundStyle(isSelected ? Color(hex: category.color) : Color(hex: "9CA3AF"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(isSelected ? Color(hex: category.color).opacity(0.5) : .clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    Divider().background(Color(hex: "2A2A2A"))

                    // Date Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When")
                            .font(.headline)
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            ForEach(SearchViewModel.DateRange.allCases, id: \.self) { range in
                                let isSelected = viewModel.dateRange == range
                                Button {
                                    viewModel.dateRange = range
                                } label: {
                                    Text(range.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color(hex: "FF6B35").opacity(0.2) : Color(hex: "2A2A2A"))
                                        .foregroundStyle(isSelected ? Color(hex: "FF6B35") : Color(hex: "9CA3AF"))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Divider().background(Color(hex: "2A2A2A"))

                    // Distance
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Distance")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(viewModel.maxDistance)) mi")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "FF6B35"))
                        }

                        Slider(value: Bindable(viewModel).maxDistance, in: 1...25, step: 1)
                            .tint(Color(hex: "FF6B35"))
                    }

                    Divider().background(Color(hex: "2A2A2A"))

                    // Toggles
                    VStack(spacing: 16) {
                        Toggle(isOn: Bindable(viewModel).alcoholFreeOnly) {
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(Color(hex: "34D399"))
                                Text("Alcohol-Free Only")
                                    .foregroundStyle(.white)
                            }
                        }
                        .tint(Color(hex: "34D399"))

                        Toggle(isOn: Bindable(viewModel).freeOnly) {
                            HStack(spacing: 8) {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundStyle(Color(hex: "60A5FA"))
                                Text("Free Events Only")
                                    .foregroundStyle(.white)
                            }
                        }
                        .tint(Color(hex: "60A5FA"))
                    }
                }
                .padding()
            }
            .background(Color(hex: "0A0A0A"))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        viewModel.clearFilters()
                    }
                    .foregroundStyle(Color(hex: "9CA3AF"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        viewModel.applyLocalFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "FF6B35"))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
