//
//  FeedDetailView.swift
//  NewsAggregator
//
//  Created by Vinays Mac on 3/29/25.
//

import SwiftUI

struct FeedDetailView: View {
    @ObservedObject var viewModel: RSSFeedViewModel // To access bookmarking functionality
    let feed: NewsFeed

    var body: some View {
        VStack {
            // Thumbnail
            if let url = feed.thumbnail, let thumbnailURL = URL(string: url) {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                }
            }

            // Title
            Text(feed.title)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            // Content
            ScrollView {
                Text(feed.content ?? "No content available.")
                    .font(.body)
                    .padding()
            }

            Spacer()

            // Bookmark Button
            Button(action: {
                viewModel.toggleBookmark(for: feed) // Toggles the bookmark state
            }) {
                HStack {
                    Image(systemName: feed.isBookmarked ? "bookmark.fill" : "bookmark")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.orange)
                    Text(feed.isBookmarked ? "Bookmarked" : "Bookmark")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationBarTitle("Feed Details", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: {
                // This back button will be handled automatically in NavigationView
            }) {
                Image(systemName: "arrow.backward")
                    .foregroundColor(.blue)
            }
        )
    }
}

