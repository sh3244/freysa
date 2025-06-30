//
//  Cache.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import Foundation
import UIKit

// MARK: - In-memory LRU Cache

final actor Cache {
    static let shared = Cache()
    private let cache = NSCache<NSString, NSData>()

    private init() {}

    func get(url: URL) -> Data? {
        return cache.object(forKey: url.absoluteString as NSString) as Data?
    }

    func set(url: URL, data: Data) {
        cache.setObject(data as NSData, forKey: url.absoluteString as NSString)
    }
}

// MARK: - Disk Cache

final actor DiskCache {
    static let shared = DiskCache()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("DiskCache")

        // Create cache directory if not exists
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    /// Fetch from disk cache if exists
    func get(url: URL) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(safeFileName(from: url))
        return try? Data(contentsOf: fileURL)
    }

    /// Store data to disk cache
    func set(url: URL, data: Data) {
        let fileURL = cacheDirectory.appendingPathComponent(safeFileName(from: url))
        try? data.write(to: fileURL)
    }

    /// Helper: generate a safe file name from URL
    private func safeFileName(from url: URL) -> String {
        let hashed = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        return hashed
    }
}
