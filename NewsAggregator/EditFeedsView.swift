import SwiftUI

import SwiftUI

struct EditFeedsView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFeed = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FeedCategory.allCases, id: \.self) { category in
                    if category == .investing {
                        // Special section for Investing with subcategories
                        Section {
                            ForEach(InvestingSubcategory.allCases, id: \.self) { subcategory in
                                DisclosureGroup {
                                    ForEach(viewModel.feedSources.filter {
                                        $0.category == .investing && $0.subcategory == subcategory
                                    }) { source in
                                        FeedSourceRow(source: source, viewModel: viewModel)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: subcategory.iconName)
                                            .foregroundStyle(.teal)
                                        Text(subcategory.rawValue)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.rawValue)
                            }
                        }
                    } else {
                        // Regular sections for other categories
                        Section {
                            ForEach(viewModel.feedSources.filter { $0.category == category }) { source in
                                FeedSourceRow(source: source, viewModel: viewModel)
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.rawValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Feeds")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddFeed = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddFeed) {
                AddFeedView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Feed Source Row
struct FeedSourceRow: View {
    let source: FeedSource
    @ObservedObject var viewModel: RSSFeedViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.body)
                Text(source.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { source.isSelected },
                set: { _ in
                    viewModel.toggleFeedSelection(for: source)
                }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Add Feed View
struct AddFeedView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var feedName = ""
    @State private var feedURL = ""
    @State private var selectedCategory: FeedCategory = .news
    @State private var selectedSubcategory: InvestingSubcategory? = nil
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Feed Name", text: $feedName)
                    TextField("Feed URL", text: $feedURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                } header: {
                    Text("Feed Information")
                } footer: {
                    Text("Enter the RSS feed URL (e.g., https://example.com/rss)")
                }
                
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(FeedCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    .onChange(of: selectedCategory) { _, newValue in
                        // Reset subcategory if not investing
                        if newValue != .investing {
                            selectedSubcategory = nil
                        }
                    }
                    
                    // Show subcategory picker only for Investing
                    if selectedCategory == .investing {
                        Picker("Subcategory", selection: $selectedSubcategory) {
                            Text("None (All Investing)").tag(nil as InvestingSubcategory?)
                            ForEach(InvestingSubcategory.allCases, id: \.self) { subcategory in
                                Label(subcategory.rawValue, systemImage: subcategory.iconName)
                                    .tag(subcategory as InvestingSubcategory?)
                            }
                        }
                    }
                } header: {
                    Text("Category")
                }
            }
            .navigationTitle("Add Feed Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addFeed()
                    }
                    .disabled(feedName.isEmpty || feedURL.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addFeed() {
        // Validate URL
        guard let _ = URL(string: feedURL) else {
            errorMessage = "Please enter a valid URL"
            showError = true
            return
        }
        
        let newSource = FeedSource(
            name: feedName,
            url: feedURL,
            isSelected: true,
            category: selectedCategory,
            subcategory: selectedSubcategory
        )
        
        viewModel.addFeedSource(newSource)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    EditFeedsView(viewModel: RSSFeedViewModel())
}

