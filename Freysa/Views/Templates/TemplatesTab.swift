//
//  TemplatesTab.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import SwiftUI

@MainActor
final class TemplatesListViewModel: ObservableObject {
    @Published var templates: [Template] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        Task { await loadTemplates() }
    }

    func loadTemplates() async {
//        isLoading = true
//        defer { isLoading = false }

        do {
            templates = try await MainAdapter.getCreationTemplates()
            // shuffle templates
            templates.shuffle()
            print("Loaded \(templates.count) templates")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


// MARK: – Templates Screen

struct TemplatesTab: View {
    @StateObject private var vm = TemplatesListViewModel()
    @State private var selected: Template?


    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView("Loading…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                } else if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if vm.templates.isEmpty {
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
                            ForEach(vm.templates) { tpl in
                                TemplateCell(template: tpl) {
                                    selected = tpl
                                }
                            }
                        }
                        .padding()
                    }.refreshable {
                        await vm.loadTemplates()
                    }
                }
            }
            .navigationTitle("Templates")
        }
        .accentColor(.gray)
        .sheet(item: $selected) { tpl in
            TemplatePromptView(template: tpl)
                .accentColor(.gray)
        }
    }
}

struct AnimatedImageView: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    private let targetScale: CGFloat
    private let targetOffset: CGSize
    private let duration: Double

    init(url: URL?, width: CGFloat, height: CGFloat) {
        self.url = url
        self.width = width
        self.height = height

        // one-time random Ken-Burns parameters
        let maxZoom: CGFloat = 0.3
        let s = 1 + .random(in: 0...maxZoom)
        
        let overshootW = width * s - width
        let overshootH = height * s - height
        let maxX = overshootW / 2
        let maxY = overshootH / 2

        self.targetScale = s
        self.targetOffset = CGSize(
            width: .random(in: -maxX...maxX),
            height: .random(in: -maxY...maxY)
        )
        self.duration = Double.random(in: 5...10)
    }

    var body: some View {
        CachedAsyncImage(url: url) { img in
            img
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .scaleEffect(scale)
                .offset(offset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                    ) {
                        scale = targetScale
                        offset = targetOffset
                    }
                }
        } placeholder: {
            Color.gray.opacity(0.3)
                .frame(width: width, height: height)
        }
    }
}


// MARK: – Grid Cell with Ken Burns Effect

struct TemplateCell: View {
    let template: Template
    let action: () -> Void

    private let cellWidth: CGFloat
    private let cellHeight: CGFloat

    init(template: Template, action: @escaping () -> Void) {
        self.template = template
        self.action = action

        let w = (UIScreen.main.bounds.width - 48) / 2
        self.cellWidth = w
        self.cellHeight = w * 1.614
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AnimatedImageView(
                url: template.thumbnailUrl,
                width: cellWidth,
                height: cellHeight
            )

            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.7), location: 0),
                    .init(color: .black.opacity(0),   location: 0.8)
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
                    AnimatedImageView(
                        url: template.thumbnailUrl,
                        width: UIScreen.main.bounds.width - 32,
                        height: 200
                    )

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

// MARK: – Preview

#Preview {
    TemplatesTab()
}
