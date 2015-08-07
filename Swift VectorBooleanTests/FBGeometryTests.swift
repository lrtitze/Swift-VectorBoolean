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

  func testPolar() {
    // cribbed from FBTangentsCross
    let e1TansLeft = CGPoint(x: -5, y: 0)
    let test1 = PolarAngle(e1TansLeft)
    let e1TansRight = CGPoint(x: 0, y: 12)
    let test2 = PolarAngle(e1TansRight)
    //[0]	CGFloat	3.1415926535897931
    //[1]	CGFloat	1.5707963267948966

    let e2TansLeft = CGPoint(x: 0, y: 8)
    let test3 = PolarAngle(e2TansLeft)
    let e2TansRight = CGPoint(x: 1.9999999999999982, y: 0)
    let test4 = PolarAngle(e2TansRight)
    //[0]	CGFloat	1.5707963267948966
    //[1]	CGFloat	0
  }

  /// Check Join of two rects (XOR)
  func testCommonSegment() {
    let usCurve = FBBezierCurve(startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 10, y: 0))
    let otherCurve = FBBezierCurve(startPoint: CGPoint(x: 5, y: 0), endPoint: CGPoint(x: 12, y: 0))
    let usCurveData = FBBezierCurveData(
      endPoint1: CGPoint(x: 0, y: 0),
      controlPoint1: CGPoint(x: 1, y: 0),
      controlPoint2: CGPoint(x: 9, y: 0),
      endPoint2: CGPoint(x: 10, y: 0),
      isStraightLine: true)
    let otherCurveData = FBBezierCurveData(
      endPoint1: CGPoint(x: 5, y: 0),
      controlPoint1: CGPoint(x: 6, y: 0),
      controlPoint2: CGPoint(x: 11, y: 0),
      endPoint2: CGPoint(x: 12, y: 0),
      isStraightLine: true)

    var usRange = FBRangeMake(0, 1)
    var themRange = FBRangeMake(0, 1)
    var stop = false
    var overlapRange : FBBezierIntersectRange?

    pfIntersectionsWithBezierCurve(usCurve.data, otherCurve.data, &usRange, &themRange, usCurve, otherCurve, &overlapRange, 0, &stop) {
      (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
      // Make sure this is a proper crossing
      println("Intersection: \(intersection.location)")
      return (false, false)
    }

    let overlap = FBContourOverlap()

    if let ir = overlapRange {
      let c1lb_ep1 = ir.curve1LeftBezier.data.endPoint1
      let c1lb_ep2 = ir.curve1LeftBezier.data.endPoint2
      let c2rb_ep1 = ir.curve2RightBezier.data.endPoint1
      let c2rb_ep2 = ir.curve2RightBezier.data.endPoint2
      var checkPoint = CGPoint(x: 0, y: 0)
      XCTAssert(FBArePointsClose(checkPoint, c1lb_ep1), "Startpoint 1 is unexpected")
      checkPoint = CGPoint(x: 5, y: 0)
      XCTAssert(FBArePointsClose(checkPoint, c1lb_ep2), "Endpoint 1 is unexpected")
      checkPoint = CGPoint(x: 10, y: 0)
      XCTAssert(FBArePointsClose(checkPoint, c2rb_ep1), "Startpoint 2 is unexpected")
      checkPoint = CGPoint(x: 12, y: 0)
      XCTAssert(FBArePointsClose(checkPoint, c2rb_ep2), "Endpoint 2 is unexpected")

      overlap.addOverlap(ir, forEdge1: usCurve, edge2: otherCurve)

      // now want to look at the  actual run generated for this
      var ovRun: FBEdgeOverlapRun?
      overlap.runsWithBlock({ (run: FBEdgeOverlapRun) -> Bool in
        ovRun = run
        return true // only want the single one
      })
      if let run = ovRun {
        let ra = run.overlaps[0]
        let contour1 = run.contour1
        let contour2 = run.contour2
        let a = contour1?.edges
      } else {
        XCTAssert(false, "There was no run created though there was an overlap")
      }

      println("")
    } else {
      XCTAssert(false, "There was no overlap range created when it must overlap")
    }

    if stop {
      return
    }

    let lowRect = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 10, height: 13))
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
    // TODO: Track down what's making these disappear

    /*
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

    thisGraph.markCrossingsAsEntryOrExitWithBezierGraph(otherGraph, markInside: true)
    otherGraph.markCrossingsAsEntryOrExitWithBezierGraph(thisGraph, markInside: true)
*/
    //_location CGPoint?    (x = 350, y = 115)  Some
    println("")
/*
    thisGraph.insertSelfCrossings];
    [graph insertSelfCrossings];
    thisGraph.cleanupCrossingsWithBezierGraph:graph];

    let thisGraph = FBBezierGraph( bezierGraphWithBezierPath:self];
    FBBezierGraph *otherGraph = [FBBezierGraph bezierGraphWithBezierPath:path];
*/
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
