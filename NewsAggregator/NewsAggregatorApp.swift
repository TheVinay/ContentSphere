//
//  NewsAggregatorApp.swift
//  NewsAggregator
//
//  Created by Vinays Mac on 3/29/25.
//

import SwiftUI

@main
struct NewsAggregatorApp: App {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if didCompleteOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}
