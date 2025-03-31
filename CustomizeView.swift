//
//  CustomizeView.swift
//  NewsAggregator
//
//  Created by Vinays Mac on 3/30/25.
//

import SwiftUI

struct CustomizeView: View {
    @Binding var isGridView: Bool

    var body: some View {
        VStack {
            Toggle("Grid View", isOn: $isGridView)
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                .padding()
            Spacer()
        }
        .navigationTitle("Customize View")
        .navigationBarTitleDisplayMode(.inline)
    }
}
