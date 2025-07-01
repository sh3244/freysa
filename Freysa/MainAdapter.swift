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

    /// Kick off generation with a template + prompt, returns the new asset’s ID
    class func generateAsset(templateId: String, prompt: String) async throws -> String {
      let mutation = """
      mutation {
        generateAsset(input: {
        templateId: "\(templateId)",
        inputs: [
          {key: "prompt", value: "\(prompt)", type: TEXT, title: "Prompt"}
        ]
        })
      }
      """
      let raw = try await API.shared.get(query: mutation)
      guard
        let json      = try JSONSerialization.jsonObject(with: raw) as? [String: Any],
        let data      = json["data"]      as? [String: Any],
        let assetId   = data["generateAsset"] as? String
      else {
        throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid generateAsset response"])
      }

      return assetId
    }

    /// Get details of generating asset in progress
    class func getAssetById(assetId: String) async throws -> VideoAsset? {
      let query = """
      query {
        assets(ids: ["\(assetId)"]) {
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
        let items = data["assets"] as? [[String: Any]],
        let first = items.first
      else { return nil }

      return VideoAsset(json: first)
    }

    /// Send a thumbs-up/thumbs-down for an existing asset
    class func rateAsset(assetId: String, decision: String) async throws -> Bool {
      let mutation = """
      mutation {
        rateAsset(assetId: "\(assetId)", decision: \(decision))
      }
      """
      let raw = try await API.shared.get(query: mutation)
      guard
        let json        = try JSONSerialization.jsonObject(with: raw) as? [String: Any],
        let data        = json["data"]        as? [String: Any],
        let success     = data["rateAsset"]   as? Bool
      else {
        throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid rateAsset response"])
      }

      return success
    }
}
