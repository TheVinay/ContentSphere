import SwiftUI

// MARK: - Headlines View
struct HeadlinesView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @State private var selectedFeed: NewsFeed?
    
    var topHeadlines: [NewsFeed] {
        let now = Date()
        let sixHoursAgo = Calendar.current.date(byAdding: .hour, value: -6, to: now)!
        
        return viewModel.newsFeeds
            .filter { feed in
                guard let date = feed.postDate else { return false }
                return date > sixHoursAgo
            }
            .sorted { feed1, feed2 in
                guard let date1 = feed1.postDate, let date2 = feed2.postDate else {
                    return feed1.postDate != nil
                }
                return date1 > date2
            }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if topHeadlines.isEmpty {
                    EmptyHeadlinesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Hero Headline
                            if let first = topHeadlines.first {
                                HeroHeadlineCard(feed: first) {
                                    selectedFeed = first
                                }
                            }
                            
                            // Top 10 Headlines
                            ForEach(Array(topHeadlines.dropFirst().prefix(9))) { feed in
                                HeadlineCard(feed: feed) {
                                    selectedFeed = feed
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Headlines")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.fetchAllCategories()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(item: $selectedFeed) { feed in
                FeedDetailView(feed: feed, viewModel: viewModel)
                    .presentationDragIndicator(.visible)
            }
            .task {
                if viewModel.newsFeeds.isEmpty {
                    await viewModel.fetchAllCategories()
                }
            }
        }
    }
}

// MARK: - Hero Headline Card
struct HeroHeadlineCard: View {
    let feed: NewsFeed
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
                                .frame(height: 300)
                                .clipped()
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            ZStack {
                                Color(.systemGray6)
                                ProgressView()
                            }
                            .frame(height: 300)
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 300)
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Breaking News Badge
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("BREAKING")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(20)
                    
                    Text(feed.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                    
                    // "Why This Matters" context
                    if let context = feed.context {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                            
                            Text(context.reason)
                                .font(.subheadline)
                                .italic()
                                .lineLimit(2)
                        }
                        .foregroundStyle(.yellow.opacity(0.95))
                        .padding(.top, 4)
                    }
                    
                    HStack {
                        if let source = feed.sourceName {
                            Text(source)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("•")
                        
                        Text(feed.formattedDate)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(20)
            }
            .frame(height: 300)
            .cornerRadius(16)
            .shadow(radius: 10)
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
            .frame(height: 300)
            .overlay {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.5))
            }
    }
}

// MARK: - Headline Card
struct HeadlineCard: View {
    let feed: NewsFeed
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
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    placeholderImage
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(feed.title)
                        .font(.headline)
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
                        if let source = feed.sourceName {
                            Text(source)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text(feed.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

// MARK: - Empty Headlines View
struct EmptyHeadlinesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("No Recent Headlines")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Check back soon for the latest breaking news from all categories")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Preview
#Preview {
    HeadlinesView(viewModel: RSSFeedViewModel())
}
