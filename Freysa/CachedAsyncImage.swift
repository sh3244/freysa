//
//  CachedAsyncImage.swift
//  Freysa
//
//  Created by Sam on 7/1/25.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage = image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .onAppear { load() }
            }
        }
    }

    private func load() {
        guard !isLoading, let url else { return }
        isLoading = true

        Task {
            // Try disk cache first
            if let data = await DiskCache.shared.get(url: url),
               let img = UIImage(data: data) {
                await MainActor.run { image = img }
                //                print("cache hit")
                return
            }

            // Download if not cached
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = UIImage(data: data) {
                    await DiskCache.shared.set(url: url, data: data)
                    await MainActor.run { image = img }
                }
            } catch {
                // Ignore error, show placeholder
            }
        }
    }
}
