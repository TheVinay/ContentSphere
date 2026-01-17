import SwiftUI

// MARK: - Sports Preferences View
struct SportsPreferencesView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var preferences: [SportsPreference]
    
    init(viewModel: RSSFeedViewModel) {
        self.viewModel = viewModel
        _preferences = State(initialValue: viewModel.sportsPreferences)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Choose which sports to follow and drag to reorder by priority")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    ForEach($preferences) { $preference in
                        SportsPreferenceRow(preference: $preference)
                    }
                    .onMove { from, to in
                        preferences.move(fromOffsets: from, toOffset: to)
                        updatePriorities()
                    }
                } header: {
                    Text("Your Sports")
                } footer: {
                    Text("Enabled sports will appear in your feed. Drag to reorder by priority.")
                }
            }
            .navigationTitle("Sports Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.sportsPreferences = preferences
                        Task {
                            await viewModel.fetchFeeds(for: .sports)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func updatePriorities() {
        for (index, _) in preferences.enumerated() {
            preferences[index].priority = index
        }
    }
}

// MARK: - Sports Preference Row
struct SportsPreferenceRow: View {
    @Binding var preference: SportsPreference
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: preference.subcategory.iconName)
                .font(.title3)
                .foregroundStyle(preference.isEnabled ? .green : .secondary)
                .frame(width: 30)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(preference.subcategory.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(preference.subcategory.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $preference.isEnabled)
                .labelsHidden()
        }
    }
}

// MARK: - Preview
#Preview {
    SportsPreferencesView(viewModel: RSSFeedViewModel())
}
