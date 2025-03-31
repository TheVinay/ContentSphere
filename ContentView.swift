import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RSSFeedViewModel()
    @State private var selectedCategory: FeedCategory = .News
    @State private var showSettings = false
    @State private var showBookmarks = false
    @State private var showCategories = false
    @State private var showTrending = false
    @State private var showCustomize = false
    @State private var isGridView = false
    @State private var selectedFeed: NewsFeed?

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search feeds...", text: $viewModel.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    Button(action: {
                        // Search functionality is tied to the searchQuery in viewModel
                    }) {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top)

                // Scrollable Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(FeedCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                viewModel.fetchRSSFeeds(for: category)
                            }) {
                                Text(category.rawValue)
                                    .fontWeight(selectedCategory == category ? .bold : .regular)
                                    .padding()
                                    .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Feeds List (List vs Grid View)
                if isGridView {
                    // Example grid view
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                            ForEach(viewModel.searchFeeds()) { feed in
                                VStack {
                                    if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fit).frame(height: 150)
                                        } placeholder: {
                                            Rectangle().foregroundColor(.gray).frame(height: 150)
                                        }
                                    }
                                    Text(feed.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 5)
                                }
                                .onTapGesture {
                                    selectedFeed = feed
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    List(viewModel.searchFeeds()) { feed in
                        Button(action: {
                            selectedFeed = feed
                        }) {
                            HStack {
                                if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().aspectRatio(contentMode: .fit).frame(width: 50, height: 50)
                                    } placeholder: {
                                        Rectangle().foregroundColor(.gray).frame(width: 50, height: 50)
                                    }
                                }
                                VStack(alignment: .leading) {
                                    Text(feed.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(feed.postDate ?? "Unknown Date")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                        }
                    }
                }

                // Action Buttons
                HStack(spacing: 20) {
                    // Bookmark Button
                    Button(action: {
                        showBookmarks = true
                    }) {
                        VStack {
                            Image(systemName: "bookmark")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.orange)
                            Text("Bookmark")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .sheet(isPresented: $showBookmarks) {
                        BookmarksView(viewModel: viewModel)
                    }

                    // Share Button
                    Button(action: {
                        if let link = selectedFeed?.link, let url = URL(string: link) {
                            let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            UIApplication.shared.windows.first?.rootViewController?.present(activityController, animated: true, completion: nil)
                        }
                    }) {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            Text("Share")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    // Categories Button
                    Button(action: {
                        showCategories = true
                    }) {
                        VStack {
                            Image(systemName: "list.bullet.rectangle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.green)
                            Text("Categories")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .sheet(isPresented: $showCategories) {
                        CategoriesView(viewModel: viewModel)
                    }

                    // Trending Button
                    Button(action: {
                        showTrending = true
                    }) {
                        VStack {
                            Image(systemName: "flame")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.red)
                            Text("Trending")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .sheet(isPresented: $showTrending) {
                        TrendingView(viewModel: viewModel)
                    }

                    Button(action: {
                        if let feed = selectedFeed {
                            viewModel.toggleBookmark(for: feed)
                        }
                    }) {
                        VStack {
                            Image(systemName: "bookmark")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.orange)
                            Text("Bookmark")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Customize View Button
                    Button(action: {
                        showCustomize = true
                    }) {
                        VStack {
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.purple)
                            Text("Customize")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    .sheet(isPresented: $showCustomize) {
                        CustomizeView(isGridView: $isGridView)
                    }
                }
                .padding()
            }
            .environment(\.colorScheme, viewModel.isDarkModeEnabled ? .dark : .light) // Apply dark mode dynamically
            .navigationBarTitle("Aggregator", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(item: $selectedFeed) { feed in
                FeedDetailView(viewModel: viewModel, feed: feed) // Pass the viewModel here
            }
        }
    }
}
