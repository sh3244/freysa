//
//  API.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import Foundation

let base_url = "https://freysa-video-backend-dev.up.railway.app"

actor API {
    static let shared = API()

    // Example of future state: auth token (safe within actor)
    var authToken: String? = "testing"

    // MARK: - Generic HTTP Request Method

    func request(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> Data {
        guard let url = URL(string: "\(base_url)\(endpoint)") else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // Example: add Authorization header if token exists
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Invalid response", code: 0, userInfo: nil)
        }

        return data
    }

    // MARK: - GraphQL GET (actually POST) query

    func get(query: String, variables: [String: Any]? = nil) async throws -> Data {
        return try await request(
            endpoint: "/query",
            method: "POST",
            body: [
                "query": query,
                "variables": variables ?? [:]
            ]
        )
    }

    // MARK: - POST

    func post(endpoint: String, body: [String: Any]? = nil) async throws -> Data {
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }

    // MARK: - PUT

    func put(endpoint: String, body: [String: Any]? = nil) async throws -> Data {
        return try await request(endpoint: endpoint, method: "PUT", body: body)
    }

    // MARK: - PATCH

    func patch(endpoint: String, body: [String: Any]? = nil) async throws -> Data {
        return try await request(endpoint: endpoint, method: "PATCH", body: body)
    }

    // MARK: - DELETE

    func delete(endpoint: String, body: [String: Any]? = nil) async throws -> Data {
        return try await request(endpoint: endpoint, method: "DELETE", body: body)
    }

    // MARK: - Example future function to set token

    func setAuthToken(_ token: String) {
        self.authToken = token
    }
}
