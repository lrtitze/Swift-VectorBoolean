//
//  FBBezierIntersection.swift
//  Swift VectorBoolean for iOS
//
//  Based on FBBezierIntersection - Created by Andrew Finnell on 6/6/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-06-29.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import UIKit

let FBPointCloseThreshold = isRunningOn64BitDevice ? 1e-7 : 1e-3
let FBParameterCloseThreshold = isRunningOn64BitDevice ? 1e-4 : 1e-2

/// FBBezierIntersection stores where two bezier curves intersect.
///
/// Initially it just stores the curves and the parameter values where they intersect.
///
/// It can lazily compute the 2D point where they intersect,
/// the left and right parts of the curves relative to
/// the intersection point, and whether the intersection is tangent.
class FBBezierIntersection {
  private var _location : CGPoint?
  private var _curve1: FBBezierCurve
  private var _parameter1: Double
  private var _curve1LeftBezier: FBBezierCurve?
  private var _curve1RightBezier: FBBezierCurve?
  private var _curve2: FBBezierCurve
  private var _parameter2: Double
  private var _curve2LeftBezier: FBBezierCurve?
  private var _curve2RightBezier: FBBezierCurve?
  private var _tangent: Bool = false
  private var needToComputeCurve1 = true
  private var needToComputeCurve2 = true

  var location : CGPoint {
    computeCurve1()
    return _location!
  }

  var curve1 : FBBezierCurve {
    return _curve1
  }

  var parameter1: Double {
    return _parameter1
  }

  var curve2 : FBBezierCurve {
    return _curve2
  }

  var parameter2: Double {
    return _parameter2
  }

  //+ (id) intersectionWithCurve1:(FBBezierCurve *)curve1 parameter1:(CGFloat)parameter1 curve2:(FBBezierCurve *)curve2 parameter2:(CGFloat)parameter2;
  //- (id) initWithCurve1:(FBBezierCurve *)curve1 parameter1:(CGFloat)parameter1 curve2:(FBBezierCurve *)curve2 parameter2:(CGFloat)parameter2;
  // let i = FBBezierIntersection(curve1: dvbc1, param1: p1, curve2: dvbc2, param2: p2)
  init(curve1: FBBezierCurve, param1: Double, curve2:FBBezierCurve, param2: Double) {
    _curve1 = curve1
    _parameter1 = param1
    _curve2 = curve2
    _parameter2 = param2
  }

  //- (BOOL) isTangent
  var isTangent : Bool {
    // If we're at the end of a curve, it's not tangent,
    // so skip all the calculations
    if isAtEndPointOfCurve {
      return false
    }

    computeCurve1()
    computeCurve2()

    // Compute the tangents at the intersection.
    let curve1LeftTangent = FBNormalizePoint(FBSubtractPoint(_curve1LeftBezier!.controlPoint2, point2: _curve1LeftBezier!.endPoint2))
    let curve1RightTangent = FBNormalizePoint(FBSubtractPoint(_curve1RightBezier!.controlPoint1, point2: _curve1RightBezier!.endPoint1))
    let curve2LeftTangent = FBNormalizePoint(FBSubtractPoint(_curve2LeftBezier!.controlPoint2, point2: _curve2LeftBezier!.endPoint2))
    let curve2RightTangent = FBNormalizePoint(FBSubtractPoint(_curve2RightBezier!.controlPoint1, point2: _curve2RightBezier!.endPoint1))

    // See if the tangents are the same. If so, then we're tangent at the intersection point
    return FBArePointsCloseWithOptions(curve1LeftTangent, point2: curve2LeftTangent, threshold: FBPointCloseThreshold)
      || FBArePointsCloseWithOptions(curve1LeftTangent, point2: curve2RightTangent, threshold: FBPointCloseThreshold)
      || FBArePointsCloseWithOptions(curve1RightTangent, point2: curve2LeftTangent, threshold: FBPointCloseThreshold)
      || FBArePointsCloseWithOptions(curve1RightTangent, point2: curve2RightTangent, threshold: FBPointCloseThreshold)
  }

  //- (FBBezierCurve *) curve1LeftBezier
  var curve1LeftBezier : FBBezierCurve {
    computeCurve1()
    return _curve1LeftBezier!
  }

  //- (FBBezierCurve *) curve1RightBezier
  var curve1RightBezier : FBBezierCurve {
    computeCurve1()
    return _curve1RightBezier!
  }

  //- (FBBezierCurve *) curve2LeftBezier
  var curve2LeftBezier : FBBezierCurve {
    computeCurve2()
    return _curve2LeftBezier!
  }

  //- (FBBezierCurve *) curve2RightBezier
  var curve2RightBezier : FBBezierCurve {
    computeCurve2()
    return _curve2RightBezier!
  }


  //- (BOOL) isAtStartOfCurve1
  var isAtStartOfCurve1 : Bool {
    return FBAreValuesCloseWithOptions(_parameter1, value2: 0.0, threshold: FBParameterCloseThreshold) || _curve1.isPoint
  }

  //- (BOOL) isAtStopOfCurve1
  var isAtStopOfCurve1 : Bool {
    return FBAreValuesCloseWithOptions(_parameter1, value2: 1.0, threshold: FBParameterCloseThreshold) || _curve1.isPoint
  }

  //- (BOOL) isAtEndPointOfCurve1
  var isAtEndPointOfCurve1 : Bool {
    return self.isAtStartOfCurve1 || self.isAtStopOfCurve1
  }


  //- (BOOL) isAtStartOfCurve2
  var isAtStartOfCurve2 : Bool {
    return FBAreValuesCloseWithOptions(_parameter2, value2: 0.0, threshold: FBParameterCloseThreshold) || _curve2.isPoint
  }

  //- (BOOL) isAtStopOfCurve2
  var isAtStopOfCurve2 : Bool {
    return FBAreValuesCloseWithOptions(_parameter2, value2: 1.0, threshold: FBParameterCloseThreshold) || _curve2.isPoint
  }

  //- (BOOL) isAtEndPointOfCurve2
  var isAtEndPointOfCurve2 : Bool {
    return self.isAtStartOfCurve2 || self.isAtStopOfCurve2
  }
  

  //- (BOOL) isAtEndPointOfCurve
  var isAtEndPointOfCurve : Bool {
    return self.isAtEndPointOfCurve1 || self.isAtEndPointOfCurve2
  }


  //- (void) computeCurve1
  private func computeCurve1()
  {
    if needToComputeCurve1 {
      let pap = _curve1.pointAtParameter(_parameter1)
      _location = pap.point
      _curve1LeftBezier = pap.leftBezierCurve
      _curve1RightBezier = pap.rightBezierCurve

      needToComputeCurve1 = false
    }
  }

  //- (void) computeCurve2
  private func computeCurve2()
  {
    if needToComputeCurve2 {
      let pap = _curve2.pointAtParameter(_parameter2)
      // not using the point from curve2
      _curve2LeftBezier = pap.leftBezierCurve
      _curve2RightBezier = pap.rightBezierCurve

      needToComputeCurve2 = false
    }
  }
}
