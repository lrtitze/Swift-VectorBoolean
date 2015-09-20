//
//  FBBezierCurve_Edge.swift
//  Swift VectorBoolean for iOS
//
//  Based on FBBezierCurve - Created by Andrew Finnell on 7/3/13.
//  Copyright (c) 2013 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-07-01.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import UIKit

// 18
//static void FBFindEdge1TangentCurves(FBBezierCurve *edge, FBBezierIntersection *intersection, FBBezierCurve** leftCurve, FBBezierCurve **rightCurve)
private func FBFindEdge1TangentCurves(edge: FBBezierCurve, intersection: FBBezierIntersection) -> (leftCurve: FBBezierCurve, rightCurve: FBBezierCurve) {

  var leftCurve: FBBezierCurve, rightCurve: FBBezierCurve

  if intersection.isAtStartOfCurve1 {
    leftCurve = edge.previousNonpoint
    rightCurve = edge
  } else if intersection.isAtStopOfCurve1 {
    leftCurve = edge
    rightCurve = edge.nextNonpoint
  } else {
    leftCurve = intersection.curve1LeftBezier
    rightCurve = intersection.curve1RightBezier
  }

  return (leftCurve: leftCurve, rightCurve: rightCurve)
}

// 32
//static void FBFindEdge2TangentCurves(FBBezierCurve *edge, FBBezierIntersection *intersection, FBBezierCurve** leftCurve, FBBezierCurve **rightCurve)
private func FBFindEdge2TangentCurves(edge: FBBezierCurve, intersection: FBBezierIntersection) -> (leftCurve: FBBezierCurve, rightCurve: FBBezierCurve) {

  var leftCurve: FBBezierCurve, rightCurve: FBBezierCurve

  if intersection.isAtStartOfCurve2 {
    leftCurve = edge.previousNonpoint
    rightCurve = edge
  } else if intersection.isAtStopOfCurve2 {
    leftCurve = edge
    rightCurve = edge.nextNonpoint
  } else {
    leftCurve = intersection.curve2LeftBezier
    rightCurve = intersection.curve2RightBezier
  }

  return (leftCurve: leftCurve, rightCurve: rightCurve)
}

// 46
//static void FBComputeEdgeTangents(FBBezierCurve* leftCurve, FBBezierCurve *rightCurve, CGFloat offset, NSPoint edgeTangents[2])
private func FBComputeEdgeTangents(leftCurve: FBBezierCurve, rightCurve: FBBezierCurve, offset: CGFloat, inout edgeTangents: FBTangentPair) {
  edgeTangents.left = leftCurve.tangentFromRightOffset(offset)
  edgeTangents.right = rightCurve.tangentFromLeftOffset(offset)
}

// 53
private func FBComputeEdge1RangeTangentCurves(edge: FBBezierCurve, intersectRange: FBBezierIntersectRange) -> (leftCurve: FBBezierCurve, rightCurve: FBBezierCurve) {

  var leftCurve: FBBezierCurve, rightCurve: FBBezierCurve

  // edge1Tangents are firstOverlap.range1.minimum going to previous
  // and lastOverlap.range1.maximum going to next
  if intersectRange.isAtStartOfCurve1 {
    leftCurve = edge.previousNonpoint
  } else {
    leftCurve = intersectRange.curve1LeftBezier
  }

  if intersectRange.isAtStopOfCurve1 {
    rightCurve = edge.nextNonpoint
  } else {
    rightCurve = intersectRange.curve1RightBezier
  }
  return (leftCurve: leftCurve, rightCurve: rightCurve)
}

// 66
private func FBComputeEdge2RangeTangentCurves(edge: FBBezierCurve, intersectRange: FBBezierIntersectRange) -> (leftCurve: FBBezierCurve, rightCurve: FBBezierCurve) {

  var leftCurve: FBBezierCurve, rightCurve: FBBezierCurve

  // edge2Tangents are firstOverlap.range2.minimum going to previous
  // and lastOverlap.range2.maximum going to next
  if intersectRange.isAtStartOfCurve2 {
    leftCurve = edge.previousNonpoint
  } else {
    leftCurve = intersectRange.curve2LeftBezier
  }

  if intersectRange.isAtStopOfCurve2 {
    rightCurve = edge.nextNonpoint
  } else {
    rightCurve = intersectRange.curve2RightBezier
  }
  return (leftCurve: leftCurve, rightCurve: rightCurve)
}

extension FBBezierCurve {

  // MARK: Public funcs

  // 119
  //- (void) addCrossing:(FBEdgeCrossing *)crossing
  func addCrossing(crossing: FBEdgeCrossing) {
    // Make sure the crossing can make it back to us,
    // and keep all the crossings sorted
    crossing.edge = self
    crossings.append(crossing)
    sortCrossings()
  }

  // 127
  //- (void) removeCrossing:(FBEdgeCrossing *)crossing
  func removeCrossing(crossing: FBEdgeCrossing) {
    // Keep the crossings sorted
    //crossing.edge = nil   // cannot nil a non-optional

    //[_crossings removeObject:crossing];
    for (index, element) in crossings.enumerate()
    {
      if element === crossing
      {
        crossings.removeAtIndex(index)
        break
      }
    }

    sortCrossings()
  }

  // 135
  //- (void) removeAllCrossings
  func removeAllCrossings() {
    crossings.removeAll()
  }

  // 140
  //- (FBBezierCurve *)next
  var next : FBBezierCurve {
    var nxt : FBBezierCurve = self

    if let contour = contour {
      if contour.edges.count > 0 {
        let nextIndex = index + 1
        if nextIndex >= contour.edges.count {
          // wrap to front
          nxt = contour.edges.first!
        } else {
          nxt = contour.edges[nextIndex]
        }
      }
    }
    return nxt
  }


  // 151
  //- (FBBezierCurve *)previous
  var previous : FBBezierCurve {
    var prev : FBBezierCurve = self

    if let contour = contour {
      if contour.edges.count > 0 {
        if index == 0 {
          // wrap to end
          prev = contour.edges.last!
        } else {
          prev = contour.edges[index-1]
        }
      }
    }
    return prev
  }

  // 162
  //- (FBBezierCurve *) nextNonpoint
  var nextNonpoint : FBBezierCurve {
    var edge = self.next
    while edge.isPoint {
      edge = edge.next
    }
    return edge
  }

  // 170
  //- (FBBezierCurve *) previousNonpoint
  var previousNonpoint : FBBezierCurve {
    var edge = self.previous
    while edge.isPoint {
      edge = edge.previous
    }
    return edge
  }

  // 178
  //- (BOOL) hasCrossings
  var hasCrossings : Bool {
    return !crossings.isEmpty
  }

  // 183
  //- (void) crossingsWithBlock:(void (^)(FBEdgeCrossing *crossing, BOOL *stop))block
  func crossingsWithBlock(block: (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool)) {
    for crossing in crossings {
      let (set, val) = block(crossing: crossing)
      if set && val {
        break
      }
    }
  }

  // 196
  //- (void) crossingsCopyWithBlock:(void (^)(FBEdgeCrossing *crossing, BOOL *stop))block
  // TODO: Check that this behaves the same as the original
  func crossingsCopyWithBlock(block: (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool)) {
    let crossingsCopy = crossings
    for crossing in crossingsCopy {
      let (set, val) = block(crossing: crossing)
      if set && val {
        break
      }
    }
  }

  // 210
  //- (FBEdgeCrossing *) nextCrossing:(FBEdgeCrossing *)crossing
  func nextCrossing(crossing: FBEdgeCrossing) -> FBEdgeCrossing? {
    if crossing.index < crossings.count - 1 {
      return crossings[crossing.index + 1]
    } else {
      return nil
    }
  }


  // 218
  //- (FBEdgeCrossing *) previousCrossing:(FBEdgeCrossing *)crossing
  func previousCrossing(crossing: FBEdgeCrossing) -> FBEdgeCrossing? {
    if crossing.index > 0 {
      return crossings[crossing.index - 1]
    } else {
      return nil
    }
  }

  // 226
  //- (void) intersectingEdgesWithBlock:(void (^)(FBBezierCurve *intersectingEdge))block
  func intersectingEdgesWithBlock(block: (intersectingEdge: FBBezierCurve) -> Void) {

    crossingsWithBlock() {
      (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in

      // Right now skip over self intersecting crossings
      if !crossing.isSelfCrossing {
        if let crossingCounterpartEdge = crossing.counterpart?.edge {
          block(intersectingEdge: crossingCounterpartEdge)
        }
      }
      return (false, false)
    }
  }


  // 236
  //- (void) selfIntersectingEdgesWithBlock:(void (^)(FBBezierCurve *intersectingEdge))block
  func selfIntersectingEdgesWithBlock(block: (intersectingEdge: FBBezierCurve) -> Void) {
    crossingsWithBlock() {
      (crossing: FBEdgeCrossing) -> (setStop: Bool, stopValue:Bool) in

      // Only want the self intersecting crossings
      if crossing.isSelfCrossing {
        if let crossingCounterpartEdge = crossing.counterpart?.edge {
          block(intersectingEdge: crossingCounterpartEdge)
        }
      }
      return (false, false)
    }
  }

  // 246
  //- (FBEdgeCrossing *) firstCrossing
  var firstCrossing : FBEdgeCrossing? {
    return crossings.first
  }

  // 253
  //- (FBEdgeCrossing *) lastCrossing
  var lastCrossing : FBEdgeCrossing? {
    return crossings.last
  }

  // 260
  //- (FBEdgeCrossing *) firstNonselfCrossing
  var firstNonselfCrossing : FBEdgeCrossing? {
    var first = firstCrossing
    while first != nil && first!.isSelfCrossing {
      first = first?.next
    }
    return first
  }


  // 268
  //- (FBEdgeCrossing *) lastNonselfCrossing
  var lastNonselfCrossing : FBEdgeCrossing? {
    var last = lastCrossing
    while last != nil && last!.isSelfCrossing {
      last = last?.previous
    }
    return last
  }

  // 276
  //- (BOOL) hasNonselfCrossings
  var hasNonselfCrossings : Bool {
    for crossing in crossings {
      if !crossing.isSelfCrossing {
        return true
      }
    }
    return false
  }


  // 288
  //- (BOOL) crossesEdge:(FBBezierCurve *)edge2 atIntersection:(FBBezierIntersection *)intersection
  func crossesEdge(edge2: FBBezierCurve, atIntersection intersection: FBBezierIntersection) -> Bool {
    // If it's tangent, then it doesn't cross
    if intersection.isTangent {
      return false
    }

    // If the intersect happens in the middle of both curves, then it
    // definitely crosses, so we can just return true.
    // Most intersections will fall into this category.
    if !intersection.isAtEndPointOfCurve {
      return true
    }

    // The intersection happens at the end of one of the edges, meaning we'll
    // have to look at the next edge in sequence to see if it crosses or not.
    // We'll do that by computing the four tangents at the exact point the
    // intersection takes place.
    // We'll compute the polar angle for each of the tangents.
    // If the angles of self split the angles of edge2 (i.e. they alternate when sorted),
    // then the edges cross.
    // If any of the angles are equal or if the angles group up,
    // then the edges don't cross.

    // Calculate the four tangents:
    //   The two tangents moving away from the intersection point on self and
    //   the two tangents moving away from the intersection point on edge2.
    var edge1Tangents = FBTangentPair(left: CGPoint.zero, right: CGPoint.zero)
    var edge2Tangents = FBTangentPair(left: CGPoint.zero, right: CGPoint.zero)
    var offset = 0.0

    let (edge1LeftCurve, edge1RightCurve) = FBFindEdge1TangentCurves(self, intersection: intersection)
    let edge1Length = min(edge1LeftCurve.length(), edge1RightCurve.length())

    let (edge2LeftCurve, edge2RightCurve) = FBFindEdge2TangentCurves(edge2, intersection: intersection)
    let edge2Length = min(edge2LeftCurve.length(), edge2RightCurve.length())

    let maxOffset = min(edge1Length, edge2Length)

    repeat {
      FBComputeEdgeTangents(edge1LeftCurve, rightCurve: edge1RightCurve, offset: offset, edgeTangents: &edge1Tangents)
      FBComputeEdgeTangents(edge2LeftCurve, rightCurve: edge2RightCurve, offset: offset, edgeTangents: &edge2Tangents)

      offset += 1.0
    } while FBAreTangentsAmbigious(edge1Tangents, edge2Tangents: edge2Tangents) && offset < maxOffset

    return FBTangentsCross(edge1Tangents, edge2Tangents: edge2Tangents)
  }

  // 332
  //- (BOOL) crossesEdge:(FBBezierCurve *)edge2 atIntersectRange:(FBBezierIntersectRange *)intersectRange
  func crossesEdge(edge2: FBBezierCurve, atIntersectRange intersectRange: FBBezierIntersectRange) -> Bool {
    // Calculate the four tangents:
    // The two tangents moving away from the intersection point on self, and
    // the two tangents moving away from the intersection point on edge2.
    var edge1Tangents = FBTangentPair(left: CGPoint.zero, right: CGPoint.zero)
    var edge2Tangents = FBTangentPair(left: CGPoint.zero, right: CGPoint.zero)
    var offset = 0.0

    let (edge1LeftCurve, edge1RightCurve) = FBComputeEdge1RangeTangentCurves(self, intersectRange: intersectRange)

    let edge1Length = min(edge1LeftCurve.length(), edge1RightCurve.length())

    let (edge2LeftCurve, edge2RightCurve) = FBComputeEdge2RangeTangentCurves(edge2, intersectRange: intersectRange)
    let edge2Length = min(edge2LeftCurve.length(), edge2RightCurve.length())

    let maxOffset = min(edge1Length, edge2Length);

    repeat {
      FBComputeEdgeTangents(edge1LeftCurve, rightCurve: edge1RightCurve, offset: offset, edgeTangents: &edge1Tangents)
      FBComputeEdgeTangents(edge2LeftCurve, rightCurve: edge2RightCurve, offset: offset, edgeTangents: &edge2Tangents)

      offset += 1.0
    } while FBAreTangentsAmbigious(edge1Tangents, edge2Tangents: edge2Tangents) && offset < maxOffset

    return FBTangentsCross(edge1Tangents, edge2Tangents: edge2Tangents);
  }


  // ===============================
  // MARK: Private funcs
  // ===============================


  // 374
  //- (void) sortCrossings
  private func sortCrossings() {

    // Sort by the "order" of the crossing and then
    // assign indices so next and previous work correctly.
    crossings.sortInPlace({ $0.order < $1.order })

    for (index, crossing) in crossings.enumerate() {
      crossing.index = index
    }
  }

}
