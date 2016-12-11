//
//  FBBezierContour.swift
//  Swift VectorBoolean for iOS
//
//  Based on FBBezierContour - Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-05-19.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import UIKit

enum FBContourInside {
  case filled
  case hole
}
//let myFBContourInsideExample = FBContourInside.Filled

/// FBBezierContour represents a closed path of bezier curves (aka edges).
///
/// Contours can be filled or represent a hole in another contour.
class FBBezierContour {

  enum FBContourDirection
  {
    case clockwise
    case antiClockwise
  }
  //let myFBContourDirectionExample = FBContourDirection.AntiClockwise

  fileprivate var _edges : [FBBezierCurve]
  fileprivate var _overlaps : [FBContourOverlap]
  fileprivate var _bounds : CGRect
  fileprivate var _boundingRect : CGRect
  fileprivate var _inside : FBContourInside
  fileprivate var	_bezPathCache : UIBezierPath?


  //@property FBContourInside inside;
  var inside : FBContourInside {
    get {
      return _inside
    }
    set {
      _inside = newValue
    }
  }

  // LRT - 2015.07.24 08:59:48 PM
  // want access from XCTest functions
  internal var overlaps : [FBContourOverlap] {
    return _overlaps
  }

  var edges : [FBBezierCurve] {
    return _edges
  }

  init() {
    self._edges = []
    self._overlaps = []
    self._bounds = CGRect.null
    self._boundingRect = CGRect.null
    self._inside = .filled
  }

  class func bezierContourWithCurve(_ curve: FBBezierCurve) -> FBBezierContour {
    let result = FBBezierContour()
    result.addCurve(curve)
    return result
  }

  // Methods for building up the contour.
  // The reverse forms flip points in the bezier curve
  // before adding them to the contour.
  //
  // The crossing to crossing methods assume the
  // crossings are on the same edge.
  // One of the crossings can be nil, but not both.




  // 72
  //- (void) addCurve:(FBBezierCurve *)curve
  func addCurve(_ curve: FBBezierCurve?) {
    // Add the curve by wrapping it in an edge
    if let curve = curve {
      curve.contour = self;
      curve.index = _edges.count
      _edges.append(curve)
      _bounds = CGRect.null   // force the bounds to be recalculated
      _boundingRect = CGRect.null
      _bezPathCache = nil
    }
  }


  // 86
  //- (void) addCurveFrom:(FBEdgeCrossing *)startCrossing to:(FBEdgeCrossing *)endCrossing
  func addCurveFrom(_ startCrossing: FBEdgeCrossing?, to endCrossing: FBEdgeCrossing?) {
    // First construct the curve that we're going to add,
    // by seeing which crossing is nil.
    // If the crossing isn't given go to the end of the edge on that side.
    var curve : FBBezierCurve?

    if startCrossing == nil, let endCrossing = endCrossing {
      // From start to endCrossing
      curve = endCrossing.leftCurve
    } else if endCrossing == nil, let startCrossing = startCrossing {
      // From startCrossing to end
      curve = startCrossing.rightCurve
    } else if let startCrossing = startCrossing, let endCrossing = endCrossing {
      // From startCrossing to endCrossing
      curve = startCrossing.curve?.subcurveWithRange(FBRange(minimum: startCrossing.parameter, maximum: endCrossing.parameter))
    }

    if let curve = curve {
      addCurve(curve)
    }
  }


  // 104
  //- (void) addReverseCurve:(FBBezierCurve *)curve
  func addReverseCurve(_ curve: FBBezierCurve?) {
    // Just reverse the points on the curve.
    // Need to do this to ensure the end point from one edge
    // matches the start on the next edge.
    if let curve = curve {
      addCurve(curve.reversedCurve())
    }
  }


  // 114
  //- (void) addReverseCurveFrom:(FBEdgeCrossing *)startCrossing to:(FBEdgeCrossing *)endCrossing
  func addReverseCurveFrom(_ startCrossing: FBEdgeCrossing?, to endCrossing: FBEdgeCrossing?) {
    // First construct the curve that we're going to add,
    // by seeing which crossing is nil.
    // If the crossing isn't given go to the end of the edge on that side.
    var curve : FBBezierCurve?

    if startCrossing == nil, let endCrossing = endCrossing {
      // From start to endCrossing
      curve = endCrossing.leftCurve
    } else if endCrossing == nil, let startCrossing = startCrossing {
      // From startCrossing to end
      curve = startCrossing.rightCurve
    } else if let startCrossing = startCrossing, let endCrossing = endCrossing {
      // From startCrossing to endCrossing
      curve = startCrossing.curve?.subcurveWithRange(FBRange(minimum: startCrossing.parameter, maximum: endCrossing.parameter))
    }

    if let curve = curve {
      addReverseCurve(curve)
    }
  }


  // 132
  //- (NSRect) bounds
  var bounds : CGRect {
    // Cache the bounds to save time
    if !_bounds.equalTo(CGRect.null) {
      return _bounds
    }

    // If no edges, no bounds
    if _edges.count == 0 {
      return CGRect.zero
    }

    var totalBounds = CGRect.zero
    for edge in _edges {
      let edgeBounds : CGRect = edge.bounds
      if totalBounds.equalTo(CGRect.zero) {
        totalBounds = edgeBounds
      } else {
        // This was:
        //   totalBounds = FBUnionRect(totalBounds, bounds)
        totalBounds = totalBounds.union(edgeBounds)
      }
    }

    _bounds = totalBounds

    return _bounds
  }


  // 156
  //- (NSRect) boundingRect
  var boundingRect : CGRect {
    // Cache the boundingRect to save time
    if !_boundingRect.equalTo(CGRect.null) {
      return _boundingRect
    }

    // If no edges, no bounds
    if _edges.count == 0 {
      return CGRect.zero
    }

    var totalBounds = CGRect.zero
    for edge in _edges {
      let edgeBounds : CGRect = edge.boundingRect
      if totalBounds.equalTo(CGRect.zero) {
        totalBounds = edgeBounds
      } else {
        // This was:
        //   totalBounds = FBUnionRect(totalBounds, bounds)
        totalBounds = totalBounds.union(edgeBounds)
      }
    }

    _boundingRect = totalBounds

    return _boundingRect
  }


  // 180
  //- (NSPoint) firstPoint
  var firstPoint : CGPoint {
    if _edges.count == 0 {
      return CGPoint.zero
    }

    return _edges[0].endPoint1
  }

  // 189
  //- (BOOL) containsPoint:(NSPoint)testPoint
  func containsPoint(_ testPoint: CGPoint) -> Bool {

    if !boundingRect.contains(testPoint) || !bounds.contains(testPoint) {
      return false
    }

    // Create a test line from our point to somewhere outside our graph.
    // We'll see how many times the test line intersects edges of the graph.
    // Based on the even/odd rule, if it's an odd number, we're inside
    // the graph, if even, outside.

    let externalXPt = testPoint.x > bounds.minX ? bounds.minX - 10 : bounds.maxX + 10
    let lineEndPoint = CGPoint(x: externalXPt, y: testPoint.y)
    /* just move us outside the bounds of the graph */
    let testCurve = FBBezierCurve.bezierCurveWithLineStartPoint(testPoint, endPoint: lineEndPoint)

    let intersectCount = numberOfIntersectionsWithRay(testCurve)

    return intersectCount.isOdd
    //return intersectCount & 1 == 1  // fast version of: intersectCount % 2 != 0
  }

  // 204
  //- (NSUInteger) numberOfIntersectionsWithRay:(FBBezierCurve *)testEdge
  func numberOfIntersectionsWithRay(_ testEdge: FBBezierCurve) -> Int {
    var count = 0
    intersectionsWithRay(testEdge, withBlock: {
      (intersection: FBBezierIntersection)-> Void in
      count += 1
    })

    return count
  }

  // 213
  //- (void) intersectionsWithRay:(FBBezierCurve *)testEdge withBlock:(void (^)(FBBezierIntersection *intersection))block
  func intersectionsWithRay(_ testEdge: FBBezierCurve, withBlock block:@escaping (_ intersection: FBBezierIntersection) -> Void) {

    var firstIntersection : FBBezierIntersection?
    var previousIntersection : FBBezierIntersection?

    // Count how many times we intersect with this particular contour
    for edge in _edges {
      // Check for intersections between our test ray and the rest of the bezier graph
      var intersectRange : FBBezierIntersectRange?

      testEdge.intersectionsWithBezierCurve(edge, overlapRange: &intersectRange) {
        (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in
        // Make sure this is a proper crossing
        if !testEdge.crossesEdge(edge, atIntersection:intersection) || edge.isPoint {
          // don't count tangents
          return (false, false)
        }

        // Make sure we don't count the same intersection twice.
        // This happens when the ray crosses at the start or end of an edge.
        if intersection.isAtStartOfCurve2, let previousIntersection = previousIntersection {
          let previousEdge = edge.previous
          if ( previousIntersection.isAtEndPointOfCurve2 && previousEdge === previousIntersection.curve2 ) {
            return (false, false)
          }
        } else if intersection.isAtEndPointOfCurve2, let firstIntersection = firstIntersection {
          let nextEdge = edge.next
          if firstIntersection.isAtStartOfCurve2 && nextEdge === firstIntersection.curve2 {
            return (false, false)
          }
        }

        block(intersection)
        if firstIntersection == nil {
          firstIntersection = intersection
        }
        previousIntersection = intersection
        return (false, false)
      }

      if let intersectRange = intersectRange {
        if testEdge.crossesEdge(edge, atIntersectRange:intersectRange) {
          block(intersectRange.middleIntersection)
        }
      }
    }
  }


  // 251
  //- (FBBezierCurve *) startEdge
  fileprivate var startEdge : FBBezierCurve? {
    // When marking we need to start at a point that is
    // clearly either inside or outside the other graph,
    // otherwise we could mark the crossings exactly opposite
    // of what they're supposed to be.
    if edges.count == 0 {
      return nil
    }

    var startEdge = edges[0]
    let stopValue = startEdge

    while startEdge.isStartShared {
      startEdge = startEdge.next
      if startEdge === stopValue {
        break; // for safety. But if we're here, we could be hosed
      }
    }
    return startEdge
  }


  // 269
  //- (NSPoint) testPointForContainment
  var testPointForContainment : CGPoint {
    // Start with the startEdge, and if it's not shared (overlapping)
    // then use its first point
    if var testEdge = self.startEdge {

    if !testEdge.isStartShared {
      return testEdge.endPoint1
    }

    // At this point we know that all the end points defining this contour are shared.
    // We'll need to somewhat arbitrarily pick a point on an edge that's not overlapping
    let stopValue = testEdge
    let  parameter = 0.5
    while doesOverlapContainParameter(parameter, onEdge:testEdge) {
      testEdge = testEdge.next;
      if ( testEdge == stopValue ) {
        break; // for safety. But if we're here, we could be hosed
      }
    }
    return testEdge.pointAtParameter(parameter).point
    } else {
      return CGPoint.zero
    }
  }


  // 289
  //- (void) startingEdge:(FBBezierCurve **)outEdge parameter:(CGFloat *)outParameter point:(NSPoint *)outPoint
  func startingEdge() -> (edge: FBBezierCurve, parameter: Double, point: CGPoint) {
    // Start with the startEdge, and if it's not shared (overlapping)
    // then use its first point
    var testEdge = startEdge!

    if !testEdge.isStartShared {
      return (edge: testEdge, parameter: 0.0, point: testEdge.endPoint1)
    }

    // At this point we know that all the end points defining this contour are shared.
    // We'll need to somewhat arbitrarily pick a point on an edge that's not overlapping
    let stopValue = testEdge
    let parameter = 0.5
    while doesOverlapContainParameter(parameter, onEdge:testEdge) {
      testEdge = testEdge.next
      if testEdge === stopValue {
        break   // for safety. But if we're here, we could be hosed
      }
    }

    let outPoint = testEdge.pointAtParameter(parameter).point

    return (edge: testEdge, parameter: 0.0, point: outPoint)
  }


  // 315
  //- (void) markCrossingsAsEntryOrExitWithContour:(FBBezierContour *)otherContour markInside:(BOOL)markInside
  func markCrossingsAsEntryOrExitWithContour(_ otherContour: FBBezierContour, markInside: Bool) {
    // Go through and mark all the crossings with the given
    // contour as "entry" or "exit".
    // This determines what part of ths contour is output.

    // When marking we need to start at a point that is clearly
    // either inside or outside the other graph, otherwise we
    // could mark the crossings exactly opposite of what they're supposed to be.
    let (startEdge, startParameter, startPoint) = startingEdge()

    // Calculate the first entry value.
    // We need to determine if the edge we're starting
    // on is inside or outside the otherContour.
    let contains = otherContour.contourAndSelfIntersectingContoursContainPoint(startPoint)
    var isEntry = markInside ? !contains : contains
    var otherContours = otherContour.selfIntersectingContours
    otherContours.append(otherContour)

    let FBStopParameterNoLimit = 2.0 // needs to be > 1.0
    let FBStartParameterNoLimit = 0.0

    // Walk all the edges in this contour and mark the crossings
    isEntry = markCrossingsOnEdge(startEdge, startParameter:startParameter, stopParameter:FBStopParameterNoLimit, otherContours:otherContours, startIsEntry:isEntry)

    var edge = startEdge.next
    while edge !== startEdge {
      isEntry = markCrossingsOnEdge(edge, startParameter:FBStartParameterNoLimit, stopParameter:FBStopParameterNoLimit, otherContours:otherContours, startIsEntry:isEntry)
      edge = edge.next
    }

    markCrossingsOnEdge(startEdge, startParameter:FBStartParameterNoLimit, stopParameter:startParameter, otherContours:otherContours, startIsEntry:isEntry)
  }


  // 347
  //- (BOOL) markCrossingsOnEdge:(FBBezierCurve *)edge startParameter:(CGFloat)startParameter stopParameter:(CGFloat)stopParameter otherContours:(NSArray *)otherContours isEntry:(BOOL)startIsEntry
  @discardableResult
  func markCrossingsOnEdge(_ edge: FBBezierCurve, startParameter: Double, stopParameter: Double, otherContours: [FBBezierContour] , startIsEntry: Bool) -> Bool {

    var isEntry = startIsEntry

    // Mark all the crossings on this edge
    edge.crossingsWithBlock() {
      (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in

      // skip over other contours

      // Note:
      // The expression:
      //   arrayOfObjs.filter({ el in el === obj }).count == 0
      // evaluates to a Bool indicating that arrayOfObjs does NOT contain obj
      // is equivalent to
      //   ![arrayOfObjs containsObject:obj]
      let other = crossing.counterpart?.edge?.contour
      let notContained = otherContours.filter({ el in el === other }).count == 0
      if crossing.isSelfCrossing || notContained {
        return (false, false) // skip
      }

      if crossing.parameter < startParameter || crossing.parameter >= stopParameter {
        return (false, false) // skip
      }

      crossing.entry = isEntry
      isEntry = !isEntry  // toggle to indicate exit or entry
      return (false, false)
    }

    return isEntry
  }


  // 363
  //- (BOOL) contourAndSelfIntersectingContoursContainPoint:(NSPoint)point
  fileprivate func contourAndSelfIntersectingContoursContainPoint(_ point: CGPoint) -> Bool {
    var containerCount = 0
    if containsPoint(point) {
      containerCount += 1
    }
    for contour in selfIntersectingContours {
      if contour.containsPoint(point) {
        containerCount += 1
      }
    }

    return containerCount.isOdd
    //return containerCount & 1 != 0  // fast version of: containerCount % 2 != 0
  }


  // 376
  //- (NSBezierPath*) bezierPath		// GPC: added
  var bezierPath : UIBezierPath {
    if _bezPathCache == nil {
      let path = UIBezierPath()
      var firstPoint = true

      for edge in self.edges {
        if firstPoint {
          path.move(to: edge.endPoint1)
          firstPoint = false
        }

        if edge.isStraightLine {
          path.addLine(to: edge.endPoint2)
        } else {
          path.addCurve(to: edge.endPoint2, controlPoint1: edge.controlPoint1, controlPoint2: edge.controlPoint2)
        }
      }

      if !path.isEmpty {
        path.close()
      }
      path.usesEvenOddFillRule = true

      _bezPathCache = path
    }

    return _bezPathCache!
  }


  // 403
  //- (void) close
  func close() {
    // adds an element to connect first and last points on the contour
    if _edges.count == 0 {
      return
    }

    let first = _edges[0]
    if let last = _edges.last {
      if !FBArePointsClose(first.endPoint1, point2: last.endPoint2) {
        addCurve(FBBezierCurve(startPoint: last.endPoint2, endPoint: first.endPoint1))
      }
    }
  }


  // 417
  //- (FBBezierContour*) reversedContour	// GPC: added
  var reversedContour : FBBezierContour {
    let revContour = FBBezierContour()

    for edge in _edges {
      revContour.addReverseCurve(edge)
    }

    return revContour
  }


  // 428
  //- (FBContourDirection) direction
  var direction : FBContourDirection {

    var lastPoint = CGPoint.zero, currentPoint = CGPoint.zero
    var firstPoint = true
  	var a = CGFloat(0.0)

    for edge in _edges {
      if firstPoint {
        lastPoint = edge.endPoint1
        firstPoint = false
      } else {
        currentPoint = edge.endPoint2
        a += ((lastPoint.x * currentPoint.y) - (currentPoint.x * lastPoint.y))
        lastPoint = currentPoint
      }
    }

    return ( a >= 0 ) ? FBContourDirection.clockwise : FBContourDirection.antiClockwise
  }


  // 449
  //- (FBBezierContour *) contourMadeClockwiseIfNecessary
  var contourMadeClockwiseIfNecessary : FBBezierContour {
    let dir = self.direction

    if dir == FBContourDirection.clockwise {
      return self
    }

    return self.reversedContour
  }


  // 459
  //- (BOOL) crossesOwnContour:(FBBezierContour *)contour
  func crossesOwnContour(_ contour: FBBezierContour) -> Bool {
    for edge in _edges {
      var intersects = false

      edge.crossingsWithBlock() {
        (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in

        // Only want the self intersecting crossings
        if crossing.isSelfCrossing, let ccpart = crossing.counterpart, let intersectingEdge = ccpart.edge {
          if intersectingEdge.contour === contour {
            intersects = true
            return (true, true)
          }
        }
        return (false, false)
      }

      if intersects {
        return true
      }
    }
    return false
  }


  // 478
  //@property (readonly) NSArray *intersectingContours;
  //- (NSArray *) intersectingContours
  var intersectingContours : [FBBezierContour] {
    // Go and find all the unique contours that intersect this specific contour
    var iContours : [FBBezierContour] = []
    for edge in _edges {

      edge.intersectingEdgesWithBlock() {
        (intersectingEdge: FBBezierCurve) -> Void in
        if let ieContour = intersectingEdge.contour {
          if iContours.filter({ el in el === ieContour }).count == 0 {
            iContours.append(ieContour)
          }
        }
      }

    }
    return iContours
  }

  // 491
  //- (NSArray *) selfIntersectingContours
  var selfIntersectingContours : [FBBezierContour] {
    // Go and find all the unique contours that intersect
    // this specific contour from our own graph
    var siContours : [FBBezierContour] = []
    addSelfIntersectingContoursToArray(&siContours, originalContour: self)
    return siContours
  }

  // 499
  //- (void) addSelfIntersectingContoursToArray:(NSMutableArray *)contours originalContour:(FBBezierContour *)originalContour
  fileprivate func addSelfIntersectingContoursToArray(_ contours: inout [FBBezierContour], originalContour: FBBezierContour) {
    for edge in _edges {

      edge.selfIntersectingEdgesWithBlock() {
        (intersectingEdge: FBBezierCurve) -> Void in
        if let ieContour = intersectingEdge.contour {
          if ieContour !== originalContour && contours.filter({ el in el === ieContour }).count == 0 {
            contours.append(ieContour)
            ieContour.addSelfIntersectingContoursToArray(&contours, originalContour: originalContour)
          }
        }
      }

    }
  }


  // 511
  //- (void) addOverlap:(FBContourOverlap *)overlap
  func addOverlap(_ overlap: FBContourOverlap) {
    if _overlaps.count == 0 {
      return
    }

    _overlaps.append(overlap)
  }


  // 519
  //- (void) removeAllOverlaps
  func removeAllOverlaps() {
    if _overlaps.count == 0 {
      return
    }

    _overlaps.removeAll()
  }


  // 527
  //- (BOOL) isEquivalent:(FBBezierContour *)other
  func isEquivalent(_ other: FBBezierContour) -> Bool {
    if _overlaps.count == 0 {
      return false
    }

    for overlap in _overlaps {
      if overlap.isBetweenContour(self, andContour: other) && overlap.isComplete {
        return true
      }
    }
    return false
  }

  // 539
  //- (void) forEachEdgeOverlapDo:(void (^)(FBEdgeOverlap *overlap))block
  fileprivate func forEachEdgeOverlapDo(_ block:(_ overlap: FBEdgeOverlap) -> Void) {
    if _overlaps.count == 0 {
      return
    }

    for overlap in _overlaps {
      overlap.runsWithBlock() {
        (run: FBEdgeOverlapRun) -> Bool in
        for edgeOverlap in run.overlaps {
          block(edgeOverlap)
        }
        return false
      }
    }
  }

  // 552
  //- (BOOL) doesOverlapContainCrossing:(FBEdgeCrossing *)crossing
  func doesOverlapContainCrossing(_ crossing: FBEdgeCrossing) -> Bool {
    if _overlaps.count == 0 {
      return false
    }

    for overlap in _overlaps {
      if overlap.doesContainCrossing(crossing) {
        return true
      }
    }
    return false
  }

  // 564
  //- (BOOL) doesOverlapContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge
  func doesOverlapContainParameter(_ parameter: Double, onEdge edge: FBBezierCurve) -> Bool {
    if _overlaps.count > 0 {
      for overlap in _overlaps {
        if overlap.doesContainParameter(parameter, onEdge:edge) {
          return true
        }
      }
    }
    return false
  }

  // 584
  //- (FBCurveLocation *) closestLocationToPoint:(NSPoint)point
  func closestLocationToPoint(_ point: CGPoint) -> FBCurveLocation? {
    var closestEdge : FBBezierCurve? = nil
    var location = FBBezierCurveLocation(parameter: 0.0, distance: 0.0)

    for edge in _edges {
      let edgeLocation = edge.closestLocationToPoint(point)
      if closestEdge == nil || edgeLocation.distance < location.distance {
        closestEdge = edge
        location = edgeLocation
      }
    }

    if let closestEdge = closestEdge {
      let curveLocation = FBCurveLocation(edge: closestEdge, parameter: location.parameter, distance: location.distance)
      curveLocation.contour = self
      return curveLocation
    } else {
      return nil
    }
  }

  // 617
  //- (NSBezierPath *) debugPathForIntersectionType:(NSInteger)itersectionType
  /// Returns a path consisting of small circles placed at
  /// the intersections that match <ti>
  ///
  /// This allows the internal state of a contour to be
  /// rapidly visualized so that bugs with boolean ops
  /// are easier to spot at a glance.
  func debugPathForIntersectionType(_ itersectionType: Int) -> UIBezierPath {

    let path : UIBezierPath = UIBezierPath()

    for edge in _edges {

      edge.crossingsWithBlock() {
        (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in

        if itersectionType == 1 {     // looking for entries
          if !crossing.isEntry {
            return (false, false)
          }
        } else if itersectionType == 2 {   // looking for exits
          if crossing.isEntry {
            return (false, false)
          }
        }
        if crossing.isEntry {
          path.append(UIBezierPath.circleAtPoint(crossing.location))
        } else {
          path.append(UIBezierPath.rectAtPoint(crossing.location))
        }

        return (false, false)
      }
    }

    // Add the start point and direction for marking
    if let startEdge = self.startEdge {
      let startEdgeTangent = FBNormalizePoint(FBSubtractPoint(startEdge.controlPoint1, point2: startEdge.endPoint1));
      path.append(UIBezierPath.triangleAtPoint(startEdge.endPoint1, direction: startEdgeTangent))
    }

    // Add the contour's entire path to make it easy
    // to see which one owns which crossings
    // (these can be colour-coded when drawing the paths)
    path.append(self.bezierPath)

    // If this countour is flagged as "inside",
    // the debug path is shown dashed, otherwise solid
    if self.inside == .hole {
      let dashes : [CGFloat] = [CGFloat(2), CGFloat(3)]
      path.setLineDash(dashes, count: 2, phase: 0)
    }

    return path;
  }

}
