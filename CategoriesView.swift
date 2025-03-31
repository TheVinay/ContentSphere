//
//  CategoriesView.swift
//  NewsAggregator
//
//  Created by Vinays Mac on 3/30/25.
//

import SwiftUI

struct CategoriesView: View {
    @ObservedObject var viewModel: RSSFeedViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(FeedCategory.allCases, id: \.self) { category in
                    Toggle(category.rawValue, isOn: .constant(true)) // Replace with real logic
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            .navigationTitle("Categories")
        }
    }
}
