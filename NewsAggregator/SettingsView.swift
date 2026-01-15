import SwiftUI

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditFeeds = false
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section {
                    Toggle(isOn: $viewModel.isDarkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                    .tint(.blue)
                    .onChange(of: viewModel.isDarkModeEnabled) { _, _ in
                        viewModel.toggleDarkMode()
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Enable dark mode for a more comfortable reading experience in low light")
                }
                
                // Feed Sources Section
                Section {
                    Button {
                        showEditFeeds = true
                    } label: {
                        Label("Manage Feed Sources", systemImage: "list.bullet.rectangle")
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Content")
                } footer: {
                    Text("Add, remove, or toggle feed sources for each category")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total Sources")
                        Spacer()
                        Text("\(viewModel.feedSources.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Active Sources")
                        Spacer()
                        Text("\(viewModel.feedSources.filter { $0.isSelected }.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditFeeds) {
                EditFeedsView(viewModel: viewModel)
            }
        }
    }
}
// MARK: - Preview
#Preview {
    SettingsView(viewModel: RSSFeedViewModel())
}

