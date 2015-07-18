//
//  FBEdgeCrossing.swift
//  Swift VectorBoolean for iOS
//
//  Based on FBEdgeCrossing - Created by Andrew Finnell on 6/15/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-07-02.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import UIKit

/// FBEdgeCrossing is used by the boolean operations code to hold data about
/// where two edges actually cross (as opposed to just intersect).
///
/// The main piece of data is the intersection, but it also holds a pointer to the
/// crossing's counterpart in the other FBBezierGraph
class FBEdgeCrossing {

  private var _intersection: FBBezierIntersection

  var edge: FBBezierCurve?
  var counterpart: FBEdgeCrossing?
  var fromCrossingOverlap = false
  var entry = false
  var processed = false
  var selfCrossing = false
  var index: Int = 0

  //+ (id) crossingWithIntersection:(FBBezierIntersection *)intersection
  init(intersection: FBBezierIntersection) {
    _intersection = intersection
  }

  var isProcessed : Bool {
    return processed
  }

  var isSelfCrossing : Bool {
    return selfCrossing
  }

  var isEntry : Bool {
    return entry
  }

  //@synthesize edge=_edge;
  //@synthesize counterpart=_counterpart;
  //@synthesize entry=_entry;
  //@synthesize processed=_processed;
  //@synthesize selfCrossing=_selfCrossing;
  //@synthesize index=_index;
  //@synthesize fromCrossingOverlap=_fromCrossingOverlap;

  //@property (assign) FBBezierCurve *edge;
  //@property (assign) FBEdgeCrossing *counterpart;
  //@property (readonly) CGFloat order;
  //@property (getter = isEntry) BOOL entry;
  //@property (getter = isProcessed) BOOL processed;
  //@property (getter = isSelfCrossing) BOOL selfCrossing;
  //@property BOOL fromCrossingOverlap;
  //@property NSUInteger index;

  // An easy way to iterate crossings. It doesn't wrap when it reaches the end.
  //@property (readonly) FBEdgeCrossing *next;
  //@property (readonly) FBEdgeCrossing *previous;
  //@property (readonly) FBEdgeCrossing *nextNonself;
  //@property (readonly) FBEdgeCrossing *previousNonself;

  // These properties pass through to the underlying intersection
  //@property (readonly) CGFloat parameter;
  ///@property (readonly) FBBezierCurve *curve;
  //@property (readonly) FBBezierCurve *leftCurve;
  //@property (readonly) FBBezierCurve *rightCurve;
  //@property (readonly, getter = isAtStart) BOOL atStart;
  //@property (readonly, getter = isAtEnd) BOOL atEnd;
  //@property (readonly) NSPoint location;


  //- (void) removeFromEdge
  func removeFromEdge() {
    if let edge = edge {
      edge.removeCrossing(self)
    }
  }

  //- (CGFloat) order
  var order : CGFloat {
    return parameter
  }

  //- (FBEdgeCrossing *) next
  var next : FBEdgeCrossing? {
    if let edge = edge {
      return edge.nextCrossing(self)
    } else {
      return nil
    }
  }

  //- (FBEdgeCrossing *) previous
  var previous : FBEdgeCrossing? {
    if let edge = edge {
      return edge.previousCrossing(self)
    } else {
      return nil
    }
  }

  //- (FBEdgeCrossing *) nextNonself
  var nextNonself : FBEdgeCrossing? {
    var nextNon : FBEdgeCrossing? = next
    while nextNon != nil && nextNon!.isSelfCrossing {
      nextNon = nextNon!.next
    }
    return nextNon
  }

  //- (FBEdgeCrossing *) previousNonself
  var previousNonself : FBEdgeCrossing? {
    var prevNon : FBEdgeCrossing? = previous
    while prevNon != nil && prevNon!.isSelfCrossing {
      prevNon = prevNon!.previous
    }
    return prevNon
  }

  // MARK: Underlying Intersection Access
  // These properties pass through to the underlying intersection

  //- (CGFloat) parameter
  var parameter : CGFloat {
    // TODO: Is this actually working? Check equality operator here!
    if edge == _intersection.curve1 {
      return _intersection.parameter1
    } else {
      return _intersection.parameter2
    }
  }

  //- (NSPoint) location
  var location : CGPoint {
    return _intersection.location
  }

  //- (FBBezierCurve *) curve
  var curve : FBBezierCurve? {
    return edge
  }

  //- (FBBezierCurve *) leftCurve
  var leftCurve : FBBezierCurve? {
    if isAtStart {
      return nil
    }

    // TODO: Is this actually working? Check equality operator here!
    if edge == _intersection.curve1 {
      return _intersection.curve1LeftBezier
    } else {
      return _intersection.curve2LeftBezier
    }
  }

  //- (FBBezierCurve *) rightCurve
  var rightCurve : FBBezierCurve? {
    if isAtEnd {
      return nil
    }

    // TODO: Is this actually working? Check equality operator here!
    let equalityTest1 = edge == _intersection.curve1
    let equalityTest2 = edge === _intersection.curve1
    println("Equality 1: \(equalityTest1) vs Equality 2: \(equalityTest2)")

    if edge == _intersection.curve1 {
      return _intersection.curve1RightBezier
    } else {
      return _intersection.curve2RightBezier
    }
  }

  //- (BOOL) isAtStart
  var isAtStart : Bool {

    // TODO: Is this actually working? Check equality operator here!
    let equalityTest1 = edge == _intersection.curve1
    let equalityTest2 = edge === _intersection.curve1
    println("Equality 1: \(equalityTest1) vs Equality 2: \(equalityTest2)")

    if edge == _intersection.curve1 {
      return _intersection.isAtStartOfCurve1
    } else {
      return _intersection.isAtStartOfCurve2
    }
  }

  //- (BOOL) isAtEnd
  var isAtEnd : Bool {
    // TODO: Is this actually working? Check equality operator here!
    let equalityTest1 = edge == _intersection.curve1
    let equalityTest2 = edge === _intersection.curve1
    println("Equality 1: \(equalityTest1) vs Equality 2: \(equalityTest2)")

    if edge == _intersection.curve1 {
      return _intersection.isAtStopOfCurve1
    } else {
      return _intersection.isAtStopOfCurve2
    }
  }

}
