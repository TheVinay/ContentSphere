import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                // Skip button (top right)
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundStyle(.blue)
                    .padding()
                }
                
                // Swipeable pages
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "lightbulb.fill",
                        iconColor: .blue,
                        title: "Understand the news faster",
                        subtitle: "Get instant context on why stories matter with intelligent insights powered by on-device analysis"
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "Explore stories your way",
                        subtitle: "Browse by category, discover personalized topics, or explore news on an interactive global map"
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "slider.horizontal.3",
                        iconColor: .orange,
                        title: "News, on your terms",
                        subtitle: "Choose your sources, customize categories, and read in your preferred layout"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom button
                Button {
                    if currentPage < 2 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage == 2 ? "Start Reading" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            didCompleteOnboarding = true
        }
    }
}

// MARK: - Onboarding Page
struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(iconColor)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
