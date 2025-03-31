import SwiftUI

struct BookmarksView: View {
    @ObservedObject var viewModel: RSSFeedViewModel

    var body: some View {
        NavigationView {
            List(viewModel.newsFeeds.filter { $0.isBookmarked }) { feed in
                HStack {
                    if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit).frame(width: 50, height: 50)
                        } placeholder: {
                            Rectangle().foregroundColor(.gray).frame(width: 50, height: 50)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(feed.title).font(.headline)
                        Text(feed.postDate ?? "Unknown Date").font(.subheadline).foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Bookmarks")
        }
    }
}
