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
    }
}

// MARK: – Templates Screen

// view for template
private struct TemplateCell: View {
    let template: Template

    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: template.thumbnailUrl) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()

            Text(template.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .center)

        }.background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        .frame(width: UIScreen.main.bounds.width / 2 - 16*3, height: 200)
    }
}

private struct TemplatesTab: View {
    @State private var templates: [Template] = []
    @State private var loading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("Loading…")
                } else if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 8) {
                            ForEach(templates) { tpl in
                                TemplateCell(template: tpl)
                                    .onTapGesture {
                                        // Navigate to creation view with selected template
                                        // For now, just print the template ID
                                        print("Selected template ID: \(tpl.id)")
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Templates")
        }
        .task { await loadTemplates() }
    }

    func loadTemplates() async {
        loading = true; errorMessage = nil
        do {
            templates = try await MainAdapter.getCreationTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}
import SwiftUI
import AVFoundation
import AVKit

// MARK: - DiscoverTab

private struct DiscoverTab: View {
    @State private var videos: [VideoAsset] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var currentIndex = 0

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("Loading…")
                } else if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                } else {
                    GeometryReader { geometry in
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    ForEach(Array(videos.enumerated()), id: \.1.id) { index, v in
                                        AutoPlayVideoView(url: v.videoUrl, isActive: currentIndex == index)
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .id(index)
                                    }
                                }
                            }
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        let threshold = geometry.size.height / 2
                                        if value.translation.height < -threshold {
                                            // Swipe up
                                            currentIndex = min(currentIndex + 1, videos.count - 1)
                                        } else if value.translation.height > threshold {
                                            // Swipe down
                                            currentIndex = max(currentIndex - 1, 0)
                                        }
                                        withAnimation {
                                            proxy.scrollTo(currentIndex, anchor: .top)
                                        }
                                    }
                            )
                            .onAppear {
                                proxy.scrollTo(currentIndex, anchor: .top)
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await loadVideos() }
    }

    func loadVideos() async {
        loading = true
        errorMessage = nil
        do {
            videos = try await MainAdapter.getPublicVideoAssets()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}

// MARK: - AutoPlayVideoView

private struct AutoPlayVideoView: UIViewControllerRepresentable {
    let url: URL?
    let isActive: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player == nil, let url = url {
            controller.player = AVPlayer(url: url)
        }

        if isActive {
            controller.player?.play()
        } else {
            controller.player?.pause()
        }
    }
}



// MARK: – Library Screen

private struct LibraryTab: View {
    @State private var assets: [VideoAsset] = []
    @State private var loading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("Loading…")
                } else if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                } else {
                    List(assets) { asset in
                        HStack {
                            AsyncImage(url: asset.thumbnailUrl) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 80, height: 80)
                            .clipped()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(asset.id).font(.headline)
                                Text(asset.createdAt, style: .date).font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Library")
        }
        .task { await loadLibrary() }
    }

    func loadLibrary() async {
        loading = true; errorMessage = nil
        do {
            assets = try await MainAdapter.getLibraryAssets()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}

// MARK: – Previews

#Preview {
    ContentView()
}
