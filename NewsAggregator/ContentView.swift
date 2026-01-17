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
                    .padding(.top, 6)
                
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
                    onBookmarksTapped: { showBookmarks = true }
                )
            }
            .navigationTitle("News Aggregator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await viewModel.refreshFeeds()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            isGridView.toggle()
                        } label: {
                            Label(isGridView ? "Switch to List" : "Switch to Grid", 
                                  systemImage: isGridView ? "list.bullet" : "square.grid.2x2")
                        }
                        
                        Divider()
                        
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
            HStack(alignment: .top, spacing: 14) {
                // Thumbnail - larger with better aspect ratio
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
                    .frame(width: 120, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    placeholderImage
                        .frame(width: 120, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Source badge
                    if let sourceName = feed.sourceName {
                        Text(sourceName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(6)
                    }
                    
                    Text(feed.title)
                        .font(.body)
                        .fontWeight(.bold)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                    
                    // "Why This Matters" context
                    if let context = feed.context {
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(contextColor(for: context.displayColor))
                            
                            Text(context.reason)
                                .font(.caption)
                                .italic()
                                .foregroundStyle(contextColor(for: context.displayColor))
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(contextColor(for: context.displayColor).opacity(0.08))
                        .cornerRadius(6)
                    }
                    
                    Spacer(minLength: 0)
                    
                    HStack(spacing: 8) {
                        Text(feed.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // Location badge
                        if let location = feed.location {
                            HStack(spacing: 3) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption2)
                                Text(location.detectedLocation)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(5)
                        }
                        
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
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
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
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail
                ZStack(alignment: .topTrailing) {
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
                        .frame(height: 140)
                        .clipped()
                    } else {
                        placeholderImage
                            .frame(height: 140)
                    }
                    
                    // Bookmark badge on image
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(.orange, in: Circle())
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    if let sourceName = feed.sourceName {
                        Text(sourceName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(5)
                    }
                    
                    Text(feed.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                    
                    // "Why This Matters" context (compact)
                    if let context = feed.context {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(contextColor(for: context.displayColor))
                            
                            Text(context.reason)
                                .font(.caption2)
                                .italic()
                                .foregroundStyle(contextColor(for: context.displayColor))
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(contextColor(for: context.displayColor).opacity(0.08))
                        .cornerRadius(5)
                    }
                    
                    Spacer(minLength: 0)
                    
                    HStack(spacing: 6) {
                        Text(feed.formattedDate)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        // Location badge (compact)
                        if feed.location != nil {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
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
            .fill(LinearGradient(colors: [.gray.opacity(0.2), .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
    }
}

// MARK: - Bottom Toolbar
struct BottomToolbarView: View {
    let onBookmarksTapped: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            ToolbarButton(
                icon: "bookmark.fill",
                label: "Saved",
                color: .orange,
                action: onBookmarksTapped
            )
            
            Spacer()
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

