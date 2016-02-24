//
//  FBBezierGraph.swift
//  Swift VectorBoolean for iOS
//
//  Based on FBBezierGraph - Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-05-21.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

// =================================================================================
// The main point of this class is to perform boolean operations. The algorithm
//  used here is a modified and expanded version of the algorithm presented
//  in "Efficient clipping of arbitrary polygons" by Günther Greiner and Kai Hormann.
//  http://www.inf.usi.ch/hormann/papers/Greiner.1998.ECO.pdf
//  That algorithm assumes polygons, not curves, and only considers one contour intersecting
//  one other contour. My algorithm uses bezier curves (not polygons) and handles
//  multiple contours intersecting other contours.
//

// FBBezierGraph is more or less an exploded version of a UIBezierPath, and
//  the two can be converted between easily. FBBezierGraph allows boolean
//  operations to be performed by allowing the curves to be annotated with
//  extra information such as where intersections happen.

import UIKit

class FBBezierGraph {

  private var _bounds : CGRect
  private var _contours : [FBBezierContour]

  var contours : [FBBezierContour] {
    get {
      return _contours
    }
  }

  init() {
    _contours = []
    _bounds = CGRectNull
  }

  init(path: UIBezierPath) {
    _contours = []
    _bounds = CGRectNull
    initWithBezierPath(path)
  }

  class func bezierGraphWithBezierPath(path: UIBezierPath!) -> AnyObject {
    return FBBezierGraph().initWithBezierPath(path)
  }

  //- (id) initWithBezierPath:(NSBezierPath *)path
  func initWithBezierPath(path: UIBezierPath!) -> FBBezierGraph {
    // A bezier graph is made up of contours, which are closed paths of curves. Anytime we
    //  see a move to in the UIBezierPath, that's a new contour.

    var lastPoint : CGPoint = CGPointZero
    var wasClosed = false

    var contour : FBBezierContour?
    let bezier = LRTBezierPathWrapper(path)

    // This is done in a completely different way than was used for NSBezierPath

    for (_, elem) in bezier.elements.enumerate() {
      switch elem {

      case let .Move(toPt):
        // if previous contour wasn't closed, close it
        if !wasClosed && contour != nil {
          contour?.close()
        }
        wasClosed = false
        contour = FBBezierContour()
        addContour(contour!)
        lastPoint = toPt

      case .Line(let toPt):

        if !CGPointEqualToPoint(toPt, lastPoint) {
          // Convert lines to bezier curves as well.
          // Just set control point to be in the line formed by the end points
          if let contour = contour {
            contour.addCurve(FBBezierCurve.bezierCurveWithLineStartPoint(lastPoint, endPoint:toPt))
          }

          lastPoint = toPt
        }

      case .QuadCurve(let toPt, let via):
        print("We have a QuadCurve: to \(toPt) via \(via) - What's up with that?")

      case .CubicCurve(let toPt, let v1, let v2):

        // GPC: skip degenerate case where all points are equal
        let allPointsEqual = CGPointEqualToPoint(toPt, lastPoint)
          && CGPointEqualToPoint(toPt, v1)
          && CGPointEqualToPoint(toPt, v2)

        if !allPointsEqual {
          contour?.addCurve(FBBezierCurve(endPoint1: lastPoint, controlPoint1: v1, controlPoint2: v2, endPoint2: toPt))
          lastPoint = toPt
        }

      case .Close:

        // [MO] attempt to close the bezier contour by
        // mapping closepaths to equivalent lineto operations,
        // though as with our NSLineToBezierPathElement processing,
        // we check so as not to add degenerate line segments which
        // blow up the clipping code.

        if let contour = contour {
          let edges = contour.edges
          if edges.count > 0 {
            let firstEdge = edges[0]
            let firstPoint = firstEdge.endPoint1

            // Skip degenerate line segments
            if !CGPointEqualToPoint(lastPoint, firstPoint) {
              contour.addCurve(FBBezierCurve.bezierCurveWithLineStartPoint(lastPoint, endPoint:firstPoint))
              wasClosed = true
            }
          }
        }
        lastPoint = CGPoint.zero
      }
    }
    // to mimic the peculiar behavior of the Objective-C version
    // so that I can debug these in parallel
    //addContour(FBBezierContour())

    return self
  }

  ////////////////////////////////////////////////////////////////////////
  // MARK: Boolean operations
  //
  // The three main boolean operations (union, intersect, difference) follow
  //  much the same algorithm. First, the places where the two graphs cross
  //  (not just intersect) are marked on the graph with FBEdgeCrossing objects.
  //  Next, we decide which sections of the two graphs should appear in the final
  //  result. (There are only two kind of sections: those inside of the other graph,
  //  and those outside.) We do this by walking all the crossings we created
  //  and marking them as entering a section that should appear in the final result,
  //  or as exiting the final result. We then walk all the crossings again, and
  //  actually output the final result of the graphs that intersect.
  //
  //  The last part of each boolean operation deals with what do with contours
  //  in each graph that don't intersect any other contours.
  //
  // The exclusive or boolean op is implemented in terms of union, intersect,
  //  and difference. More specifically it subtracts the intersection of both
  //  graphs from the union of both graphs.
  //

  // 218
  //- (FBBezierGraph *) unionWithBezierGraph:(FBBezierGraph *)graph
  func unionWithBezierGraph(graph: FBBezierGraph) -> FBBezierGraph! {
    // First insert FBEdgeCrossings into both graphs where the graphs
    //  cross.
    insertCrossingsWithBezierGraph(graph)
    insertSelfCrossings()
    graph.insertSelfCrossings()
    cleanupCrossingsWithBezierGraph(graph)

    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are outside the other for the final result.
    self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: false)
    graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: false)

    // Walk the crossings and actually compute the final result for the intersecting parts
    var result = bezierGraphFromIntersections

    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    unionNonintersectingPartsIntoGraph(&result, withGraph: graph)

    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    self.removeCrossings()
    graph.removeCrossings()
    self.removeOverlaps()
    graph.removeOverlaps()

    return result
  }

  // 248
  //- (void) unionNonintersectingPartsIntoGraph:(FBBezierGraph *)result withGraph:(FBBezierGraph *)graph
  private func unionNonintersectingPartsIntoGraph(inout result: FBBezierGraph, withGraph graph: FBBezierGraph) {

    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    var ourNonintersectingContours = self.nonintersectingContours
    var theirNonintersectinContours = graph.nonintersectingContours
    var finalNonintersectingContours = ourNonintersectingContours
    // Swift is so sweet about some things!
    // [finalNonintersectingContours addObjectsFromArray:theirNonintersectinContours];
    finalNonintersectingContours += theirNonintersectinContours
    unionEquivalentNonintersectingContours(&ourNonintersectingContours, withContours: &theirNonintersectinContours, results: &finalNonintersectingContours)

    // Since we're doing a union, assume all the non-crossing contours are in, and remove
    //  by exception when they're contained by another contour.
    for ourContour in ourNonintersectingContours {
      // If the other graph contains our contour, it's redundant and we can just remove it
      let clipContainsSubject = graph.containsContour(ourContour)
      if clipContainsSubject {
        // [finalNonintersectingContours removeObject:ourContour];
        for (index, element) in finalNonintersectingContours.enumerate()
        {
          if element === ourContour
          {
            finalNonintersectingContours.removeAtIndex(index)
            break
          }
        }
      }
    }

    for theirContour in theirNonintersectinContours {
      // If we contain this contour, it's redundant and we can just remove it
      let subjectContainsClip = self.containsContour(theirContour)
      if subjectContainsClip {
        //[finalNonintersectingContours removeObject:theirContour];
        for (index, element) in finalNonintersectingContours.enumerate()
        {
          if element === theirContour
          {
            finalNonintersectingContours.removeAtIndex(index)
            break
          }
        }
      }
    }

    // Append the final nonintersecting contours
    for contour in finalNonintersectingContours {
      result.addContour(contour)
    }
  }

  // 278
  //- (void) unionEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results
  private func unionEquivalentNonintersectingContours(inout ourNonintersectingContours: [FBBezierContour], inout withContours theirNonintersectingContours: [FBBezierContour], inout results: [FBBezierContour]) {

    var ourIndex = 0
    while ourIndex < ourNonintersectingContours.count {
      let ourContour = ourNonintersectingContours[ourIndex]
      for theirIndex in 0 ..< theirNonintersectingContours.count  {
        let theirContour = theirNonintersectingContours[theirIndex]

        if !ourContour.isEquivalent(theirContour) {
          continue
        }

        if ourContour.inside == theirContour.inside  {
          // Redundant, so just remove one of them from the results
          // [results removeObject:theirContour];
          for (index, element) in results.enumerate()
          {
            if element === theirContour
            {
              results.removeAtIndex(index)
              break
            }
          }
        } else {
          // One is a hole, one is a fill, so they cancel each other out. Remove both from the results
          //[results removeObject:theirContour];
          for (index, element) in results.enumerate()
          {
            if element === theirContour
            {
              results.removeAtIndex(index)
              break
            }
          }
          for (index, element) in results.enumerate()
          {
            if element === ourContour
            {
              results.removeAtIndex(index)
              break
            }
          }
        }

        // Remove both from the inputs so they aren't processed later
        theirNonintersectingContours.removeAtIndex(theirIndex)
        ourNonintersectingContours.removeAtIndex(ourIndex)
        ourIndex -= 1
        break
      }
      ourIndex += 1
    }
  }

  // 306
  //- (FBBezierGraph *) intersectWithBezierGraph:(FBBezierGraph *)graph
  func intersectWithBezierGraph(graph: FBBezierGraph) -> FBBezierGraph {

    // First insert FBEdgeCrossings into both graphs where the graphs cross.
    insertCrossingsWithBezierGraph(graph)
    self.insertSelfCrossings()
    graph.insertSelfCrossings()
    cleanupCrossingsWithBezierGraph(graph)

    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are inside the other for the final result.
    self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: true)
    graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: true)

    // Walk the crossings and actually compute the final result for the intersecting parts
    var result = bezierGraphFromIntersections

    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    intersectNonintersectingPartsIntoGraph(&result, withGraph: graph)

    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    self.removeCrossings()
    graph.removeCrossings()
    self.removeOverlaps()
    graph.removeOverlaps()
    
    return result
  }

  // 335
  //- (void) intersectNonintersectingPartsIntoGraph:(FBBezierGraph *)result withGraph:(FBBezierGraph *)graph
  private func intersectNonintersectingPartsIntoGraph(inout result: FBBezierGraph, withGraph graph: FBBezierGraph) {
    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    var ourNonintersectingContours = self.nonintersectingContours
    var theirNonintersectinContours = graph.nonintersectingContours
    var finalNonintersectingContours = intersectEquivalentNonintersectingContours(&ourNonintersectingContours, withContours: &theirNonintersectinContours)

    // Since we're doing an intersect, assume that most of these non-crossing contours shouldn't be in
    //  the final result.
    for ourContour in ourNonintersectingContours {
      // If their graph contains ourContour, then the two graphs intersect (logical AND) at ourContour,
      //  so add it to the final result.
      let clipContainsSubject = graph.containsContour(ourContour)
      if clipContainsSubject {
        finalNonintersectingContours.append(ourContour)
      }
    }
    for theirContour in theirNonintersectinContours {
      // If we contain theirContour, then the two graphs intersect (logical AND) at theirContour,
      //  so add it to the final result.
      let subjectContainsClip = self.containsContour(theirContour)
      if subjectContainsClip {
        finalNonintersectingContours.append(theirContour)
      }
    }

    // Append the final nonintersecting contours
    for contour in finalNonintersectingContours {
      result.addContour(contour)
    }
  }

  // 365
  //- (void) intersectEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results
  private func intersectEquivalentNonintersectingContours(inout ourNonintersectingContours: [FBBezierContour], inout withContours theirNonintersectingContours: [FBBezierContour]) -> [FBBezierContour] {

    var results: [FBBezierContour] = []

    var ourIndex = 0
    while ourIndex < ourNonintersectingContours.count {
      let ourContour = ourNonintersectingContours[ourIndex]
      for theirIndex in 0 ..< theirNonintersectingContours.count {
        let theirContour = theirNonintersectingContours[theirIndex]

        if !ourContour.isEquivalent(theirContour) {
          continue
        }

        if ourContour.inside == theirContour.inside {
          // Redundant, so just add one of them to our results
          results.append(ourContour)
        } else {
          // One is a hole, one is a fill, so the hole cancels the fill. Add the hole to the results
          if theirContour.inside == .Hole {
            // theirContour is the hole, so add it
            results.append(theirContour)
          } else {
            // ourContour is the hole, so add it
            results.append(ourContour)
          }
        }

        // Remove both from the inputs so they aren't processed later
        theirNonintersectingContours.removeAtIndex(theirIndex)
        ourNonintersectingContours.removeAtIndex(ourIndex)
        ourIndex -= 1
        break
      }
      ourIndex += 1
    }
    return results
  }

  // 398
  //- (FBBezierGraph *) differenceWithBezierGraph:(FBBezierGraph *)graph
  func differenceWithBezierGraph(graph: FBBezierGraph) -> FBBezierGraph {

    // First insert FBEdgeCrossings into both graphs where the graphs cross.
    insertCrossingsWithBezierGraph(graph)
    self.insertSelfCrossings()
    graph.insertSelfCrossings()
    cleanupCrossingsWithBezierGraph(graph)

    // Handle the parts of the graphs that intersect first. We're subtracting
    //  graph from ourselves. Mark the outside parts of ourselves, and the inside
    //  parts of them for the final result.
    self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: false)
    graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: true)

    // Walk the crossings and actually compute the final result for the intersecting parts
    let result = bezierGraphFromIntersections

    // Finally, process the contours that don't cross anything else. They're either
    //  completely contained in another contour, or disjoint.
    var ourNonintersectingContours = self.nonintersectingContours
    var theirNonintersectinContours = graph.nonintersectingContours
    var finalNonintersectingContours = differenceEquivalentNonintersectingContours(&ourNonintersectingContours, withContours: &theirNonintersectinContours)

    // We're doing a subtraction, so assume none of the contours should be in the final result
    for ourContour in ourNonintersectingContours {
      // If ourContour isn't subtracted away (contained by) the other graph,
      // it should stick around, so add it to our final result.
      let clipContainsSubject = graph.containsContour(ourContour)
      if !clipContainsSubject {
        finalNonintersectingContours.append(ourContour)
      }
    }
    for theirContour in theirNonintersectinContours {
      // If our graph contains theirContour, then add theirContour as a hole.
      let subjectContainsClip = self.containsContour(theirContour)
      if subjectContainsClip {
        finalNonintersectingContours.append(theirContour)   // add it as a hole
      }
    }

    // Append the final nonintersecting contours
    for contour in finalNonintersectingContours {
      result.addContour(contour)
    }

    // Clean up crossings so the graphs can be reused
    self.removeCrossings()
    graph.removeCrossings()
    self.removeOverlaps()
    graph.removeOverlaps()
    
    return result
  }

  // 450
  //- (void) differenceEquivalentNonintersectingContours:(NSMutableArray *)ourNonintersectingContours withContours:(NSMutableArray *)theirNonintersectingContours results:(NSMutableArray *)results
  private func differenceEquivalentNonintersectingContours(inout ourNonintersectingContours: [FBBezierContour], inout withContours theirNonintersectingContours: [FBBezierContour]) -> [FBBezierContour] {

    var results: [FBBezierContour] = []

    var ourIndex = 0
    while ourIndex < ourNonintersectingContours.count {
      let ourContour = ourNonintersectingContours[ourIndex]
      for theirIndex in 0 ..< theirNonintersectingContours.count {
        let theirContour = theirNonintersectingContours[theirIndex]

        if !ourContour.isEquivalent(theirContour) {
          continue
        }

        if ourContour.inside != theirContour.inside {
          // Trying to subtract a hole from a fill or vice versa does nothing,
          // so add the original to the results
          results.append(ourContour)
        } else if ourContour.inside == .Hole && theirContour.inside == .Hole {
          // Subtracting a hole from a hole is redundant,
          // so just add one of them to the results
          results.append(ourContour)
        } else {
          // Both are fills, and subtracting a fill from a fill removes both.
          // So add neither to the results.
          //  Intentionally do nothing for this case.
        }

        // Remove both from the inputs so they aren't processed later
        theirNonintersectingContours.removeAtIndex(theirIndex)
        ourNonintersectingContours.removeAtIndex(ourIndex)
        ourIndex -= 1
        break
      }
      ourIndex += 1
    }
    return results
  }

  // 480
  //- (void) markCrossingsAsEntryOrExitWithBezierGraph:(FBBezierGraph *)otherGraph markInside:(BOOL)markInside
  internal func markCrossingsAsEntryOrExitWithBezierGraph(otherGraph: FBBezierGraph, markInside: Bool) {
    // Walk each contour in ourself and mark the crossings with each intersecting contour as entering
    //  or exiting the final contour.
    for contour in contours {
      let intersectingContours = contour.intersectingContours
      for otherContour in intersectingContours {
        // If the other contour is a hole, that's a special case where we flip marking inside/outside.
        //  For example, if we're doing a union, we'd normally mark the outside of contours. But
        //  if we're unioning with a hole, we want to cut into that hole so we mark the inside instead
        //  of outside.

        //let adjustedMarkInside : Bool = (otherContour.inside == .Hole) != markInside

        if otherContour.inside == .Hole {
          contour.markCrossingsAsEntryOrExitWithContour(otherContour, markInside: !markInside)
        } else {
          contour.markCrossingsAsEntryOrExitWithContour(otherContour, markInside: markInside)
        }
      }
    }
  }


  // 499
  //- (FBBezierGraph *) xorWithBezierGraph:(FBBezierGraph *)graph
  func xorWithBezierGraph(graph: FBBezierGraph) -> FBBezierGraph {
    // XOR is done by combing union (OR), intersect (AND) and difference.
    //
    // Specifically we compute the union of the two graphs and the intersect of them,
    // and then subtract the intersect from the union.
    //
    // Note that we reuse the resulting graphs, which is why it is important
    // that operations clean up any crossings when they're done, otherwise
    // they could interfere with subsequent operations.

    // First insert FBEdgeCrossings into both graphs where the graphs cross.
    insertCrossingsWithBezierGraph(graph)
    insertSelfCrossings()
    graph.insertSelfCrossings()
    cleanupCrossingsWithBezierGraph(graph)

    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are outside the other for the final result.
    self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside: false)
    graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: false)

    // Walk the crossings and actually compute the final result for the intersecting parts
    var allParts = bezierGraphFromIntersections
    unionNonintersectingPartsIntoGraph(&allParts, withGraph:graph)

    self.markAllCrossingsAsUnprocessed()
    graph.markAllCrossingsAsUnprocessed()

    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are inside the other for the final result.
    self.markCrossingsAsEntryOrExitWithBezierGraph(graph, markInside:true)
    graph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside:true)

    var intersectingParts = bezierGraphFromIntersections
    intersectNonintersectingPartsIntoGraph(&intersectingParts, withGraph: graph)

    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    self.removeCrossings()
    graph.removeCrossings()
    self.removeOverlaps()
    graph.removeOverlaps()
    
    return allParts.differenceWithBezierGraph(intersectingParts)
  }


  // 544
  //- (NSBezierPath *) bezierPath
  var bezierPath : UIBezierPath {
    // Convert this graph into a bezier path. This is straightforward, each contour
    //  starting with a move to and each subsequent edge being translated by doing
    //  a curve to.
    // Be sure to mark the winding rule as even-odd, or interior contours (holes)
    //  won't get filled/left alone properly.
    let path = UIBezierPath()
    path.usesEvenOddFillRule = true

    for contour in _contours {
      var firstPoint = true
      for edge in contour.edges {
        if firstPoint {
          path.moveToPoint(edge.endPoint1)
          firstPoint = false
        }

        if edge.isStraightLine {
          path.addLineToPoint(edge.endPoint2)
        } else {
          path.addCurveToPoint(edge.endPoint2, controlPoint1: edge.controlPoint1, controlPoint2: edge.controlPoint2)
        }
      }
      path.closePath()  // GPC: close each contour
    }

    return path
  }

  // 575
  //- (void) insertCrossingsWithBezierGraph:(FBBezierGraph *)other
  internal func insertCrossingsWithBezierGraph(other: FBBezierGraph) {

    // Find all intersections and, if they cross the other graph,
    // create crossings for them, and insert them into each graph's edges.

    for ourContour in contours {
      for theirContour in other.contours {

        let overlap = FBContourOverlap()

        for ourEdge in ourContour.edges {
          for theirEdge in theirContour.edges {

            // Find all intersections between these two edges (curves)
            var intersectRange : FBBezierIntersectRange?
            ourEdge.intersectionsWithBezierCurve(theirEdge, overlapRange: &intersectRange) {
              (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

              // If this intersection happens at one of the ends of
              // the edges, then mark that on the edge.
              // We do this here because not all intersections create
              // crossings, but we still need to know when the
              // intersections fall on end points later on in the algorithm.

              if intersection.isAtStartOfCurve1 {
                ourEdge.startShared = true
              }
              if intersection.isAtStopOfCurve1 {
                ourEdge.next.startShared = true
              }
              if intersection.isAtStartOfCurve2 {
                theirEdge.startShared = true
              }
              if intersection.isAtStopOfCurve2 {
                theirEdge.next.startShared = true
              }

              // Don't add a crossing unless one edge actually crosses the other
              if !ourEdge.crossesEdge(theirEdge, atIntersection: intersection) {
                return (false, false)
              }

              // Add crossings to both graphs for this intersection, and point them at each other
              let ourCrossing = FBEdgeCrossing(intersection: intersection)
              let theirCrossing = FBEdgeCrossing(intersection: intersection)
              ourCrossing.counterpart = theirCrossing
              theirCrossing.counterpart = ourCrossing
              ourEdge.addCrossing(ourCrossing)
              theirEdge.addCrossing(theirCrossing)
              return (false, false)
            }
            // =====================

            if let intersectRange = intersectRange {
              overlap.addOverlap(intersectRange, forEdge1: ourEdge, edge2: theirEdge)
            }
          } // end theirEdges
        } //end ourEdges

        // At this point we've found all intersections/overlaps between ourContour and theirContour

        // Determine if the overlaps constitute crossings
        if !overlap.isComplete {
          // The contours aren't equivalent so see if they're crossings
          overlap.runsWithBlock() {
            (run: FBEdgeOverlapRun) -> Bool in
            if run.isCrossing {
              // The two ends of the overlap run should serve as crossings
              run.addCrossings()
            }
            return false
          }
        }
        
        ourContour.addOverlap(overlap)
        theirContour.addOverlap(overlap)
      } // end theirContours
    } // end ourContours
  }


  // 639
  //- (void) cleanupCrossingsWithBezierGraph:(FBBezierGraph *)other
  func cleanupCrossingsWithBezierGraph(other: FBBezierGraph) {
    // Remove duplicate crossings that can happen at end points of edges
    removeDuplicateCrossings()
    other.removeDuplicateCrossings()
    // Remove crossings that happen in the middle of
    // overlaps that aren't crossings themselves
    removeCrossingsInOverlaps()
    other.removeCrossingsInOverlaps()
  }

  // 649
  //- (void) removeCrossingsInOverlaps
  func removeCrossingsInOverlaps() {
    for ourContour in contours {
      for ourEdge in ourContour.edges {

        ourEdge.crossingsCopyWithBlock() {
          (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
          if crossing.fromCrossingOverlap {
            return (false, false)
          }

          if ourContour.doesOverlapContainCrossing(crossing) {
            let counterpart = crossing.counterpart
            crossing.removeFromEdge()
            if let counterpart = counterpart {
              counterpart.removeFromEdge()
            }
          }
          return (false, false)
        }

      }
    }
  }

  // 667
  //- (void) removeDuplicateCrossings
  private func removeDuplicateCrossings() {
    // Find any duplicate crossings. These will happen at the endpoints of edges.
    for ourContour in contours {
      for ourEdge in ourContour.edges {

        ourEdge.crossingsCopyWithBlock() {
          (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in

          if let crossingEdge = crossing.edge, lastCrossing = crossingEdge.previous.lastCrossing {
            if crossing.isAtStart && lastCrossing.isAtEnd {
              // Found a duplicate. Remove this crossing and its counterpart
              let counterpart = crossing.counterpart
              crossing.removeFromEdge()
              if let counterpart = counterpart {
                counterpart.removeFromEdge()
              }
            }
          }

          if let crossingEdge = crossing.edge, firstCrossing = crossingEdge.next.firstCrossing {
            if crossing.isAtEnd && firstCrossing.isAtStart {
              // Found a duplicate. Remove this crossing and its counterpart
              let counterpart = firstCrossing.counterpart
              firstCrossing.removeFromEdge()
              if let counterpart = counterpart {
                counterpart.removeFromEdge()
              }
            }
          }
          return (false, false)
        }
      }
    }
  }

  // 690
  //- (void) insertSelfCrossings
  internal func insertSelfCrossings() {
    // Find all intersections and, if they cross other contours in this graph,
    // create crossings for them, and insert them into each contour's edges.
    var remainingContours = self.contours

    while remainingContours.count > 0 {
      if let firstContour = remainingContours.last {
        for secondContour in remainingContours {
          // We don't handle self-intersections on the contour this way, so skip them here
          if firstContour === secondContour {
            continue
          }

          if !FBLineBoundsMightOverlap(firstContour.boundingRect, bounds2: secondContour.boundingRect) || !FBLineBoundsMightOverlap(firstContour.bounds, bounds2: secondContour.bounds) {
            continue
          }

          // Compare all the edges between these two contours looking for crossings
          for firstEdge in firstContour.edges {
            for secondEdge in secondContour.edges {
              // Find all intersections between these two edges (curves)
              var unused: FBBezierIntersectRange?
              firstEdge.intersectionsWithBezierCurve(secondEdge, overlapRange: &unused) {
                (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

                // If this intersection happens at one of the ends of the edges,
                // then mark that on the edge.
                // We do this here because not all intersections create crossings,
                // but we still need to know when the intersections fall on end points
                // later on in the algorithm.

                if intersection.isAtStartOfCurve1 {
                  firstEdge.startShared = true
                } else if intersection.isAtStopOfCurve1 {
                  firstEdge.next.startShared = true
                }

                if intersection.isAtStartOfCurve2 {
                  secondEdge.startShared = true
                } else if intersection.isAtStopOfCurve2 {
                  secondEdge.next.startShared = true
                }

                // Don't add a crossing unless one edge actually crosses the other
                if !firstEdge.crossesEdge(secondEdge, atIntersection: intersection) {
                  return (false, false)
                }

                // Add crossings to both graphs for this intersection, and point them at each other
                let firstCrossing = FBEdgeCrossing(intersection: intersection)
                let secondCrossing = FBEdgeCrossing(intersection: intersection)

                firstCrossing.selfCrossing = true
                secondCrossing.selfCrossing = true
                firstCrossing.counterpart = secondCrossing
                secondCrossing.counterpart = firstCrossing
                firstEdge.addCrossing(firstCrossing)
                secondEdge.addCrossing(secondCrossing)

                // LRT - 2015.07.27 12:29:32 PM
                // WTF?
                //return (setStop:true, stopValue:true) // Only need the one
                return (false, false)
              }
            }
          }
        }
      }

      // We just compared this contour to all the others, so we don't need to do it again
      remainingContours.removeLast()  // do this at the end of the loop when we're done with it
    }

    // Go through and mark each contour if its a hole or filled region
    for contour in _contours {
      if contour.edges.count == 0 {
        continue
      }
      contour.inside = contourInsides(contour)
    }
  }

  // 750
  //- (NSRect) bounds
  var bounds : CGRect {

    // Compute the bounds of the graph by unioning together
    // the bounds of the individual contours
    if !CGRectEqualToRect(_bounds, CGRectNull) {
      return _bounds
    }

    if _contours.count == 0 {
      return CGRectZero
    }

    for contour in _contours {
      _bounds = CGRectUnion(_bounds, contour.bounds)
    }

    return _bounds
  }


  // 765
  //- (FBContourInside) contourInsides:(FBBezierContour *)testContour
  private func contourInsides(testContour: FBBezierContour) -> FBContourInside {

    // Determine if this contour, which should reside in this graph, is a filled region or
    //  a hole. Determine this by casting a ray from one edge of the contour to the outside of
    //  the entire graph. Count how many times the ray intersects a contour in the graph. If it's
    //  an odd number, the test contour resides inside of filled region, meaning it must be a hole.
    //  Otherwise it's "outside" of the graph and creates a filled region.
    // Create the line from the first point in the contour to outside the graph

    // NOTE: this method requires insertSelfCrossings() to be called before it
    // and the self crossings to be in place to work

    if testContour.edges.count == 0 {
      
    }

    let testPoint = testContour.testPointForContainment

    // Move us just outside the bounds of the graph
    let beyondX = testPoint.x > CGRectGetMinX(self.bounds) ? CGRectGetMinX(self.bounds) - 10 : CGRectGetMaxX(self.bounds) + 10
    let lineEndPoint = CGPoint(x: beyondX, y: testPoint.y)
    let testCurve = FBBezierCurve(startPoint: testPoint, endPoint: lineEndPoint)

    var intersectCount = 0
    for contour in contours {

      // LRT - Added test for empty contour added by Obj-C simulation
      if contour.edges.count == 0 {
        continue  // don't test degenerate contours
      }

      if contour === testContour || contour.crossesOwnContour(testContour) {
        continue // don't test self intersections
      }

      intersectCount += contour.numberOfIntersectionsWithRay(testCurve)
    }

    // return (intersectCount & 1) == 1 ? .Hole : .Filled
    if intersectCount.isOdd {
      return .Hole
    } else {
      return .Filled
    }
  }

  // 791
  //- (FBCurveLocation *) closestLocationToPoint:(NSPoint)point
  func closestLocationToPoint(point: CGPoint) -> FBCurveLocation? {
    var closestLocation : FBCurveLocation? = nil

    for contour in _contours {
      let contourLocation : FBCurveLocation? = contour.closestLocationToPoint(point)
      if ( contourLocation != nil && (closestLocation == nil || contourLocation!.distance < closestLocation!.distance) ) {
        closestLocation = contourLocation
      }
    }

    if let closestLocation = closestLocation {
      closestLocation.graph = self
      return closestLocation
    } else {
      return nil
    }
  }


  // 809
  //- (NSBezierPath *) debugPathForContainmentOfContour:(FBBezierContour *)testContour
  func debugPathForContainmentOfContour(testContour: FBBezierContour) -> UIBezierPath {
    return debugPathForContainmentOfContour(testContour, transform: CGAffineTransformIdentity)
  }

  // 814
  //- (NSBezierPath *) debugPathForContainmentOfContour:(FBBezierContour *)testContour transform:(NSAffineTransform *)transform
  func debugPathForContainmentOfContour(testContour: FBBezierContour, transform: CGAffineTransform) -> UIBezierPath {
    let path = UIBezierPath()

    var intersectCount = 0
    for contour in self.contours {
      if contour === testContour {
        continue // don't test self intersections
      }

      // Check for self-intersections between this contour and other contours in the same graph
      //  If there are intersections, then don't consider the intersecting contour for the purpose
      //  of determining if we are "filled" or a "hole"
      var intersectsWithThisContour = false

      for edge in contour.edges {
        for oneTestEdge in testContour.edges {
          var unusedRange : FBBezierIntersectRange?
          oneTestEdge.intersectionsWithBezierCurve(edge, overlapRange: &unusedRange) {
            (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

            // These are important so startEdge below doesn't
            // pick an ambigious point as a test
            if intersection.isAtStartOfCurve1 {
              oneTestEdge.startShared = true
            } else if intersection.isAtStopOfCurve1 {
              oneTestEdge.next.startShared = true
            }

            if intersection.isAtStartOfCurve2 {
              edge.startShared = true
            } else if intersection.isAtStopOfCurve2 {
              edge.next.startShared = true
            }

            if oneTestEdge.crossesEdge(edge, atIntersection: intersection) {
              intersectsWithThisContour = true
            }

            return (false, false)   // keep going
          }
        }
      }
      if intersectsWithThisContour {
        continue // skip it
      }

      // Count how many times we intersect with this particular contour
      // Create the line from the first point in the contour to outside the graph
      let testPoint = testContour.testPointForContainment

      // Move us just outside the bounds of the graph
      let beyondX = testPoint.x > CGRectGetMinX(self.bounds) ? CGRectGetMinX(self.bounds) - 10 : CGRectGetMaxX(self.bounds) + 10
      let lineEndPoint = CGPoint(x: beyondX, y: testPoint.y)
      let testCurve = FBBezierCurve(startPoint: testPoint, endPoint: lineEndPoint)
      contour.intersectionsWithRay(testCurve, withBlock: {
        (intersection: FBBezierIntersection) -> Void in
        intersectCount += 1
      })
    }

    // Add the contour's entire path to make it easy to see which one owns
    //   which crossings (these can be colour-coded when drawing the paths)

    let testPoint = testContour.testPointForContainment

    // Move us just outside the bounds of the graph
    let beyondX = testPoint.x > CGRectGetMinX(self.bounds) ? CGRectGetMinX(self.bounds) - 10 : CGRectGetMaxX(self.bounds) + 10
    let lineEndPoint = CGPoint(x: beyondX, y: testPoint.y);
    let testCurve = FBBezierCurve(startPoint: testPoint, endPoint: lineEndPoint)

    let curvePath = testCurve.bezierPath
    curvePath.applyTransform(transform)
    path.appendPath(curvePath)

    // if this countour is flagged as "inside", the debug path is shown dashed, otherwise solid
//    if (intersectCount & 1) == 1 {
    if intersectCount.isOdd {
      let dashes : [CGFloat] = [CGFloat(2), CGFloat(3)]
      path.setLineDash(dashes, count: 2, phase: 0)
    }
    
    return path
  }


  // 882
  //- (NSBezierPath *) debugPathForJointsOfContour:(FBBezierContour *)testContour
  func debugPathForJointsOfContour(testContour: FBBezierContour) -> UIBezierPath {
    let path = UIBezierPath()

    for edge in testContour.edges {
      if !edge.isStraightLine {
        path.moveToPoint(edge.endPoint1)
        path.addLineToPoint(edge.controlPoint1)
        path.appendPath(UIBezierPath.smallCircleAtPoint(edge.controlPoint1))

        path.moveToPoint(edge.endPoint2)
        path.addLineToPoint(edge.controlPoint2)
        path.appendPath(UIBezierPath.smallCircleAtPoint(edge.controlPoint2))
      }
      path.appendPath(UIBezierPath.smallRectAtPoint(edge.endPoint2))
    }
    
    return path
  }


  // 901
  //- (BOOL) containsContour:(FBBezierContour *)testContour
  private func containsContour(testContour: FBBezierContour) -> Bool {

    // Determine the container, if any, for the test contour.
    // We do this by casting a ray from one end of the graph to the other,
    //  and recording the intersections before and after the test contour.
    // If the ray intersects with a contour an odd number of
    //  times on one side, we know it contains the test contour.
    // After determining which contours contain the test contour,
    //  we simply pick the closest one to test contour.
    //
    // Things get a bit more complicated though:
    //
    // If contour shares an edge with the test contour, then it can be impossible
    //  to determine whom contains whom.
    // Or if we hit the test contour at a location where edges joint together (i.e. end points).
    //
    // For this reason, we sit in a loop passing both horizontal and vertical
    //  rays through the graph until we can eliminate the number of potentially
    //  enclosing contours down to 1 or 0.
    //
    // Most times the first ray will find the correct answer, but in some degenerate
    //  cases it will take a few iterations.

    let FBRayOverlap = CGFloat(10.0)

    // Do a relatively cheap bounds test first
    if !FBLineBoundsMightOverlap(self.bounds, bounds2: testContour.bounds) {
      return false
    }

    // In the beginning all our contours are possible containers
    // for the test contour.
    var containers : [FBBezierContour] = self._contours

    // Each time through the loop we split the test contour into
    //  any increasing amount of pieces (halves, thirds, quarters, etc)
    //  and send a ray along the boundaries.
    // In order to increase our changes of eliminating all but 1 of
    //  the contours, we do both horizontal and vertical rays.

    let count = Int(max(ceil(testContour.bounds.width), ceil(testContour.bounds.height)))
    for fraction in 2 ... count * 2 {
      var didEliminate = false

      // Send horizontal rays through the test contour
      //  and (possibly) through parts of the graph
      let verticalSpacing = (testContour.bounds.height) / CGFloat(fraction)
      let yStart = CGRectGetMinY(testContour.bounds) + verticalSpacing
      let yFinir = CGRectGetMaxY(testContour.bounds)
      var y = yStart
      while y < yFinir {
        // Construct a line that will reach outside both ends of both the test contour and graph
        let rayStart = CGPoint(x: min(CGRectGetMinX(self.bounds), CGRectGetMinX(testContour.bounds)) - FBRayOverlap, y: y)
        let rayFinir = CGPoint(x: max(CGRectGetMaxX(self.bounds), CGRectGetMaxX(testContour.bounds)) + FBRayOverlap, y: y)
        let ray = FBBezierCurve(startPoint: rayStart, endPoint: rayFinir)

        // Eliminate any contours that aren't containers.
        // It's possible for this method to fail, so check the return
        let eliminated = eliminateContainers(&containers, thatDontContainContour: testContour, usingRay: ray)
        if eliminated {
          didEliminate = true
        }
        y += verticalSpacing
      }

      // Send vertical rays through the test contour
      //  and (possibly) through parts of the graph
      let horizontalSpacing = (testContour.bounds.width) / CGFloat(fraction)
      let xStart = CGRectGetMinX(testContour.bounds) + horizontalSpacing
      let xFinir = CGRectGetMaxX(testContour.bounds)
      var x = xStart
      while x < xFinir {
        // Construct a line that will reach outside both ends of both the test contour and graph
        let rayStart = CGPoint(x: x, y: min(CGRectGetMinY(self.bounds), CGRectGetMinY(testContour.bounds)) - FBRayOverlap)
        let rayFinir = CGPoint(x: x, y: max(CGRectGetMaxY(self.bounds), CGRectGetMaxY(testContour.bounds)) + FBRayOverlap)
        let ray = FBBezierCurve(startPoint: rayStart, endPoint: rayFinir)

        // Eliminate any contours that aren't containers.
        // It's possible for this method to fail, so check the return
        let eliminated = eliminateContainers(&containers, thatDontContainContour: testContour, usingRay: ray)
        if eliminated {
          didEliminate = true
        }
        x += horizontalSpacing
      }

      // If we've eliminated all the contours, then nothing contains the test contour, and we're done
      if containers.count == 0 {
        return false
      }

      // We were able to eliminate someone, and we're down to one, so we're done.
      // If the eliminateContainers: method failed, we can't make any assumptions
      // about the contains, so just let it go again.
      if didEliminate {
        return containers.count.isOdd
        //return (containers.count & 1) == 1  // fast version of: containers.count % 2 != 0
      }
    }

    // This is a curious case, because by now we've sent rays that went through
    //  every integral cordinate of the test contour.
    // Despite that, eliminateContainers failed each time, meaning one container
    //  has a shared edge for each ray test.
    // It is likely that contour is equal (the same) as the test contour.
    // Return false, because if it is equal, it doesn't contain.
    return false
  }


  // 967
  //- (BOOL) findBoundsOfContour:(FBBezierContour *)testContour onRay:(FBBezierCurve *)ray minimum:(NSPoint *)testMinimum maximum:(NSPoint *)testMaximum
  private func findBoundsOfContour(testContour: FBBezierContour, onRay ray: FBBezierCurve, inout minimum testMinimum: CGPoint, inout maximum testMaximum: CGPoint) -> Bool {

    // Find the bounds of test contour that lie on ray.
    // Simply intersect the ray with test contour.

    // For a horizontal ray, the minimum is the point with the lowest x value,
    // the maximum with the highest x value.

    // For a vertical ray, use the high and low y values.

    let horizontalRay = ray.endPoint1.y == ray.endPoint2.y  // ray has to be a vertical or horizontal line

    // First find all the intersections with the ray
    var rayIntersections : [FBBezierIntersection] = []
    var unusedRange : FBBezierIntersectRange?
    for edge in testContour.edges {
      ray.intersectionsWithBezierCurve(edge, overlapRange: &unusedRange) {
        (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

        rayIntersections.append(intersection)
        return (false, false)   // keep going
      }
    }
    if rayIntersections.count == 0 {
      return false // shouldn't happen
    }

    // Next; go through and find the lowest and highest
    let firstRayIntersection = rayIntersections[0]
    testMinimum = firstRayIntersection.location
    testMaximum = testMinimum
    for intersection in rayIntersections {
      if ( horizontalRay ) {
        if intersection.location.x < testMinimum.x {
          testMinimum = intersection.location
        }
        if intersection.location.x > testMaximum.x {
          testMaximum = intersection.location
        }
      } else {
        if intersection.location.y < testMinimum.y {
          testMinimum = intersection.location
        }
        if intersection.location.y > testMaximum.y {
          testMaximum = intersection.location
        }
      }
    }
    return true
  }


  // 1004
  //- (BOOL) findCrossingsOnContainers:(NSArray *)containers onRay:(FBBezierCurve *)ray beforeMinimum:(NSPoint)testMinimum afterMaximum:(NSPoint)testMaximum crossingsBefore:(NSMutableArray *)crossingsBeforeMinimum crossingsAfter:(NSMutableArray *)crossingsAfterMaximum
  private func findCrossingsOnContainers(containers: [FBBezierContour], onRay ray: FBBezierCurve, beforeMinimum testMinimum: CGPoint, afterMaximum testMaximum: CGPoint, inout crossingsBefore crossingsBeforeMinimum: [FBEdgeCrossing], inout crossingsAfter crossingsAfterMaximum: [FBEdgeCrossing]) -> Bool {

    // Find intersections where the ray intersects the possible containers
    // before the minimum point, or after the maximum point.
    // Store these as FBEdgeCrossings in the out parameters.

    let horizontalRay = ray.endPoint1.y == ray.endPoint2.y; // ray has to be a vertical or horizontal line

    // Walk through each possible container, one at a time and see where it intersects
    var ambiguousCrossings : [FBEdgeCrossing] = []
    for container in containers {
      for containerEdge in container.edges {
        // See where the ray intersects this particular edge
        var ambigious = false
        var unusedRange : FBBezierIntersectRange?

        ray.intersectionsWithBezierCurve(containerEdge, overlapRange: &unusedRange) {
          (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

          if intersection.isTangent {
            return (false, false)   // tangents don't count
          }

          // If the ray intersects one of the contours at a joint (end point),
          // then we won't be able to make any accurate conclusions,
          // so bail now, and say we failed.
          if intersection.isAtEndPointOfCurve2 {
            ambigious = true
            return (true, true) // stop
          }

          // If the point lies inside the min and max bounds specified,
          // just skip over it. We only want to remember the intersections
          // that fall on or outside of the min and max.
          if horizontalRay && FBIsValueLessThan(intersection.location.x, maximum: testMaximum.x) && FBIsValueGreaterThan(intersection.location.x, minimum: testMinimum.x) {
            return (false, false)
          } else if !horizontalRay && FBIsValueLessThan(intersection.location.y, maximum: testMaximum.y) && FBIsValueGreaterThan(intersection.location.y, minimum: testMinimum.y) {
            return (false, false)
          }

          // Create a crossing for it so we know what edge it is associated with.
          // Don't insert it into a graph or anything though.
          let crossing = FBEdgeCrossing(intersection: intersection)
          crossing.edge = containerEdge

          // Special case if the bounds are just a point, and this crossing is on that point.
          // In that case it could fall on either side, and we'll need to do some special
          // processing on it later.
          // For now, remember it, and move on to the next intersection.
          if CGPointEqualToPoint(testMaximum, testMinimum) && CGPointEqualToPoint(testMaximum, intersection.location) {
            ambiguousCrossings.append(crossing)
            return (false, false)
          }

          // This crossing falls outse the bounds, so add it to the appropriate array

          if horizontalRay && FBIsValueLessThanEqual(intersection.location.x, maximum: testMinimum.x) {
            crossingsBeforeMinimum.append(crossing)
          } else if !horizontalRay && FBIsValueLessThanEqual(intersection.location.y, maximum: testMinimum.y) {
            crossingsBeforeMinimum.append(crossing)
          }
          if horizontalRay && FBIsValueGreaterThanEqual(intersection.location.x, minimum: testMaximum.x) {
            crossingsAfterMaximum.append(crossing)
          } else if !horizontalRay && FBIsValueGreaterThanEqual(intersection.location.y, minimum: testMaximum.y) {
            crossingsAfterMaximum.append(crossing)
          }
          return (false, false)
        }

        if ambigious {
          return false
        }
      }
    }

    // Handle any intersects that are ambigious.
    // i.e. the min and max are one point, and the intersection is on that point.
    for ambiguousCrossing in ambiguousCrossings {
      // See how many times the given contour crosses on each side.
      // Add the ambigious crossing to the side that has less,
      // in hopes of balancing it out.
      if let ambigEdge = ambiguousCrossing.edge, edgeContour = ambigEdge.contour {
        let numberOfTimesContourAppearsBefore = numberOfTimesContour(edgeContour, appearsInCrossings: crossingsBeforeMinimum)
        let numberOfTimesContourAppearsAfter = numberOfTimesContour(edgeContour, appearsInCrossings:crossingsAfterMaximum)
        if numberOfTimesContourAppearsBefore < numberOfTimesContourAppearsAfter {
          crossingsBeforeMinimum.append(ambiguousCrossing)
        } else {
          crossingsAfterMaximum.append(ambiguousCrossing)
        }
      }
    }
    
    return true
  }




  // 1078
  //- (NSUInteger) numberOfTimesContour:(FBBezierContour *)contour appearsInCrossings:(NSArray *)crossings
  private func numberOfTimesContour(contour: FBBezierContour, appearsInCrossings crossings: [FBEdgeCrossing]) -> Int {
    // Count how many times a contour appears in a crossings array
    var count = 0
    for crossing in crossings {
      if let crossingEdge = crossing.edge {
        if crossingEdge.contour === contour {
          count += 1
        }
      }
    }
    return count
  }


  // 1089
  //- (BOOL) eliminateContainers:(NSMutableArray *)containers thatDontContainContour:(FBBezierContour *)testContour usingRay:(FBBezierCurve *)ray
  private func eliminateContainers(inout containers: [FBBezierContour], thatDontContainContour testContour: FBBezierContour, usingRay ray: FBBezierCurve) -> Bool {

    // This method attempts to eliminate all or all but one of the containers
    // that might contain the test contour, using the ray specified.

    // First determine the exterior bounds of testContour on the given ray
    var testMinimum = CGPoint.zero
    var testMaximum = CGPoint.zero
    let foundBounds = findBoundsOfContour(testContour, onRay: ray, minimum: &testMinimum, maximum: &testMaximum)

    if !foundBounds {
      return false
    }

    // Find all the containers on either side of the otherContour
    var crossingsBeforeMinimum : [FBEdgeCrossing] = []
    var crossingsAfterMaximum : [FBEdgeCrossing] = []
    let foundCrossings = findCrossingsOnContainers(containers, onRay: ray, beforeMinimum: testMinimum, afterMaximum: testMaximum, crossingsBefore: &crossingsBeforeMinimum, crossingsAfter:&crossingsAfterMaximum)

    if !foundCrossings {
      return false
    }

    // Remove containers that appear an even number of times on either side
    // because by the even/odd rule they can't contain test contour.
    removeContoursThatDontContain(&crossingsBeforeMinimum)
    removeContoursThatDontContain(&crossingsAfterMaximum)

    // Remove containers that appear only on one side
    removeContourCrossings(&crossingsBeforeMinimum, thatDontAppearIn: crossingsAfterMaximum)
    removeContourCrossings(&crossingsAfterMaximum, thatDontAppearIn: crossingsBeforeMinimum)

    // Although crossingsBeforeMinimum and crossingsAfterMaximum contain different crossings,
    // they should contain the same contours, so just pick one to pull the contours from
    containers = contoursFromCrossings(crossingsBeforeMinimum)
    
    return true
  }


  // 1123
  //- (NSArray *) contoursFromCrossings:(NSArray *)crossings
  private func contoursFromCrossings(crossings: [FBEdgeCrossing]) -> [FBBezierContour] {

    // Determine all the unique contours in the array of crossings
    var contours : [FBBezierContour] = []
    for crossing in crossings {
      if let crossingEdge = crossing.edge {
        if let contour = crossingEdge.contour {
          // if ( ![contours containsObject:crossing.edge.contour] )
          if contours.filter({ el in el === contour }).count == 0 {
            contours.append(contour)
          }
        }
      }
    }
    return contours
  }


  // 1134
  //- (void) removeContourCrossings:(NSMutableArray *)crossings1 thatDontAppearIn:(NSMutableArray *)crossings2
  private func removeContourCrossings(inout crossings1: [FBEdgeCrossing], thatDontAppearIn crossings2: [FBEdgeCrossing]) {

    // If a contour appears in crossings1, but not crossings2, remove all the associated crossings from
    //  crossings1.

    var containersToRemove : [FBBezierContour] = []
    for crossingToTest in crossings1 {
      var existsInOther = true
      if let containerToTest = crossingToTest.edge?.contour {
        // See if this contour exists in the other array
        for crossing in crossings2 {
          if crossing.edge?.contour === containerToTest {
            existsInOther = true
            break
          }
        }
        // If it doesn't exist in our counterpart, mark it for death
        if !existsInOther {
          containersToRemove.append(containerToTest)
        }
      }
    }
    removeCrossings(&crossings1, forContours: containersToRemove)
  }


  // 1157
  //- (void) removeContoursThatDontContain:(NSMutableArray *)crossings
  private func removeContoursThatDontContain(inout crossings: [FBEdgeCrossing]) {

    // Remove contours that cross the ray an even number of times.
    // By the even/odd rule this means they can't contain the test contour.
    var containersToRemove : [FBBezierContour] = []

    for crossingToTest in crossings {
      // For this contour, count how many times it appears in the crossings array
      if let containerToTest = crossingToTest.edge?.contour {
        var count = 0
        for crossing in crossings {
          if crossing.edge?.contour === containerToTest {
            count += 1
          }
        }
        // If it's not an odd number of times, it doesn't contain
        // the test contour, so mark it for death
        //if (count % 2) != 1 {
        if count.isEven {
          containersToRemove.append(containerToTest)
        }
      }
    }
    removeCrossings(&crossings, forContours: containersToRemove)
  }


  // 1177
  //- (void) removeCrossings:(NSMutableArray *)crossings forContours:(NSArray *)containersToRemove
  private func removeCrossings(inout crossings: [FBEdgeCrossing], forContours containersToRemove: [FBBezierContour]) {

    // A helper method that goes through and removes all the
    // crossings that appear on the specified contours.

    // First walk through and identify which crossings to remove
    var crossingsToRemove : [FBEdgeCrossing] = []
    for contour in containersToRemove {
      for crossing in crossings {
        if crossing.edge?.contour === contour {
          crossingsToRemove.append(crossing)
        }
      }
    }

    // Now walk through and remove the crossings
    for crossing in crossingsToRemove {
      //[crossings removeObject:crossing];
      for (index, element) in crossings.enumerate()
      {
        if element === crossing
        {
          crossings.removeAtIndex(index)
          break
        }
      }
    }
  }


  // 1195
  //- (void) markAllCrossingsAsUnprocessed
  private func markAllCrossingsAsUnprocessed() {
    for contour in _contours {
      for edge in contour.edges {

        edge.crossingsWithBlock() {
          (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in
          crossing.processed = false
          return (false, false)
        }

      }
    }
  }


  // 1205
  //- (FBEdgeCrossing *) firstUnprocessedCrossing
  private var firstUnprocessedCrossing : FBEdgeCrossing? {

    // Find the first crossing in our graph that has yet to be processed
    // by the bezierGraphFromIntersections method.

    for contour in _contours {
      for edge in contour.edges {
        var unprocessedCrossing : FBEdgeCrossing?
        edge.crossingsWithBlock() {
          (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in

          if crossing.isSelfCrossing {
            return (false, false)
          }
          if !crossing.isProcessed {
            unprocessedCrossing = crossing
            return (true, true)
          }
          return (false, false)
        }

        if unprocessedCrossing != nil {
          return unprocessedCrossing!
        }
      }
    }
    return nil
  }


  // 1228
  //- (FBBezierGraph *) bezierGraphFromIntersections
  private var bezierGraphFromIntersections : FBBezierGraph {

    // This method walks the current graph, starting at the crossings,
    // and outputs the final contours of the parts of the graph that
    // actually intersect.
    //
    // The general algorithm is:
    //
    //   Start a crossing we haven't seen before.
    //
    //   If it's marked as entry, start outputing edges moving forward
    //   (i.e. using edge.next) until another crossing is hit.
    //   - (If a crossing is marked as exit, start outputting edges
    //     moving backwards, using edge.previous.)
    //
    //   Once the next crossing is hit, switch to the crossing's
    //   counterpart in the other graph, and process it in the same way.
    //
    //   Continue this until we reach a crossing that's been processed.

    let result = FBBezierGraph()

    // Find the first crossing to start one
    var optCrossing : FBEdgeCrossing? = firstUnprocessedCrossing
    while var crossing = optCrossing {
      // This is the start of a contour, so create one
      let contour = FBBezierContour()
      result.addContour(contour)

      // Keep going until we run into a crossing we've seen before.
      while !crossing.isProcessed {
        crossing.processed = true // ...and we've just seen this one

        if crossing.isEntry {
          // Keep going to next until meet a crossing
          contour.addCurveFrom(crossing, to: crossing.nextNonself)

          if let nextNon = crossing.nextNonself {
            crossing = nextNon    // this edge has a crossing, so just move to it
          } else {
            // We hit the end of the edge without finding another crossing,
            // so go find the next crossing
            if let crossingEdge = crossing.edge {
              var edge : FBBezierCurve = crossingEdge.next
              while !edge.hasNonselfCrossings {
                // output this edge whole
                // make a copy to add. contours don't share too good
                contour.addCurve(edge.clone())

                edge = edge.next
              }
              // We have an edge that has at least one crossing
              crossing = edge.firstNonselfCrossing!
              contour.addCurveFrom(nil, to: crossing)  // add the curve up to the crossing
            }
          }
        } else {
          // Keep going to previous until meet a crossing
          contour.addReverseCurveFrom(crossing.previousNonself, to: crossing)

          if let prevNonself = crossing.previousNonself {
            crossing = prevNonself
          } else {
            // we hit the end of the edge without finding another crossing,
            // so go find the previous crossing
            if let crossingEdge = crossing.edge {   // should ALWAYS be the case
              var edge : FBBezierCurve = crossingEdge.previous
              while !edge.hasNonselfCrossings {
                // output this edge whole
                contour.addReverseCurve(edge)

                edge = edge.previous
              }
              // We have an edge that has at least one edge
              crossing = edge.lastNonselfCrossing!
              contour.addReverseCurveFrom(crossing, to: nil) // add the curve up to the crossing
            } else {
              print("This is bad, really bad")
            }
          }
        }

        // Switch over to counterpart in the other graph
        crossing.processed = true
        crossing = crossing.counterpart!
      }

      // See if there's another contour that we need to handle
      optCrossing = firstUnprocessedCrossing
    }

    return result
  }


  // 1298
  //- (void) removeCrossings
  private func removeCrossings() {
    // Crossings only make sense for the intersection between two specific graphs.
    // In order for this graph to be usable in the future, remove all the crossings
    for contour in _contours {
      for edge in contour.edges {
        edge.removeAllCrossings()
      }
    }
  }


  // 1307
  //- (void) removeOverlaps
  private func removeOverlaps() {
    for contour in _contours {
      contour.removeAllOverlaps()
    }
  }

  // 1313
  //- (void) addContour:(FBBezierContour *)contour
  private func addContour(contour: FBBezierContour) {
    // Add a contour to ouselves, and force the bounds to be recalculated
    _contours.append(contour)
    _bounds = CGRectNull
  }

  // 1320
  //- (NSArray *) nonintersectingContours
  private var nonintersectingContours : [FBBezierContour] {
    // Find all the contours that have no crossings on them.
    var contours : [FBBezierContour] = []
    for contour in self.contours {
      if contour.intersectingContours.count == 0 {
        contours.append(contour)
      }
    }
    return contours
  }

  // 1331
  //- (void) debuggingInsertCrossingsForUnionWithBezierGraph:(FBBezierGraph *)otherGraph
  func debuggingInsertCrossingsForUnionWithBezierGraph(inout otherGraph: FBBezierGraph) {
    debuggingInsertCrossingsWithBezierGraph(&otherGraph, markInside: false, markOtherInside: false)
  }

  // 1336
  //- (void) debuggingInsertCrossingsForIntersectWithBezierGraph:(FBBezierGraph *)otherGraph
  func debuggingInsertCrossingsForIntersectWithBezierGraph(inout otherGraph: FBBezierGraph) {
    debuggingInsertCrossingsWithBezierGraph(&otherGraph, markInside: true, markOtherInside: true)
  }

  // 1341
  //- (void) debuggingInsertCrossingsForDifferenceWithBezierGraph:(FBBezierGraph *)otherGraph
  func debuggingInsertCrossingsForDifferenceWithBezierGraph(inout otherGraph: FBBezierGraph) {
    debuggingInsertCrossingsWithBezierGraph(&otherGraph, markInside: false, markOtherInside: true)
  }

  // 1346
  //- (void) debuggingInsertCrossingsWithBezierGraph:(FBBezierGraph *)otherGraph markInside:(BOOL)markInside markOtherInside:(BOOL)markOtherInside
  private func debuggingInsertCrossingsWithBezierGraph(inout otherGraph: FBBezierGraph, markInside: Bool, markOtherInside: Bool) {

    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    self.removeCrossings()
    otherGraph.removeCrossings()
    self.removeOverlaps()
    otherGraph.removeOverlaps()

    // First insert FBEdgeCrossings into both graphs where the graphs cross.
    insertCrossingsWithBezierGraph(otherGraph)
    self.insertSelfCrossings()
    otherGraph.insertSelfCrossings()

    // Handle the parts of the graphs that intersect first. Mark the parts
    //  of the graphs that are inside the other for the final result.
    self.markCrossingsAsEntryOrExitWithBezierGraph(otherGraph, markInside: markInside)
    otherGraph.markCrossingsAsEntryOrExitWithBezierGraph(self, markInside: markOtherInside)
  }

  // 1365
  //- (void) debuggingInsertIntersectionsWithBezierGraph:(FBBezierGraph *)otherGraph
  private func debuggingInsertIntersectionsWithBezierGraph(inout otherGraph: FBBezierGraph) {

    // Clean up crossings so the graphs can be reused, e.g. XOR will reuse graphs.
    self.removeCrossings()
    otherGraph.removeCrossings()
    self.removeOverlaps()
    otherGraph.removeOverlaps()

    for ourContour in contours {
      for ourEdge in ourContour.edges {
        for theirContour in otherGraph.contours {
          for theirEdge in theirContour.edges {
            // Find all intersections between these two edges (curves)
            var intersectRange : FBBezierIntersectRange?
            ourEdge.intersectionsWithBezierCurve(theirEdge, overlapRange: &intersectRange) {
              (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

              let ourCrossing = FBEdgeCrossing(intersection: intersection)
              let theirCrossing = FBEdgeCrossing(intersection: intersection)
              ourCrossing.counterpart = theirCrossing
              theirCrossing.counterpart = ourCrossing
              ourEdge.addCrossing(ourCrossing)
              theirEdge.addCrossing(theirCrossing)
              return (false, false)
            }
          }
        }
      }
    }
  }


  // ===================
}
