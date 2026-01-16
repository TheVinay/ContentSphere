import SwiftUI
import SwiftUI
import SafariServices

struct FeedDetailView: View {
    let feed: NewsFeed
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false
    @State private var isImplicationsExpanded = false
    @State private var isTimelineExpanded = false
    
    var isBookmarked: Bool {
        viewModel.isBookmarked(feed)
    }
    
    // Generate implications on demand
    private var implications: ArticleImplications? {
        let intelligence = ArticleIntelligenceEngine()
        
        // Try to determine category from source
        var category: FeedCategory? = nil
        var subcategory: InvestingSubcategory? = nil
        var sportsSubcategory: SportsSubcategory? = nil
        
        if let sourceName = feed.sourceName,
           let source = viewModel.feedSources.first(where: { $0.name == sourceName }) {
            category = source.category
            subcategory = source.subcategory
            sportsSubcategory = source.sportsSubcategory
        }
        
        return intelligence.generateImplications(
            for: feed,
            category: category,
            subcategory: subcategory,
            sportsSubcategory: sportsSubcategory
        )
    }
    
    // Generate related articles (Story Timeline)
    private var relatedArticles: [NewsFeed] {
        let keywords = extractKeywords(from: feed.title)
        guard !keywords.isEmpty else { return [] }
        
        let related = viewModel.newsFeeds
            .filter { article in
                article.id != feed.id
            }
            .filter { article in
                let articleKeywords = extractKeywords(from: article.title)
                let overlap = Set(keywords).intersection(Set(articleKeywords))
                return overlap.count >= 1
            }
            .sorted { ($0.postDate ?? Date.distantPast) < ($1.postDate ?? Date.distantPast) }
        
        return related.count >= 2 ? Array(related.prefix(5)) : []
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "from", "as", "is", "was", "are", "be", "been", "has", "have", "had", "will", "would", "can", "could", "may", "might", "must", "should", "this", "that", "these", "those", "it", "its", "s"])
        
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 4 && !stopWords.contains($0) }
        
        return words
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero Image
                    if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .clipped()
                            case .failure(_):
                                placeholderImage
                            case .empty:
                                ProgressView()
                                    .frame(height: 250)
                            @unknown default:
                                placeholderImage
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Source and Date
                        HStack {
                            if let sourceName = feed.sourceName {
                                Label(sourceName, systemImage: "building.2")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                            
                            Spacer()
                            
                            Text(feed.formattedDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Title
                        Text(feed.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(nil)
                        
                        // Story Timeline
                        if !relatedArticles.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isTimelineExpanded.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.subheadline)
                                            .foregroundStyle(.blue)
                                        
                                        Text("Story Timeline")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.blue)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.blue.opacity(0.7))
                                            .rotationEffect(.degrees(isTimelineExpanded ? 90 : 0))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                if isTimelineExpanded {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(relatedArticles) { article in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(article.formattedDate)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                
                                                Text(article.title)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(2)
                                            }
                                            .padding(.leading, 4)
                                            
                                            if article.id != relatedArticles.last?.id {
                                                Divider()
                                                    .padding(.leading, 4)
                                            }
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // What This Means (if available)
                        if let implications = implications, implications.hasImplications {
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isImplicationsExpanded.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.purple)
                                        
                                        Text("What this means")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.purple)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.purple.opacity(0.7))
                                            .rotationEffect(.degrees(isImplicationsExpanded ? 90 : 0))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.purple.opacity(0.1))
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                if isImplicationsExpanded {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(implications.bullets, id: \.self) { bullet in
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("•")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                
                                                Text(bullet)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(nil)
                                            }
                                        }
                                    }
                                    .padding(.leading, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Divider()
                        
                        // Content
                        Text(feed.displayContent)
                            .font(.body)
                            .lineSpacing(4)
                        
                        // Read Full Article Button
                        Button {
                            showSafari = true
                        } label: {
                            HStack {
                                Image(systemName: "safari")
                                Text("Read Full Article")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.markAsRead(feed)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleBookmark(for: feed)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    
                    if let url = URL(string: feed.link) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = URL(string: feed.link) {
                    SafariView(url: url)
                }
            }
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 250)
            .overlay {
                Image(systemName: "newspaper")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
// MARK: - Preview
#Preview {
    FeedDetailView(
        feed: NewsFeed(
            title: "Sample News Article",
            link: "https://example.com",
            thumbnail: nil,
            postDate: Date(),
            content: "This is a sample article content that would be displayed here.",
            sourceName: "Example News",
            description: "Sample description"
        ),
        viewModel: RSSFeedViewModel()
    )
}


