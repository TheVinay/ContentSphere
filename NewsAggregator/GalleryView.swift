import SwiftUI

// MARK: - Gallery View
struct GalleryView: View {
    let feeds: [NewsFeed]
    let isBookmarked: (NewsFeed) -> Bool
    let onFeedTapped: (NewsFeed) -> Void
    @State private var selectedIndex: Int = 0
    
    // Only show feeds with images
    private var feedsWithImages: [NewsFeed] {
        feeds.filter { $0.thumbnail != nil }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if feedsWithImages.isEmpty {
                EmptyGalleryView()
            } else {
                // Main swipeable gallery
                TabView(selection: $selectedIndex) {
                    ForEach(Array(feedsWithImages.enumerated()), id: \.element.id) { index, feed in
                        GalleryCard(
                            feed: feed,
                            isBookmarked: isBookmarked(feed),
                            onTap: { onFeedTapped(feed) }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom info bar
                GalleryInfoBar(
                    currentIndex: selectedIndex,
                    totalCount: feedsWithImages.count,
                    currentFeed: feedsWithImages[safe: selectedIndex]
                )
            }
        }
    }
}

// MARK: - Gallery Card
struct GalleryCard: View {
    let feed: NewsFeed
    let isBookmarked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Background Image
                if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            ZStack {
                                Color(.systemGray6)
                                ProgressView()
                            }
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 200)
                
                // Content overlay
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Source badge
                        if let sourceName = feed.sourceName {
                            Text(sourceName)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.9))
                                .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Bookmark indicator
                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(.orange)
                                .font(.title3)
                        }
                    }
                    
                    // Title
                    Text(feed.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .shadow(radius: 10)
                    
                    // Date
                    Text(feed.formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.5))
            }
    }
}

// MARK: - Gallery Info Bar
struct GalleryInfoBar: View {
    let currentIndex: Int
    let totalCount: Int
    let currentFeed: NewsFeed?
    
    var body: some View {
        HStack {
            // Counter
            Text("\(currentIndex + 1) / \(totalCount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            
            Spacer()
            
            // Quick info
            if let feed = currentFeed {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(feed.formattedDate)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground).opacity(0.95))
    }
}

// MARK: - Empty Gallery View
struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Images Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Articles with images will appear here in a beautiful gallery format")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Gallery Grid View (Alternative)
struct GalleryGridView: View {
    let feeds: [NewsFeed]
    let isBookmarked: (NewsFeed) -> Bool
    let onFeedTapped: (NewsFeed) -> Void
    @State private var selectedFeed: NewsFeed?
    
    private var feedsWithImages: [NewsFeed] {
        feeds.filter { $0.thumbnail != nil }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(feedsWithImages) { feed in
                    Button {
                        selectedFeed = feed
                    } label: {
                        GalleryGridCard(feed: feed, isBookmarked: isBookmarked(feed))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .fullScreenCover(item: $selectedFeed) { feed in
            GalleryFullScreenView(
                feeds: feedsWithImages,
                selectedFeed: feed,
                isBookmarked: isBookmarked,
                onFeedTapped: onFeedTapped
            )
        }
    }
}

// MARK: - Gallery Grid Card
struct GalleryGridCard: View {
    let feed: NewsFeed
    let isBookmarked: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_), .empty, _:
                        Color(.systemGray5)
                    }
                }
            } else {
                Color(.systemGray5)
            }
            
            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.orange)
                    .padding(8)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Full Screen Gallery View
struct GalleryFullScreenView: View {
    let feeds: [NewsFeed]
    let selectedFeed: NewsFeed
    let isBookmarked: (NewsFeed) -> Bool
    let onFeedTapped: (NewsFeed) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    
    init(feeds: [NewsFeed], selectedFeed: NewsFeed, isBookmarked: @escaping (NewsFeed) -> Bool, onFeedTapped: @escaping (NewsFeed) -> Void) {
        self.feeds = feeds
        self.selectedFeed = selectedFeed
        self.isBookmarked = isBookmarked
        self.onFeedTapped = onFeedTapped
        _currentIndex = State(initialValue: feeds.firstIndex(where: { $0.id == selectedFeed.id }) ?? 0)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(feeds.enumerated()), id: \.element.id) { index, feed in
                    ZStack {
                        if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure(_), .empty, _:
                                    Color.black
                                }
                            }
                        }
                    }
                    .tag(index)
                    .onTapGesture {
                        onFeedTapped(feed)
                        dismiss()
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()
            }
        }
    }
}

// MARK: - View Mode Enum
enum ViewMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
    case gallery = "Gallery"
    
    var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        case .gallery: return "photo.on.rectangle.angled"
        }
    }
}

// MARK: - Helper Extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    GalleryView(
        feeds: [
            NewsFeed(title: "Sample", link: "https://example.com", thumbnail: nil, postDate: Date(), sourceName: "Test")
        ],
        isBookmarked: { _ in false },
        onFeedTapped: { _ in }
    )
}
