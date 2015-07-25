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
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }


  /// Check Join of two rects (XOR)
  func testCommonSegment() {
    let lowRect = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 10, height: 12))
    let topRect = UIBezierPath(rect: CGRect(x: 5, y: 0, width: 7, height: 8))
    // will have a common segment from 5,0 to 10,0
    // will have a crossing at 10,8

    var thisGraph = FBBezierGraph(path: lowRect)
    var otherGraph = FBBezierGraph(path: topRect)
    thisGraph.insertCrossingsWithBezierGraph(otherGraph)

    XCTAssert(thisGraph.contours.count == 1, "Found \(thisGraph.contours.count) contours - should only have 1 contour")
    XCTAssert(thisGraph.contours[0].edges.count == 4, "Found \(thisGraph.contours[0].edges.count) edges - should have 4 edges")

    let aSetOfOverlaps = thisGraph.contours[0].edges[0].contour?.overlaps
    let numOverlaps = aSetOfOverlaps?.count

    XCTAssert(numOverlaps == 1, "The first edge should have one overlap")
  }


  /// Check Difference of two rects
  func testTwoRectDifference() {
    let lowRect = UIBezierPath(rect: CGRect(x: 50, y: 50, width: 300, height: 200))

    let topRect = UIBezierPath(rect: CGRect(x: 230, y: 115, width: 250, height: 250))

    var thisGraph = FBBezierGraph(path: lowRect)
    var otherGraph = FBBezierGraph(path: topRect)
    //var result = thisGraph.differenceWithBezierGraph(otherGraph).bezierPath
    thisGraph.insertCrossingsWithBezierGraph(otherGraph)
    XCTAssert(thisGraph.contours.count == 1, "Found \(thisGraph.contours.count) contours - should only have 1 contour")
    XCTAssert(thisGraph.contours[0].edges.count == 4, "Found \(thisGraph.contours[0].edges.count) edges - should have 4 edges")
    XCTAssert(thisGraph.contours[0].edges[0].crossings.count == 0, "The first edge should not have any crossings")
    XCTAssert(thisGraph.contours[0].edges[1].crossings.count == 1, "The second edge should have a single crossing")

    let crossing = thisGraph.contours[0].edges[1].crossings[0]
    XCTAssert(crossing.location.x == 350 && crossing.location.y == 115, "The second edge crossing is at the wrong location \(crossing.location)")
    let edge = crossing.edge
    let starts = crossing.isAtStart
    let ends = crossing.isAtEnd
    let g1C1 = thisGraph.contours[0].edges[1].crossings[0]
    let g1C2 = thisGraph.contours[0].edges[2].crossings[0]
    let g2C1 = otherGraph.contours[0].edges[0].crossings[0]
    let g2C2 = otherGraph.contours[0].edges[3].crossings[0]
    let counterpartAMatch = g2C1.counterpart === g1C1
    let counterpartBMatch = g2C2.counterpart === g1C2
    thisGraph.insertSelfCrossings() // none for rects
    otherGraph.insertSelfCrossings() // none for rects
    thisGraph.cleanupCrossingsWithBezierGraph(otherGraph)

    thisGraph.markCrossingsAsEntryOrExitWithBezierGraph(otherGraph, markInside: false)
    otherGraph.markCrossingsAsEntryOrExitWithBezierGraph(thisGraph, markInside: true)

    //_location	CGPoint?	(x = 350, y = 115)	Some
    println("")
/*
    thisGraph.insertSelfCrossings];
    [graph insertSelfCrossings];
    thisGraph.cleanupCrossingsWithBezierGraph:graph];

    let thisGraph = FBBezierGraph( bezierGraphWithBezierPath:self];
    FBBezierGraph *otherGraph = [FBBezierGraph bezierGraphWithBezierPath:path];
*/
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
