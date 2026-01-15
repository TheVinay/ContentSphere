import SwiftUI
import SwiftUI
import SafariServices

struct FeedDetailView: View {
    let feed: NewsFeed
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSafari = false
    
    var isBookmarked: Bool {
        viewModel.isBookmarked(feed)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Bookmark Button
                        Button {
                            viewModel.toggleBookmark(for: feed)
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(isBookmarked ? .orange : .blue)
                        }
                        
                        // Share Button
                        if let url = URL(string: feed.link) {
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.blue)
                            }
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


