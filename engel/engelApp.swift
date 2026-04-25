//
//  engelApp.swift
//  engel
//
//  Created by Arssh Kumar on 4/21/26.
//

import SwiftUI
import SwiftData
import CoreText

@main
struct engelApp: App {
    @AppStorage("usesSystemAppearance") private var usesSystemAppearance = true
    @AppStorage("prefersDarkMode") private var prefersDarkMode = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .tint(ThemeTokens.colors.ink)
                } else {
                    OnboardingView {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(for: [SDEntry.self, SDInsight.self])
    }

    private var preferredColorScheme: ColorScheme? {
        if usesSystemAppearance { return nil }
        return prefersDarkMode ? .dark : .light
    }

    private static func registerBundledFonts() {
        let fontFiles = ["Fraunces.ttf", "Fraunces-Italic.ttf", "JetBrainsMono.ttf"]
        for file in fontFiles {
            guard let url = Bundle.main.url(forResource: file, withExtension: nil) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
