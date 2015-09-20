//
//  FBEdgeOverlapRun.swift
//  Swift VectorBoolean for iOS
//
//  Based on part of FBContourOverlap - Created by Andrew Finnell on 11/7/12.
//  Copyright (c) 2012 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-07-02.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import UIKit

class FBEdgeOverlapRun {

  var overlaps : [FBEdgeOverlap] = []


  //- (BOOL) insertOverlap:(FBEdgeOverlap *)overlap
  func insertOverlap(overlap: FBEdgeOverlap) -> Bool {

    if overlaps.count == 0 {
      // The first one always works
      overlaps.append(overlap)
      return true
    }

    // Check to see if overlap fits after our last overlap
    if let lastOverlap = overlaps.last {
      if lastOverlap.fitsBefore(overlap) {
        overlaps.append(overlap)
        return true
      }
    }

    // Check to see if overlap fits before our first overlap
    if let firstOverlap = overlaps.first {
      if firstOverlap.fitsAfter(overlap) {
        overlaps.insert(overlap, atIndex: 0)
        return true
      }
    }

    return false
  }


  //- (BOOL) isComplete
  var isComplete : Bool {
    // To be complete, we should wrap around
    if overlaps.count == 0 {
      return false
    }

    if let lastOverlap = overlaps.last {
      let firstOverlap = overlaps[0]
      return lastOverlap.fitsBefore(firstOverlap)
    }

    return false
  }


  //- (BOOL) doesContainCrossing:(FBEdgeCrossing *)crossing
  func doesContainCrossing(crossing: FBEdgeCrossing) -> Bool {
    if let crossingEdge = crossing.edge {
      return doesContainParameter(crossing.parameter, onEdge: crossingEdge)
    } else {
      return false
    }
  }


  //- (BOOL) doesContainParameter:(CGFloat)parameter onEdge:(FBBezierCurve *)edge
  func doesContainParameter(parameter: Double, onEdge edge: FBBezierCurve) -> Bool {
    if overlaps.count == 0 {
      return false
    }

    // Find the FBEdgeOverlap that contains the crossing (if it exists)
    var containingOverlap : FBEdgeOverlap?
    for overlap in overlaps {
      if overlap.edge1 == edge || overlap.edge2 == edge {
        containingOverlap = overlap
        break
      }
    }

    // The edge it's attached to isn't here
    if let containingOverlap = containingOverlap {

      let lastOverlap = overlaps.last
      let firstOverlap = overlaps[0]

      let atTheStart = containingOverlap === firstOverlap
      let extendsBeforeStart = !atTheStart || (atTheStart && lastOverlap!.fitsBefore(firstOverlap))

      let atTheEnd = containingOverlap === lastOverlap
      let extendsAfterEnd = !atTheEnd || (atTheEnd && firstOverlap.fitsAfter(lastOverlap!))

      return containingOverlap.doesContainParameter(parameter, onEdge: edge, startExtends: extendsBeforeStart, endExtends: extendsAfterEnd)
    } else {
      return false
    }
  }


  //- (BOOL) isCrossing
  var isCrossing : Bool {
    // The intersection happens at the end of one of the edges,
    // meaning we'll have to look at the next edge in sequence
    // to see if it crosses or not.
    //
    // We'll do that by computing the four tangents at the exact
    // point the intersection takes place.
    //
    // We'll compute the polar angle for each of the tangents.
    // If the angles of self split the angles of edge2
    // (i.e. they alternate when sorted), then the edges cross.
    //
    // If any of the angles are equal or if the angles group up,
    // then the edges don't cross.

    // Calculate the four tangents:
    //   The two tangents moving away from the intersection point on self,
    //   the two tangents moving away from the intersection point on edge2.

    let firstOverlap = overlaps[0]
    if let lastOverlap = overlaps.last {

      var edge1Tangents = FBTangentPair(left: CGPoint.zero, right: CGPoint.zero)
      var edge2Tangents = FBTangentPair(left: CGPoint.zero, right: CGPoint.zero)

      var offset = 0.0
      var maxOffset = 0.0

      repeat {
        let length1 = FBComputeEdge1Tangents(firstOverlap, lastOverlap: lastOverlap, offset: offset, edge1Tangents: &edge1Tangents)
        let length2 = FBComputeEdge2Tangents(firstOverlap, lastOverlap: lastOverlap, offset: offset, edge2Tangents: &edge2Tangents)
        maxOffset = min(length1, length2);

        offset += 1.0
      } while ( FBAreTangentsAmbigious(edge1Tangents, edge2Tangents: edge2Tangents) && offset < maxOffset);

      if FBTangentsCross(edge1Tangents, edge2Tangents: edge2Tangents) {
        return true
      }

      // Tangents work, mostly, for overlaps. If we get a yes, it's solid.
      // If we get a no, it might still be a crossing.
      // Only way to tell now is to perform an actual point test
      var testPoints = FBTangentPair(left: CGPoint.zero, right: CGPoint.zero)
      FBComputeEdge1TestPoints(firstOverlap, lastOverlap: lastOverlap, offset: 1.0, testPoints: &testPoints)
      if let contour2 = firstOverlap.edge2.contour {
        let testPoint1Inside = contour2.containsPoint(testPoints.left)
        let testPoint2Inside = contour2.containsPoint(testPoints.right)
        return testPoint1Inside != testPoint2Inside
      }
    }

    return false
  }


  //- (void) addCrossings
  func addCrossings() {
    // Add crossings to both graphs for this intersection/overlap.
    // Pick the middle point and use that
    if overlaps.count == 0 {
      return
    }

    let middleOverlap = overlaps[overlaps.count / 2]
    middleOverlap.addMiddleCrossing()
  }


  //- (FBBezierContour *) contour1
  var contour1 : FBBezierContour? {

    if overlaps.count == 0 {
      return nil
    }

    let overlap = overlaps[0]

    return overlap.edge1.contour
  }


  //- (FBBezierContour *) contour2
  var contour2 : FBBezierContour? {

    if overlaps.count == 0 {
      return nil
    }

    let overlap = overlaps[0]

    return overlap.edge2.contour
  }

}

// =============================
// MARK: Utility functions
// =============================

//static CGFloat FBComputeEdge1Tangents(FBEdgeOverlap *firstOverlap, FBEdgeOverlap *lastOverlap, CGFloat offset, NSPoint edge1Tangents[2])
func FBComputeEdge1Tangents(firstOverlap: FBEdgeOverlap, lastOverlap: FBEdgeOverlap, offset: Double, inout edge1Tangents: FBTangentPair) -> Double {

  // edge1Tangents are firstOverlap.range1.minimum going to previous
  // and lastOverlap.range1.maximum going to next

  var firstLength = 0.0
  var lastLength = 0.0

  if firstOverlap.range.isAtStartOfCurve1 {
    let otherEdge1 = firstOverlap.edge1.previousNonpoint
    edge1Tangents.left = otherEdge1.tangentFromRightOffset(offset)
    firstLength = otherEdge1.length()
  } else {
    edge1Tangents.left = firstOverlap.range.curve1LeftBezier.tangentFromRightOffset(offset)
    firstLength = firstOverlap.range.curve1LeftBezier.length()
  }

  if lastOverlap.range.isAtStopOfCurve1 {
    let otherEdge1 = lastOverlap.edge1.nextNonpoint
    edge1Tangents.right = otherEdge1.tangentFromLeftOffset(offset)
    lastLength = otherEdge1.length()
  } else {
    edge1Tangents.right = lastOverlap.range.curve1RightBezier.tangentFromLeftOffset(offset)
    lastLength = lastOverlap.range.curve1RightBezier.length()
  }

  return min(firstLength, lastLength)
}


//static CGFloat FBComputeEdge2Tangents(FBEdgeOverlap *firstOverlap, FBEdgeOverlap *lastOverlap, CGFloat offset, NSPoint edge2Tangents[2])
func FBComputeEdge2Tangents(firstOverlap: FBEdgeOverlap, lastOverlap: FBEdgeOverlap, offset: Double, inout edge2Tangents: FBTangentPair) -> Double {

  // edge2Tangents are firstOverlap.range2.minimum going to previous
  // and lastOverlap.range2.maximum going to next
  //  unless reversed, then
  // edge2Tangents are firstOverlap.range2.maximum going to next
  // and lastOverlap.range2.minimum going to previous

  var firstLength = 0.0
  var lastLength = 0.0

  if !firstOverlap.range.reversed {
    if firstOverlap.range.isAtStartOfCurve2 {
      let otherEdge2 = firstOverlap.edge2.previousNonpoint
      edge2Tangents.left = otherEdge2.tangentFromRightOffset(offset)
      firstLength = otherEdge2.length()
    } else {
      edge2Tangents.left = firstOverlap.range.curve2LeftBezier.tangentFromRightOffset(offset)
      firstLength = firstOverlap.range.curve2LeftBezier.length()
    }

    if lastOverlap.range.isAtStopOfCurve2 {
      let otherEdge2 = lastOverlap.edge2.nextNonpoint
      edge2Tangents.right = otherEdge2.tangentFromLeftOffset(offset)
      lastLength = otherEdge2.length()
    } else {
      edge2Tangents.right = lastOverlap.range.curve2RightBezier.tangentFromLeftOffset(offset)
      lastLength = lastOverlap.range.curve2RightBezier.length()
    }

  } else {
    if firstOverlap.range.isAtStopOfCurve2 {
      let otherEdge2 = firstOverlap.edge2.nextNonpoint
      edge2Tangents.left = otherEdge2.tangentFromLeftOffset(offset)
      firstLength = otherEdge2.length()
    } else {
      edge2Tangents.left = firstOverlap.range.curve2RightBezier.tangentFromLeftOffset(offset)
      firstLength = firstOverlap.range.curve2RightBezier.length()
    }

    if lastOverlap.range.isAtStartOfCurve2 {
      let otherEdge2 = lastOverlap.edge2.previousNonpoint
      edge2Tangents.right = otherEdge2.tangentFromRightOffset(offset)
      lastLength = otherEdge2.length()
    } else {
      edge2Tangents.right = lastOverlap.range.curve2LeftBezier.tangentFromRightOffset(offset)
      lastLength = lastOverlap.range.curve2LeftBezier.length()
    }
  }

  return min(firstLength, lastLength)
}

//static void FBComputeEdge1TestPoints(FBEdgeOverlap *firstOverlap, FBEdgeOverlap *lastOverlap, CGFloat offset, NSPoint testPoints[2])
func FBComputeEdge1TestPoints(firstOverlap: FBEdgeOverlap, lastOverlap: FBEdgeOverlap, offset: Double, inout testPoints: FBTangentPair) {

  // edge1Tangents are firstOverlap.range1.minimum going to previous
  // and lastOverlap.range1.maximum going to next
  if firstOverlap.range.isAtStartOfCurve1 {
    let otherEdge1 = firstOverlap.edge1.previousNonpoint
    testPoints.left = otherEdge1.pointFromRightOffset(offset)
  } else {
    testPoints.left = firstOverlap.range.curve1LeftBezier.pointFromRightOffset(offset)
  }

  if lastOverlap.range.isAtStopOfCurve1 {
    let otherEdge1 = lastOverlap.edge1.nextNonpoint
    testPoints.right = otherEdge1.pointFromLeftOffset(offset)
  } else {
    testPoints.right = lastOverlap.range.curve1RightBezier.pointFromLeftOffset(offset)
  }
}


