//
//  FreysaTests.swift
//  FreysaTests
//
//  Created by Sam on 6/30/25.
//

import XCTest
@testable import Freysa

final class FreysaTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testAPI() async throws {
        // 1. Fetch creation templates
        let templates = try await MainAdapter.getCreationTemplates()
        print("Templates payload:", templates)
        XCTAssertFalse(templates.isEmpty, "Should return at least one template")

        // 2. Fetch public video assets
        let publicVideos = try await MainAdapter.getPublicVideoAssets()
        print("PublicVideoAssets payload:", publicVideos)
        XCTAssertFalse(publicVideos.isEmpty, "Should return at least one public video asset")

        // 3. Fetch library assets
        let libraryAssets = try await MainAdapter.getLibraryAssets()
        print("LibraryAssets payload:", libraryAssets)
        XCTAssertNotNil(libraryAssets, "Library assets array should not be nil")

        // 4. Generate a new asset
        let firstTemplateID = templates.first!.id
        let newAssetID = try await MainAdapter.generateAsset(templateId: firstTemplateID, prompt: "Test prompt")
        print("generateAsset returned ID:", newAssetID)
        XCTAssertFalse(newAssetID.isEmpty, "generateAsset should return a non-empty ID")

        // 5. Rate the newly generated asset
        let rateResult = try await MainAdapter.rateAsset(assetId: newAssetID, decision: .LIKE)
        print("rateAsset result:", rateResult)
        XCTAssertTrue(rateResult, "rateAsset should return true")
    }



}
