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
    @State var showPrompt = false
    @State var promptText = ""

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView("Loading…")
                } else if let err = errorMessage {
                    Text(err).foregroundColor(.red)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 12) {
                            ForEach(templates) { tpl in
                                TemplateCell(template: tpl) {
                                    selectedTemplate = tpl
                                    promptText = ""
                                    showPrompt = true
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
        .sheet(isPresented: $showPrompt) {
            if let tpl = selectedTemplate {
                TemplatePromptView(
                    template: tpl,
                    promptText: $promptText,
                    isPresented: $showPrompt)
            }
        }
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
struct TemplateCell: View {
    let template: Template
    let action: () -> Void

    let cellWidth: CGFloat = (UIScreen.main.bounds.width - 48) / 2
    let cellHeight: CGFloat = (UIScreen.main.bounds.width - 48) / 2 * 1.614

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: template.thumbnailUrl) { img in
                img
                    .resizable()
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .clipped()
            } placeholder: {
                Color.gray.opacity(0.3)
                    .frame(width: cellWidth, height: cellHeight)
            }

            // Gradient overlay for text fade
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.7), location: 0.0),
                    .init(color: Color.black.opacity(0.0), location: 0.8)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 40)
            .frame(width: cellWidth)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .alignmentGuide(.bottom) { d in d[.bottom] }

            // Title text near bottom
            HStack {
                Spacer()
                Text(template.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                Spacer()
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(0)
        .onTapGesture(perform: action)
    }
}

struct TemplatePromptView: View {
    let template: Template
    @Binding var promptText: String
    @Binding var isPresented: Bool
    @State var isProcessing = false
    @State var asset: VideoAsset?

    var body: some View {
        Form {
            Section(header: Text("Template")) {
                Text(template.title)
            }
            Section(header: Text("Prompt")) {
                TextField("Enter prompt", text: $promptText)
            }
        }
        .navigationTitle("Generate Video")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Generate") {
                    Task { await generate() }
                }
                .disabled(isProcessing)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPresented = false }
            }
        }
        .overlay(alignment: .center) {
            if isProcessing {
                ProgressView()
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(8)
            }
        }
    }

    func generate() async {
        isProcessing = true
        do {
            let id = try await MainAdapter.generateAsset(templateId: template.id, prompt: promptText)
            while true {
                let assets = try await MainAdapter.getLibraryAssets()
                if let found = assets.first(where: { $0.id == id }) {
                    asset = found; break
                }
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            }
        } catch {}
        isProcessing = false
    }
}



// MARK: – Previews

#Preview {
    TemplatesTab()
}
