//
//  ContentView.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import SwiftUI
import AVKit

struct ContentView: View {
    var body: some View {
        TabView {
            TemplatesTab()
                .tabItem { Label("Templates", systemImage: "square.grid.2x2") }

            DiscoverTab()
                .tabItem { Label("Discover", systemImage: "play.rectangle") }

            LibraryTab()
                .tabItem { Label("Library", systemImage: "books.vertical") }
        }
        .accentColor(.blue)
        .preferredColorScheme(.light) // This makes the status bar text black
    }
}

// MARK: – Previews

#Preview {
    ContentView()
}
