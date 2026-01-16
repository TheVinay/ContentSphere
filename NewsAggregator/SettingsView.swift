import SwiftUI

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditFeeds = false
    @State private var showInsights = false
    @State private var showCategories = false
    
    var body: some View {
        NavigationView {
            List {
                // Insights Section
                Section {
                    Button {
                        showInsights = true
                    } label: {
                        Label("Insights", systemImage: "chart.bar.fill")
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Activity")
                } footer: {
                    Text("View your reading and puzzle activity")
                }
                
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
                        showCategories = true
                    } label: {
                        Label("Manage Categories", systemImage: "square.grid.2x2")
                    }
                    .foregroundStyle(.primary)
                    
                    Button {
                        showEditFeeds = true
                    } label: {
                        Label("Manage Feed Sources", systemImage: "list.bullet.rectangle")
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Content")
                } footer: {
                    Text("Customize categories and feed sources")
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
            .sheet(isPresented: $showInsights) {
                InsightsView(activityTracker: viewModel.activityTracker, signalEngine: viewModel.signalEngine)
            }
            .sheet(isPresented: $showCategories) {
                CategoryManagementView(viewModel: viewModel)
            }
        }
    }
}
// MARK: - Preview
#Preview {
    SettingsView(viewModel: RSSFeedViewModel())
}

