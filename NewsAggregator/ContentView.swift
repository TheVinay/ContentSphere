import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RSSFeedViewModel()
    @State private var showSettings = false
    @State private var showBookmarks = false
    @State private var selectedFeed: NewsFeed?
    @State private var isGridView = false
    @State private var showInvestingSubcategories = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(searchText: $viewModel.searchQuery)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Category Tabs
                CategoryTabsView(
                    selectedCategory: $viewModel.selectedCategory,
                    selectedSubcategory: $viewModel.selectedSubcategory,
                    onCategorySelected: { category in
                        // Reset subcategory when changing categories
                        if category != .investing {
                            viewModel.selectedSubcategory = nil
                        }
                        Task {
                            await viewModel.fetchFeeds(for: category)
                        }
                    },
                    onInvestingTapped: {
                        if viewModel.selectedCategory == .investing {
                            showInvestingSubcategories = true
                        }
                    },
                    onSportsTapped: {
                        // Sports preferences - placeholder for now since this view isn't being used
                    },
                    enabledCategories: viewModel.enabledCategories()
                )
                .padding(.vertical, 8)
                
                // Subcategory badge for Investing
                if viewModel.selectedCategory == .investing, let subcategory = viewModel.selectedSubcategory {
                    HStack {
                        InvestingBadge(subcategory: subcategory)
                        
                        Spacer()
                        
                        Button {
                            showInvestingSubcategories = true
                        } label: {
                            Text("Change Topic")
                                .font(.caption)
                                .foregroundStyle(.teal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Content Area
                ZStack {
                    switch viewModel.loadingState {
                    case .idle:
                        EmptyStateView(
                            icon: "newspaper",
                            title: "Select a Category",
                            message: "Choose a category above to start reading news"
                        )
                        
                    case .loading:
                        LoadingView()
                        
                    case .loaded:
                        if viewModel.filteredFeeds().isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "No Results",
                                message: "No articles match your search"
                            )
                        } else {
                            FeedListView(
                                feeds: viewModel.filteredFeeds(),
                                isGridView: isGridView,
                                isBookmarked: { viewModel.isBookmarked($0) },
                                onFeedTapped: { selectedFeed = $0 }
                            )
                        }
                        
                    case .error(let message):
                        EmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "Error",
                            message: message
                        )
                    }
                }
                
                // Bottom Toolbar
                BottomToolbarView(
                    isGridView: $isGridView,
                    onBookmarksTapped: { showBookmarks = true },
                    onRefreshTapped: {
                        Task {
                            await viewModel.refreshFeeds()
                        }
                    }
                )
            }
            .navigationTitle("News Aggregator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarksView(viewModel: viewModel) { feed in
                    selectedFeed = feed
                }
            }
            .sheet(item: $selectedFeed) { feed in
                FeedDetailView(feed: feed, viewModel: viewModel)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showInvestingSubcategories) {
                InvestingSubcategoryView(
                    viewModel: viewModel,
                    selectedSubcategory: $viewModel.selectedSubcategory,
                    onSubcategorySelected: { subcategory in
                        Task {
                            await viewModel.fetchFeeds(for: .investing, subcategory: subcategory)
                        }
                    }
                )
            }
            .preferredColorScheme(viewModel.isDarkModeEnabled ? .dark : .light)
            .task {
                // Load initial feeds
                await viewModel.fetchFeeds()
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search articles...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Feed List View
struct FeedListView: View {
    let feeds: [NewsFeed]
    let isGridView: Bool
    let isBookmarked: (NewsFeed) -> Bool
    let onFeedTapped: (NewsFeed) -> Void
    
    var body: some View {
        ScrollView {
            if isGridView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(feeds) { feed in
                        FeedGridCard(feed: feed, isBookmarked: isBookmarked(feed)) {
                            onFeedTapped(feed)
                        }
                    }
                }
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(feeds) { feed in
                        FeedListCard(feed: feed, isBookmarked: isBookmarked(feed)) {
                            onFeedTapped(feed)
                        }
                    }
                }
                .padding()
            }
        }
        .refreshable {
            // Trigger refresh
        }
    }
}

// MARK: - Feed List Card
struct FeedListCard: View {
    let feed: NewsFeed
    let isBookmarked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    placeholderImage
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Source badge
                    if let sourceName = feed.sourceName {
                        Text(sourceName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                    
                    Text(feed.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                    
                    // "Why This Matters" context
                    if let context = feed.context {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(contextColor(for: context.displayColor))
                            
                            Text(context.reason)
                                .font(.caption)
                                .italic()
                                .foregroundStyle(contextColor(for: context.displayColor))
                                .lineLimit(2)
                        }
                        .padding(.top, 2)
                    }
                    
                    HStack {
                        Text(feed.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func contextColor(for colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "teal": return .teal
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Feed Grid Card
struct FeedGridCard: View {
    let feed: NewsFeed
    let isBookmarked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .frame(height: 120)
                    .clipped()
                } else {
                    placeholderImage
                        .frame(height: 120)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let sourceName = feed.sourceName {
                        Text(sourceName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    
                    Text(feed.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                    
                    // "Why This Matters" context (compact for grid)
                    if let context = feed.context {
                        HStack(alignment: .top, spacing: 3) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(contextColor(for: context.displayColor))
                            
                            Text(context.reason)
                                .font(.system(size: 9))
                                .italic()
                                .foregroundStyle(contextColor(for: context.displayColor))
                                .lineLimit(1)
                        }
                        .padding(.top, 1)
                    }
                    
                    HStack {
                        Text(feed.formattedDate)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func contextColor(for colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "teal": return .teal
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Bottom Toolbar
struct BottomToolbarView: View {
    @Binding var isGridView: Bool
    let onBookmarksTapped: () -> Void
    let onRefreshTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 32) {
            ToolbarButton(
                icon: "bookmark.fill",
                label: "Saved",
                color: .orange,
                action: onBookmarksTapped
            )
            
            ToolbarButton(
                icon: "arrow.clockwise",
                label: "Refresh",
                color: .blue,
                action: onRefreshTapped
            )
            
            ToolbarButton(
                icon: isGridView ? "square.grid.2x2" : "list.bullet",
                label: isGridView ? "Grid" : "List",
                color: .purple,
                action: { isGridView.toggle() }
            )
        }
        .padding()
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(color)
            }
        }
    }
}
// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading articles...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

