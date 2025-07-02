//
//  DiscoverTab.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//
import SwiftUI
import AVKit
import AVFoundation

@MainActor
final class DiscoverListViewModel: ObservableObject {
    @Published var videos: [VideoAsset] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        Task { await loadVideos() }
    }

    func loadVideos() async {
//        isLoading = true
//        defer { isLoading = false }

        do {
            videos = try await MainAdapter.getPublicVideoAssets()
            print("Loaded \(videos.count) videos")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Continue refactoring: Move state and loading logic into the view model

struct DiscoverTab: View {
    @StateObject private var viewModel = DiscoverListViewModel()
    @State private var currentIndex = 0

    var body: some View {
        NavigationView {
            Group {
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading…")
        }
        else if let err = viewModel.errorMessage {
            errorView(message: err)
        }
        else if viewModel.videos.isEmpty {
            emptyView
        }
        else {
            videosPager
        }
    }

    private func errorView(message: String) -> some View {
        Text(message)
            .foregroundColor(.red)
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
    }

    private var emptyView: some View {
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
    }

    private var videosPager: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.videos.indices, id: \.self) { idx in
                            videoCell(idx: idx, geo: geo)
                        }
                    }
                    .background(
                        scrollOffsetListener(geo: geo)
                    )
                }
                .coordinateSpace(name: "scroll")
                .scrollTargetBehavior(.paging)
                .refreshable {
                    await viewModel.loadVideos()
                }
                .tint(.gray)    // ← make the refresh control white

                .onAppear {
                    proxy.scrollTo(currentIndex, anchor: .top)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func videoCell(idx: Int, geo: GeometryProxy) -> some View {
        ZStack {
            AutoPlayVideoView(
                url: viewModel.videos[idx].videoUrl,
                isActive: currentIndex == idx
            )
            .frame(width: geo.size.width, height: geo.size.height)
            .id(idx)

            videoActions(idx: idx, geo: geo)
        }
    }

    private func videoActions(idx: Int, geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Button(action: {
                        print("👎 Disliked video at index \(idx)")
                        Task {
                            try? await MainAdapter.rateAsset(assetId: viewModel.videos[idx].id, decision: "DISLIKE")
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
                            try? await MainAdapter.rateAsset(assetId: viewModel.videos[idx].id, decision: "LIKE")
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
                .padding(.bottom, 120)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }

    private func scrollOffsetListener(geo: GeometryProxy) -> some View {
        GeometryReader { innerGeo -> Color in
            let offsetY = -innerGeo.frame(in: .named("scroll")).origin.y
            let page = Int(round(offsetY / geo.size.height))
            DispatchQueue.main.async {
                guard
                    page != currentIndex,
                    page >= 0,
                    page < viewModel.videos.count
                else { return }
                currentIndex = page
            }
            return .clear
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
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .task(id: isActive) {
                if isActive {
                    configureAudioSession()
                    if player == nil, let videoURL = url {
                        await loadAndSetupPlayer(from: videoURL)
                    }
                    player?.play()
                } else {
                    player?.pause()
                }
            }
            .onDisappear {
                // full cleanup if the view goes away
                player?.pause()
                looper = nil
                player = nil
            }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func loadAndSetupPlayer(from url: URL) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // 1) Attempt cache
        let data: Data
        if let cached = await DiskCache.shared.get(url: url) {
            data = cached
        } else {
            // 2) Download (with proper do/try/catch)
            do {
                let (downloaded, _) = try await URLSession.shared.data(from: url)
                data = downloaded
                await DiskCache.shared.set(url: url, data: downloaded)
            } catch {
                // failed download—give up
                return
            }
        }

        // 3) Write to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")
        try? data.write(to: tempURL)

        // 4) Build player on the main actor
        await MainActor.run {
            let item = AVPlayerItem(url: tempURL)
            let queue = AVQueuePlayer()
            looper = AVPlayerLooper(player: queue, templateItem: item)
            player = queue
        }
    }
}

// MARK: – Previews
#Preview {
    DiscoverTab()
}
