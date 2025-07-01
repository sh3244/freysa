//
//  DiscoverTab.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//
import SwiftUI
import AVKit
import AVFoundation

struct DiscoverTab: View {
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
                    GeometryReader { geo in
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    ForEach(videos.indices, id: \.self) { idx in
                                        AutoPlayVideoView(
                                            url: videos[idx].videoUrl,
                                            isActive: currentIndex == idx
                                        )
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .id(idx)
                                    }
                                }
                                .background(
                                    GeometryReader { innerGeo -> Color in
                                        let offsetY = -innerGeo.frame(in: .named("scroll")).origin.y
                                        let pageHeight = geo.size.height
                                        let calculatedIndex = Int(round(offsetY / pageHeight))

                                        DispatchQueue.main.async {
                                            if calculatedIndex != currentIndex && calculatedIndex >= 0 && calculatedIndex < videos.count {
                                                currentIndex = calculatedIndex
                                                print("📄 Page updated to \(currentIndex)")
                                            }
                                        }

                                        return Color.clear
                                    }
                                )
                            }
                            .coordinateSpace(name: "scroll")
                            .scrollTargetBehavior(.paging)
                            .onAppear {
                                proxy.scrollTo(currentIndex, anchor: .top)
                            }
                        }
                    }
                    .ignoresSafeArea()
                }
            }
//            .navigationTitle("Discover")
//            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            loading = true
            do {
                videos = try await MainAdapter.getPublicVideoAssets()
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }
}

struct AutoPlayVideoView: View {
    let url: URL?
    let isActive: Bool
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                configureAudioSession()
                if let u = url {
                    player.replaceCurrentItem(with: AVPlayerItem(url: u))
                }
                // Only autoplay if active upon appearing
                if isActive {
                    player.play()
                    print("▶️ Autoplay started for URL: \(url?.absoluteString ?? "unknown")")
                }
            }
            .onChange(of: isActive, initial: true) { _, active in
                if active {
                    player.seek(to: .zero)
                    player.play()
                    print("▶️ Video playing: \(url?.absoluteString ?? "unknown")")
                } else {
                    player.pause()
                    print("⏸ Video paused: \(url?.absoluteString ?? "unknown")")
                }
            }
            .onDisappear {
                player.pause()
                player.replaceCurrentItem(with: nil)
            }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}

// MARK: – Previews
#Preview {
    DiscoverTab()
}
