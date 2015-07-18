//
//  FBGeometryTests.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-14.
//  Copyright (c) 2015 Startside Softworks. All rights reserved.
//

import UIKit
import XCTest

class FBGeometryTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.FBDistanceBetweenPoints
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testFBDistanceBetweenPoints() {
    var point1 = CGPoint(x: 12, y: 15)
    var point2 = CGPoint(x: 13, y: 16)
    var result = FBDistanceBetweenPoints(point1, point2)
    var check = CGFloat(1.4142135623730951)

    XCTAssert(result == check, "Distance between points is being calculated as \(result)")


    point2 = CGPoint(x: 12, y: 16.5)
    result = FBDistanceBetweenPoints(point1, point2)
    check = CGFloat(1.5)

    XCTAssert(result == check, "Distance between points is being calculated as \(result)")
}

  func testFBDistancePointToLine() {
    var point1 = CGPoint(x: 0, y: 15) // any y value is okay
    var point2 = CGPoint(x: 10, y: 0)
    var point3 = CGPoint(x: 10, y: 20)
    var result = FBDistancePointToLine(point1, point2, point3)
    let check = CGFloat(10.0)
    XCTAssert(result == check, "Distance between points is being calculated as \(result)")

  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock() {
      // Put the code you want to measure the time of here.
    }
  }

}
