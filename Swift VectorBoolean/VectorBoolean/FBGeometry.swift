//
//  FBGeometry.swift
//  Swift VectorBoolean for iOS
//
//  Based on FBGeometry - Created by Andrew Finnell on 5/28/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-05-21.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import UIKit


// ===================================
// MARK: Point Helpers
// ===================================

// LRT - fiddle with these
//let FBPointClosenessThreshold   = CGFloat(1e-10)
//let FBTangentClosenessThreshold = CGFloat(1e-12)
//let FBBoundsClosenessThreshold  = CGFloat(1e-9)
let FBPointClosenessThreshold   = CGFloat(1e-7)
let FBTangentClosenessThreshold = CGFloat(1e-7)
let FBBoundsClosenessThreshold  = CGFloat(1e-5)



func FBDistanceBetweenPoints(point1: CGPoint, point2: CGPoint) -> CGFloat {

  let xDelta = point2.x - point1.x
  let yDelta = point2.y - point1.y

  return sqrt(xDelta * xDelta + yDelta * yDelta);
}

func FBDistancePointToLine(point: CGPoint, lineStartPoint: CGPoint, lineEndPoint: CGPoint) -> CGFloat {

  let lineLength = FBDistanceBetweenPoints(lineStartPoint, point2: lineEndPoint)
  if lineLength == 0 {
    return 0.0
  }

  let u = ((point.x - lineStartPoint.x) * (lineEndPoint.x - lineStartPoint.x) + (point.y - lineStartPoint.y) * (lineEndPoint.y - lineStartPoint.y)) / (lineLength * lineLength);

  let intersectionPoint = CGPointMake(lineStartPoint.x + u * (lineEndPoint.x - lineStartPoint.x), lineStartPoint.y + u * (lineEndPoint.y - lineStartPoint.y))

  return FBDistanceBetweenPoints(point, intersectionPoint)
}

func FBAddPoint(point1: CGPoint, point2: CGPoint) -> CGPoint {

  return CGPointMake(point1.x + point2.x, point1.y + point2.y)
}

func FBUnitScalePoint(point: CGPoint, scale: CGFloat) -> CGPoint {

  var result = point
  let length = FBPointLength(point)
  if length != 0.0 {
    result.x *= scale/length
    result.y *= scale/length
  }
  return result
}

func FBScalePoint(point: CGPoint, scale: CGFloat) -> CGPoint {

  return CGPointMake(point.x * scale, point.y * scale)
}

func FBDotMultiplyPoint(point1: CGPoint, point2: CGPoint) -> CGFloat {

  return point1.x * point2.x + point1.y * point2.y
}

func FBSubtractPoint(point1: CGPoint, point2: CGPoint) -> CGPoint {

  return CGPointMake(point1.x - point2.x, point1.y - point2.y)
}

func FBPointLength(point: CGPoint) -> CGFloat {

  return sqrt((point.x * point.x) + (point.y * point.y))
}

func FBPointSquaredLength(point: CGPoint) -> CGFloat {
  return (point.x * point.x) + (point.y * point.y)
}

func FBNormalizePoint(point: CGPoint) -> CGPoint {

  var result = point
  let length = FBPointLength(point)
  if length != 0.0 {
    result.x /= length
    result.y /= length
  }
  return result
}

func FBNegatePoint(point: CGPoint) -> CGPoint {

  return CGPointMake(-point.x, -point.y)
}

func FBRoundPoint(point: CGPoint) -> CGPoint {

  return CGPointMake(round(point.x), round(point.y))
}

func FBLineNormal(lineStart: CGPoint, lineEnd: CGPoint) -> CGPoint {

  return FBNormalizePoint(CGPointMake(-(lineEnd.y - lineStart.y), lineEnd.x - lineStart.x))
}

func FBLineMidpoint(lineStart: CGPoint, lineEnd: CGPoint) -> CGPoint {

  let distance = FBDistanceBetweenPoints(lineStart, point2: lineEnd)
  let tangent = FBNormalizePoint(FBSubtractPoint(lineEnd, point2: lineStart))
  return FBAddPoint(lineStart, FBUnitScalePoint(tangent, distance / 2.0))
}

func FBRectGetTopLeft(rect : CGRect) -> CGPoint {

  return CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))
}

func FBRectGetTopRight(rect : CGRect) -> CGPoint {

  return CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))
}

func FBRectGetBottomLeft(rect : CGRect) -> CGPoint {

  return CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))
}

func FBRectGetBottomRight(rect : CGRect) -> CGPoint {

  return CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))
}

func FBExpandBoundsByPoint(inout topLeft: CGPoint, inout bottomRight: CGPoint, point: CGPoint) {

  if point.x < topLeft.x     { topLeft.x = point.x }

  if point.x > bottomRight.x { bottomRight.x = point.x }

  if point.y < topLeft.y     { topLeft.y = point.y }

  if point.y > bottomRight.y { bottomRight.y = point.y }
}

func FBUnionRect(rect1: CGRect, rect2: CGRect) -> CGRect {

  var topLeft = FBRectGetTopLeft(rect1)
  var bottomRight = FBRectGetBottomRight(rect1)
  FBExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: FBRectGetTopLeft(rect2))
  FBExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: FBRectGetTopRight(rect2))
  FBExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: FBRectGetBottomRight(rect2))
  FBExpandBoundsByPoint(&topLeft, bottomRight: &bottomRight, point: FBRectGetBottomLeft(rect2))

  return CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
}


// ===================================
// MARK: -- Distance Helper methods --
// ===================================


func FBArePointsClose(point1: CGPoint, point2: CGPoint) -> Bool {

  return FBArePointsCloseWithOptions(point1, point2: point2, threshold: FBPointClosenessThreshold)
}

func FBArePointsCloseWithOptions(point1: CGPoint, point2: CGPoint, threshold: CGFloat) -> Bool {

  return FBAreValuesCloseWithOptions(point1.x, value2: point2.x, threshold: threshold) && FBAreValuesCloseWithOptions(point1.y, value2: point2.y, threshold: threshold);
}

func FBAreValuesClose(value1: CGFloat, value2: CGFloat) -> Bool {

  return FBAreValuesCloseWithOptions(value1, value2: value2, threshold: FBPointClosenessThreshold)
}

func FBAreValuesCloseWithOptions(value1: CGFloat, value2: CGFloat, threshold: CGFloat) -> Bool {

  let delta = value1 - value2
  return (delta <= threshold) && (delta >= -threshold)
}




// ===================================
// MARK: ---- Angle Helpers ----
// ===================================


//////////////////////////////////////////////////////////////////////////
// Helper methods for angles
//
let Two_π = CGFloat(2.0 * M_PI)
let π = CGFloat(M_PI)
let Half_π = CGFloat(M_PI_2)


// Normalize the angle between 0 and 2 π
func NormalizeAngle(var value: CGFloat) -> CGFloat {

  while value < 0.0 {  value = value + Two_π }
  while value >= Two_π { value = value - Two_π }

  return value
}

// Compute the polar angle from the cartesian point
func PolarAngle(point: CGPoint) -> CGFloat {

  var value = CGFloat(0.0)

  if point.x > 0.0 {
    value = atan(point.y / point.x)
  }
  else if point.x < 0.0 {
    if point.y >= 0.0 {
      value = atan(point.y / point.x) + π
    } else {
      value = atan(point.y / point.x) - π
    }
  } else {
    if point.y > 0.0 {
      value =  Half_π
    }
    else if point.y < 0.0 {
      value =  -Half_π
    }
    else {
      value = 0.0
    }
  }

  return NormalizeAngle(value)
}



// ===================================
// MARK: ---- Angle Range ----
// ===================================


//////////////////////////////////////////////////////////////////////////
// Angle Range structure provides a simple way to store angle ranges
//  and determine if a specific angle falls within.
//
struct FBAngleRange {
  var minimum : CGFloat
  var maximum : CGFloat
}


// NOTE: Should just use Swift:
//    var something = FBAngleRange(minimum: 12.0, maximum: 4.0)
//func FBAngleRangeMake(minimum: CGFloat, maximum: CGFloat) -> FBAngleRange {
//
//  return FBAngleRange(minimum: minimum, maximum: maximum)
//}


func FBIsValueGreaterThanWithOptions(value: CGFloat, minimum: CGFloat, threshold: CGFloat) -> Bool {

  if FBAreValuesCloseWithOptions(value, value2: minimum, threshold: threshold) {
    return false
  }

  return value > minimum
}

func FBIsValueGreaterThan(value: CGFloat, minimum: CGFloat) -> Bool {

  return FBIsValueGreaterThanWithOptions(value, minimum: minimum, threshold: FBTangentClosenessThreshold)
}

func FBIsValueLessThan(value: CGFloat, maximum: CGFloat) -> Bool {

  if FBAreValuesCloseWithOptions(value, value2: maximum, threshold: FBTangentClosenessThreshold) {
    return false
  }

  return value < maximum
}

func FBIsValueGreaterThanEqual(value: CGFloat, minimum: CGFloat) -> Bool {

  if FBAreValuesCloseWithOptions(value, value2: minimum, threshold: FBTangentClosenessThreshold) {
    return true
  }

  return value >= minimum
}

func FBIsValueLessThanEqualWithOptions(value: CGFloat, maximum: CGFloat, threshold: CGFloat) -> Bool {

  if FBAreValuesCloseWithOptions(value, value2: maximum, threshold: threshold) {
    return true
  }

  return value <= maximum
}

func FBIsValueLessThanEqual(value: CGFloat, maximum: CGFloat) -> Bool {

  return FBIsValueLessThanEqualWithOptions(value, maximum: maximum, threshold: FBTangentClosenessThreshold)
}


func FBAngleRangeContainsAngle(range: FBAngleRange, angle: CGFloat) -> Bool {

  if range.minimum <= range.maximum {
    return FBIsValueGreaterThan(angle, minimum: range.minimum) && FBIsValueLessThan(angle, maximum: range.maximum)
  }

  // The range wraps around 0. See if the angle falls in the first half
  if FBIsValueGreaterThan(angle, minimum: range.minimum) && angle <= Two_π {
    return true
  }

  return angle >= 0.0 && FBIsValueLessThan(angle, maximum: range.maximum)
}


// ===================================
// MARK: Parameter ranges
// ===================================


// FBRange is a range of parameter (t)
struct FBRange {
  var minimum : CGFloat
  var maximum : CGFloat
}

// NOTE: Should just use Swift:
//    var something = FBRange(minimum: 12.0, maximum: 4.0)
func FBRangeMake(minimum: CGFloat, maximum: CGFloat) -> FBRange {

  return FBRange(minimum: minimum, maximum: maximum)
}

func FBRangeHasConverged(range: FBRange, decimalPlaces: Int) -> Bool {

  let factor = pow(CGFloat(10.0), CGFloat(decimalPlaces))
  let minimum = Int(range.minimum * factor)
  let maxiumum = Int(range.maximum * factor)
  return minimum == maxiumum
}

func FBRangeGetSize(range: FBRange) -> CGFloat {

  return range.maximum - range.minimum
}

func FBRangeAverage(range: FBRange) -> CGFloat {

  return (range.minimum + range.maximum) / 2.0
}

func FBRangeScaleNormalizedValue(range: FBRange, value: CGFloat) -> CGFloat {

  return (range.maximum - range.minimum) * value + range.minimum
}

func FBRangeUnion(range1: FBRange, range2: FBRange) -> FBRange {

  return FBRange(minimum: min(range1.minimum, range2.minimum), maximum: max(range1.maximum, range2.maximum))
}


// ===================================
// MARK: Tangents
// ===================================


struct FBTangentPair {
  var left: CGPoint
  var right: CGPoint
}

func FBAreTangentsAmbigious(edge1Tangents: FBTangentPair, edge2Tangents: FBTangentPair) -> Bool {

  let normalEdge1 = FBTangentPair(left: FBNormalizePoint(edge1Tangents.left), right: FBNormalizePoint(edge1Tangents.right))
  let normalEdge2 = FBTangentPair(left: FBNormalizePoint(edge2Tangents.left), right: FBNormalizePoint(edge2Tangents.right))

  return FBArePointsCloseWithOptions(normalEdge1.left,  point2: normalEdge2.left,  threshold: FBTangentClosenessThreshold)
      || FBArePointsCloseWithOptions(normalEdge1.left,  point2: normalEdge2.right, threshold: FBTangentClosenessThreshold)
      || FBArePointsCloseWithOptions(normalEdge1.right, point2: normalEdge2.left,  threshold: FBTangentClosenessThreshold)
      || FBArePointsCloseWithOptions(normalEdge1.right, point2: normalEdge2.right, threshold: FBTangentClosenessThreshold)
}


struct FBAnglePair {
  var a: CGFloat
  var b: CGFloat
}

func FBTangentsCross(edge1Tangents: FBTangentPair, edge2Tangents: FBTangentPair) -> Bool {

  // Calculate angles for the tangents
  let edge1Angles = FBAnglePair(a: PolarAngle(edge1Tangents.left), b: PolarAngle(edge1Tangents.right))
  let edge2Angles = FBAnglePair(a: PolarAngle(edge2Tangents.left), b: PolarAngle(edge2Tangents.right))

  // Count how many times edge2 angles appear between the self angles
  let range1 = FBAngleRange(minimum: edge1Angles.a, maximum: edge1Angles.b)
  var rangeCount1 = 0

  if FBAngleRangeContainsAngle(range1, angle: edge2Angles.a) {
    rangeCount1++
  }

  if FBAngleRangeContainsAngle(range1, angle: edge2Angles.b) {
    rangeCount1++
  }

  // Count how many times self angles appear between the edge2 angles
  let range2 = FBAngleRange(minimum: edge1Angles.b, maximum: edge1Angles.a)
  var rangeCount2 = 0

  if FBAngleRangeContainsAngle(range2, angle: edge2Angles.a) {
    rangeCount2++
  }

  if FBAngleRangeContainsAngle(range2, angle: edge2Angles.b) {
    rangeCount2++
  }

  // If each pair of angles split the other two, then the edges cross.
  return rangeCount1 == 1 && rangeCount2 == 1
}


func FBLineBoundsMightOverlap(bounds1: CGRect, bounds2: CGRect) -> Bool
{
  let left = max(CGRectGetMinX(bounds1), CGRectGetMinX(bounds2))
  let right = min(CGRectGetMaxX(bounds1), CGRectGetMaxX(bounds2))

  if FBIsValueGreaterThanWithOptions(left, minimum: right, threshold: FBBoundsClosenessThreshold) {
    return false    // no horizontal overlap
  }

  let top = max(CGRectGetMinY(bounds1), CGRectGetMinY(bounds2))
  let bottom = min(CGRectGetMaxY(bounds1), CGRectGetMaxY(bounds2))
  return FBIsValueLessThanEqualWithOptions(top, maximum: bottom, threshold: FBBoundsClosenessThreshold)
}
