//
//  LibraryTab.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import SwiftUI


struct LibraryTab: View {
    @State var assets: [VideoAsset] = []
    @State var loading = false
    @State var errorMessage: String?

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
    LibraryTab()
}
