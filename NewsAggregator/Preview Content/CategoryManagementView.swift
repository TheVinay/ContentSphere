import SwiftUI

struct CategoryManagementView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.categoryPreferences) { pref in
                    HStack {
                        Image(systemName: pref.category.iconName)
                            .foregroundStyle(categoryColor(pref.category.color))
                            .frame(width: 30)
                        
                        Text(pref.category.rawValue)
                        
                        Spacer()
                        
                        Toggle("", isOn: binding(for: pref.category))
                            .labelsHidden()
                    }
                }
                .onMove { source, destination in
                    var updatedPrefs = viewModel.categoryPreferences
                    updatedPrefs.move(fromOffsets: source, toOffset: destination)
                    
                    viewModel.categoryPreferences = updatedPrefs.enumerated().map { index, pref in
                        CategoryPreference(id: pref.id, category: pref.category, isEnabled: pref.isEnabled, priority: index)
                    }
                    viewModel.saveCategoryPreferences()
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if editMode == .active {
                        Button("Done") {
                            editMode = .inactive
                        }
                    } else {
                        Button("Edit") {
                            editMode = .active
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func binding(for category: FeedCategory) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.categoryPreferences.first(where: { $0.category == category })?.isEnabled ?? true
            },
            set: { newValue in
                if let index = viewModel.categoryPreferences.firstIndex(where: { $0.category == category }) {
                    viewModel.categoryPreferences[index].isEnabled = newValue
                    viewModel.saveCategoryPreferences()
                    
                    // If disabling current category, switch to first enabled one
                    if !newValue && viewModel.selectedCategory == category {
                        if let firstEnabled = viewModel.enabledCategories().first {
                            viewModel.selectedCategory = firstEnabled
                            Task {
                                await viewModel.fetchFeeds(for: firstEnabled)
                            }
                        }
                    }
                }
            }
        )
    }
    
    private func categoryColor(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "teal": return .teal
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

#Preview {
    CategoryManagementView(viewModel: RSSFeedViewModel())
}
