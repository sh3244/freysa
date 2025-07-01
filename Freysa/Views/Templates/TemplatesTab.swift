//
//  TemplatesTab.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import SwiftUI

// MARK: – Templates Screen

struct TemplatesTab: View {
    @State var templates: [Template] = []
    @State var loading = false
    @State var errorMessage: String?
    @State var selectedTemplate: Template?

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("Loading…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                } else if let err = errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No templates available")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 12) {
                            ForEach(templates) { tpl in
                                TemplateCell(template: tpl) {
                                    selectedTemplate = tpl
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Templates")
        }
        .accentColor(.gray)
        .task { await loadTemplates() }
        .sheet(item: $selectedTemplate) { tpl in
            TemplatePromptView(template: tpl)
                .accentColor(.gray)
        }
    }

    func loadTemplates() async {
        loading = true
        errorMessage = nil
        do {
            templates = try await MainAdapter.getCreationTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}

// MARK: – Grid Cell with Ken Burns Effect

struct TemplateCell: View {
    let template: Template
    let action: () -> Void

    let cellWidth: CGFloat = (UIScreen.main.bounds.width - 48) / 2
    let cellHeight: CGFloat = (UIScreen.main.bounds.width - 48) / 2 * 1.614

    @State var animatedScale: CGFloat = 1.0
    @State var animatedOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: template.thumbnailUrl) { img in
                img
                    .resizable()
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .clipped()
                // apply Ken Burns effect
                    .scaleEffect(animatedScale)
                    .offset(animatedOffset)
                    .onAppear {
                        // random target values
                        let maxZoom: CGFloat = 0.3
                        let targetScale = 1 + .random(in: 0...maxZoom)
                        // After scaling, the image is larger: compute overshoot
                        let overshootWidth = cellWidth * targetScale - cellWidth
                        let overshootHeight = cellHeight * targetScale - cellHeight
                        // Half overshoot is max safe offset
                        let maxXOffset = overshootWidth / 2
                        let maxYOffset = overshootHeight / 2
                        // Random offset within safe range
                        let targetOffset = CGSize(
                            width: .random(in: -maxXOffset...maxXOffset),
                            height: .random(in: -maxYOffset...maxYOffset)
                        )
                        let duration = Double.random(in: 5...10)
                        withAnimation(
                            Animation.easeInOut(duration: duration)
                                .repeatForever(autoreverses: true)
                        ) {
                            animatedScale = targetScale
                            animatedOffset = targetOffset
                        }
                    }
            } placeholder: {
                Color.gray.opacity(0.3)
                    .frame(width: cellWidth, height: cellHeight)
            }

            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .white.opacity(0.7), location: 0),
                    .init(color: .white.opacity(0),   location: 0.8)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: cellWidth, height: 40)

            Text(template.title)
                .font(.title3.bold())
                .foregroundColor(.white)
                .shadow(radius: 4)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .frame(width: cellWidth, height: cellHeight)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: action)
    }
}

// MARK: – Prompt & Generation

struct TemplatePromptView: View {
    let template: Template
    @Environment(\.dismiss) var dismiss

    @State var promptText: String = ""
    @State var isProcessing = false
    @State var isPublic: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Template preview
                ZStack(alignment: .bottom) {
                    CachedAsyncImage(url: template.thumbnailUrl) { img in
                        img
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                            .frame(height: 200)
                    }

                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.7), location: 0),
                            .init(color: .black.opacity(0),   location: 0.8)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 60)

                    Text(template.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
                .cornerRadius(12)

                // Custom prompt field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("Enter prompt", text: $promptText)
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }

                Toggle(isOn: $isPublic) {
                    Text("Public")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))

                Spacer()

                // Credits 100 flat credits cost
                Text("Cost in Credits: 100, Balance: \(999)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(action: { Task { await generate() } }) {
                    Text(isProcessing ? "Generating…" : "Generate Video")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isProcessing || promptText.isEmpty)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .navigationTitle("Generate Video")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.accentColor)
                }
            }
        }
        .accentColor(.accentColor)
    }

    func generate() async {
        isProcessing = true
        do {
            let assetId = try await MainAdapter.generateAsset(
                templateId: template.id,
                prompt: promptText
            )
            while true {
                if let asset = try await MainAdapter.getAssetById(assetId: assetId),
                   asset.status == "ready" {
                    break
                }
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            }
            dismiss()
        } catch {
            print("Generation error:", error.localizedDescription)
            dismiss()
        }
        isProcessing = false
    }
}

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

// MARK: – Preview

#Preview {
    TemplatesTab()
}
