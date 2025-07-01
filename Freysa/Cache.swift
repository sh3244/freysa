//
//  Cache.swift
//  Freysa
//
//  Created by Sam on 6/30/25.
//

import Foundation
import UIKit

// MARK: - Disk Cache

final actor DiskCache {
    static let shared = DiskCache()
    let fileManager = FileManager.default
    let cacheDirectory: URL

    init() {
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
    func safeFileName(from url: URL) -> String {
        let hashed = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        return hashed
    }
}