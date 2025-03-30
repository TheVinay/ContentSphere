import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: RSSFeedViewModel

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Options")) {
                    NavigationLink(destination: DarkModeSettingsView(viewModel: viewModel)) {
                        Text("Dark Mode")
                    }

                    NavigationLink(destination: EditFeedsView(viewModel: viewModel)) {
                        Text("Edit Feeds")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
