//
//  Models.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import Foundation

// MARK: - Models

struct Template: Identifiable {
    let id: String
    let title: String
    let thumbnailUrl: URL?
    let videoUrl: URL?

    init?(json: [String: Any]) {
        guard
            let id = json["id"] as? String,
            let title = json["title"] as? String
        else { return nil }
        self.id = id
        self.title = title
        if let thumb = (json["thumbnailUrl"] as? String)?.trimmingCharacters(in: .whitespaces) {
            thumbnailUrl = URL(string: thumb)
        } else {
            thumbnailUrl = nil
        }
        if let vid = json["videoUrl"] as? String {
            videoUrl = URL(string: vid)
        } else {
            videoUrl = nil
        }
    }
}

struct VideoAsset: Identifiable {
    let id: String
    let thumbnailUrl: URL?
    let videoUrl: URL?
    let createdAt: Date
    var status: String? // e.g. "processing", "ready", etc.

    init?(json: [String: Any]) {
        guard
            let id = json["id"] as? String,
            let createdAtStr = json["createdAt"] as? String
        else { return nil }
        self.id = id
        // parse ISO8601 with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAtStr) else { return nil }
        self.createdAt = date

        if let thumb = json["thumbnailUrl"] as? String {
            thumbnailUrl = URL(string: thumb)
        } else {
            thumbnailUrl = nil
        }
        if let vid = json["videoUrl"] as? String {
            videoUrl = URL(string: vid)
        } else {
            videoUrl = nil
        }

        self.status = json["status"] as? String
    }
}

enum RateAssetDecision: String {
    case LIKE, DISLIKE
}
