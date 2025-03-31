//
//  DarkModeSettingsView.swift
//  NewsAggregator
//
//  Created by Vinays Mac on 3/29/25.
//

import SwiftUI

struct DarkModeSettingsView: View {
    @ObservedObject var viewModel: RSSFeedViewModel

    var body: some View {
        VStack {
            Text("Dark Mode")
                .font(.largeTitle)
                .padding()

            Toggle("Enable Dark Mode", isOn: $viewModel.isDarkModeEnabled)
                .padding()
                .toggleStyle(SwitchToggleStyle(tint: .blue))

            Spacer()
        }
        .navigationTitle("Dark Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
