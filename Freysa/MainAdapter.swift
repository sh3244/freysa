//
//  MainAdapter.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import Foundation

// MARK: - Adapter

class MainAdapter {

    class func getCreationTemplates() async throws -> [Template] {
        let query = """
        query {
          creationTemplates {
            id
            title
            thumbnailUrl
            videoUrl
          }
        }
        """
        let raw = try await API.shared.get(query: query)
        let json = try JSONSerialization.jsonObject(with: raw) as? [String: Any]
        guard
            let data = json?["data"] as? [String: Any],
            let items = data["creationTemplates"] as? [[String: Any]]
        else { return [] }

        return items.compactMap { Template(json: $0) }
    }

    class func getPublicVideoAssets() async throws -> [VideoAsset] {
        let query = """
        query {
          publicVideoAssets {
            id
            thumbnailUrl
            videoUrl
            createdAt
          }
        }
        """
        let raw = try await API.shared.get(query: query)
        let json = try JSONSerialization.jsonObject(with: raw) as? [String: Any]
        guard
            let data = json?["data"] as? [String: Any],
            let items = data["publicVideoAssets"] as? [[String: Any]]
        else { return [] }

        return items.compactMap { VideoAsset(json: $0) }
    }

    class func getLibraryAssets() async throws -> [VideoAsset] {
        let query = """
        query {
          assets {
            ... on VideoAsset {
              id
              thumbnailUrl
              videoUrl
              createdAt
              status
            }
          }
        }
        """
        let raw = try await API.shared.get(query: query)
        let json = try JSONSerialization.jsonObject(with: raw) as? [String: Any]
        guard
            let data = json?["data"] as? [String: Any],
            let items = data["assets"] as? [[String: Any]]
        else { return [] }

        return items.compactMap { VideoAsset(json: $0) }
    }

    /// Dummy implementation: return a new UUID for testing
    class func generateAsset(templateId: String, prompt: String) async throws -> String {
        return UUID().uuidString
    }

    /// Dummy implementation: always return true for testing
    class func rateAsset(assetId: String, decision: RateAssetDecision) async throws -> Bool {
        return true
    }
}
