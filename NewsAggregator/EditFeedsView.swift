//
//  EditFeedsView.swift
//  NewsAggregator
//
//  Created by Vinays Mac on 3/29/25.
//

import SwiftUI

struct EditFeedsView: View {
    @ObservedObject var viewModel: RSSFeedViewModel

    var body: some View {
        List {
            ForEach(FeedCategory.allCases, id: \.self) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(viewModel.feedSources.filter { $0.category == category }) { feed in
                        Toggle(feed.name, isOn: Binding(
                            get: { feed.isSelected },
                            set: { newValue in
                                viewModel.toggleFeedSelection(for: feed)
                            }
                        ))
                    }
                }
            }
        }
        .navigationTitle("Edit Feeds")
        .navigationBarTitleDisplayMode(.inline)
    }
}
