//
//  Trending.swift
//  NewsAggregator
//
//  Created by Vinays Mac on 3/30/25.
//

import SwiftUI

struct TrendingView: View {
    @ObservedObject var viewModel: RSSFeedViewModel

    var body: some View {
        NavigationView {
            List(viewModel.newsFeeds) { feed in
                VStack(alignment: .leading) {
                    Text(feed.title).font(.headline)
                    Text(feed.postDate ?? "Unknown Date").font(.subheadline).foregroundColor(.gray)
                }
            }
            .navigationTitle("Trending")
        }
    }
}
