//
//  ShoppingManiacUITestsLaunchTests.swift
//  ShoppingManiacUITests
//
//  Created by Dmitry Matyushkin on 5/21/26.
//

import XCTest

final class ShoppingManiacUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestInMemoryStore"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Shopping lists"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
