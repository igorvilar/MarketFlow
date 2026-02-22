//
//  MarketFlowUITests.swift
//  MarketFlowUITests
//
//  Created by Igor Vilar on 22/02/26.
//

import XCTest

final class MarketFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainFlowNavigation() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // 1. Verify "Top Exchanges" List Loaded
        let listTable = app.tables["ExchangeListTable"]
        
        // Wait for the Table to exist and become interactable (networking simulation wait)
        let tableExists = listTable.waitForExistence(timeout: 10)
        XCTAssertTrue(tableExists, "The Exchange list table should appear.")
        XCTAssertTrue(listTable.cells.count > 0, "The Exchange list must load at least one cell.")

        // 2. Tap the first Exchange Cell in the list
        let firstCell = listTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists, "The first cell must be accessible.")
        firstCell.tap()
        
        // 3. Verify Navigation to the Exchange Detail Screen
        let detailScrollView = app.scrollViews["ExchangeDetailScrollView"]
        let detailScrollExists = detailScrollView.waitForExistence(timeout: 5)
        XCTAssertTrue(detailScrollExists, "The Detail ScrollView must appear after tapping a cell.")
        
        // 4. Verify the Loading Indicator spins and then disappears (Info fetch completes)
        let detailLoader = app.activityIndicators["DetailLoadingIndicator"]
        if detailLoader.exists {
            // Wait for loader to disappear meaning data is loaded or error thrown
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: detailLoader)
            _ = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        }
        
        // 5. Scroll down to force the assets to be in view
        detailScrollView.swipeUp()
        
        // 6. Verify "Available Assets" Table exists
        let assetsTable = app.tables["ExchangeDetailAssetsTable"]
        let assetsTableExists = assetsTable.waitForExistence(timeout: 5)
        XCTAssertTrue(assetsTableExists, "The Assets table should appear at the bottom of the Detail screen.")
        
        // 7. Test the "Back" Button integration
        let backButton = app.navigationBars.buttons.element(boundBy: 0) // The generic iOS back button
        XCTAssertTrue(backButton.exists, "Navigation back button must exist.")
        backButton.tap()
        
        // 8. Verify we returned to the List screen
        XCTAssertTrue(listTable.exists, "After backing out, the App must be on the List Screen again.")
    }
}
