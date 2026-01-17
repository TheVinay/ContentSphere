import SwiftUI

// MARK: - Saved View
struct SavedView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @State private var selectedFeed: NewsFeed?
    @State private var selectedFilter: SavedFilter = .all
    
    var bookmarkedFeeds: [NewsFeed] {
        let feeds = viewModel.newsFeeds.filter { viewModel.isBookmarked($0) }
        
        switch selectedFilter {
        case .all:
            return feeds
        case .today:
            return feeds.filter { feed in
                guard let date = feed.postDate else { return false }
                return Calendar.current.isDateInToday(date)
            }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            return feeds.filter { feed in
                guard let date = feed.postDate else { return false }
                return date >= weekAgo
            }
        case .withImages:
            return feeds.filter { $0.thumbnail != nil }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SavedFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding()
                }
                
                // Content
                Group {
                    if bookmarkedFeeds.isEmpty {
                        EmptyBookmarksView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(bookmarkedFeeds) { feed in
                                    SavedArticleCard(feed: feed, viewModel: viewModel) {
                                        selectedFeed = feed
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedFeed) { feed in
                FeedDetailView(feed: feed, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Saved Filter
enum SavedFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case withImages = "With Images"
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Saved Article Card
struct SavedArticleCard: View {
    let feed: NewsFeed
    @ObservedObject var viewModel: RSSFeedViewModel
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
                    if let sourceName = feed.sourceName {
                        Text(sourceName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                    
                    Text(feed.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                    
                    Text(feed.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
                
                // Remove bookmark button
                Button {
                    withAnimation {
                        viewModel.toggleBookmark(for: feed)
                    }
                } label: {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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

// MARK: - Preview
#Preview {
    SavedView(viewModel: RSSFeedViewModel())
}
