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
    @State var videos: [VideoAsset] = []
    @State var loading = false
    @State var errorMessage: String?
    @State var currentIndex = 0

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("Loading…")
                } else if let err = errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                } else if videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.7))
                        Text("No videos to discover yet.")
                            .foregroundColor(.white)
                            .font(.title3)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
                } else {
                    GeometryReader { geo in
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 0) {
                                    ForEach(videos.indices, id: \.self) { idx in
                                        ZStack {
                                            AutoPlayVideoView(
                                                url: videos[idx].videoUrl,
                                                isActive: currentIndex == idx
                                            )
                                            .frame(width: geo.size.width, height: geo.size.height)
                                            .id(idx)

                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    VStack(spacing: 16) {
                                                        Button(action: {
                                                            print("👎 Disliked video at index \(idx)")
                                                            Task {
                                                                try? await MainAdapter.rateAsset(assetId: videos[idx].id, decision: "DISLIKE")
                                                            }
                                                        }) {
                                                            Image(systemName: "hand.thumbsdown.fill")
                                                                .font(.system(size: 22))
                                                                .foregroundColor(.white)
                                                                .padding(10)
                                                                .background(Color.black.opacity(0.7))
                                                                .clipShape(Circle())
                                                        }

                                                        Button(action: {
                                                            print("👍 Liked video at index \(idx)")
                                                            Task {
                                                                try? await MainAdapter.rateAsset(assetId: videos[idx].id, decision: "LIKE")
                                                            }
                                                        }) {
                                                            Image(systemName: "hand.thumbsup.fill")
                                                                .font(.system(size: 22))
                                                                .foregroundColor(.white)
                                                                .padding(10)
                                                                .background(Color.black.opacity(0.7))
                                                                .clipShape(Circle())
                                                        }
                                                    }
                                                    .padding(.trailing, 24)
                                                    .padding(.bottom, 120) // Move buttons further down
                                                }
                                            }
                                            .frame(width: geo.size.width, height: geo.size.height)
                                        }
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

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isLoading = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VideoPlayer(player: player)
                .onAppear {
                    configureAudioSession()
                    guard let url = url else { return }
                    loadVideo(url: url)
                }
                .onChange(of: isActive, initial: false) { _, active in
                    guard let queue = player else { return }
                    if active {
                        queue.play()
                    } else {
                        queue.pause()
                    }
                }
                .onDisappear {
                    player?.pause()
                    looper = nil
                    player = nil
                }
        }
    }

    private func loadVideo(url: URL) {
        guard !isLoading else { return }
        isLoading = true

        Task {
            // Try disk cache first
            if let data = await DiskCache.shared.get(url: url) {
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try? data.write(to: tempUrl)
                await MainActor.run {
                    setupPlayer(with: tempUrl)
                }
                // print("Cache hit for \(url)")
                return
            }

            // Download if not cached
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try? data.write(to: tempUrl)
                await DiskCache.shared.set(url: url, data: data)
                await MainActor.run {
                    setupPlayer(with: tempUrl)
                }
            } catch {
                // Ignore error
            }
        }
    }

    private func setupPlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        let loop = AVPlayerLooper(player: queue, templateItem: item)
        self.player = queue
        self.looper = loop
        if isActive {
            queue.play()
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
