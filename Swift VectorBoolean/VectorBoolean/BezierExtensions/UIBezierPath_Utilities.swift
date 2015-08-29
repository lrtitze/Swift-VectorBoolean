//
//  UIBezierPath_Utilities.swift
//  Swift VectorBoolean for iOS
//
//  Based on NSBezierPath+Boolean - Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-05-19.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import Foundation
import UIKit

struct UIBezierElement {
  var kind : CGPathElementType
  var point : CGPoint
  var controlPoints : [CGPoint]
//  var controlPoint1 : CGPoint?
//  var controlPoint2 : CGPoint?
}

let FBDebugPointSize = CGFloat(10.0)
let FBDebugSmallPointSize = CGFloat(3.0)


extension UIBezierPath {


  // 57
  //- (void) fb_copyAttributesFrom:(NSBezierPath *)path
  func fb_copyAttributesFrom(path: UIBezierPath) {
    self.lineWidth = path.lineWidth
    self.lineCapStyle = path.lineCapStyle
    self.lineJoinStyle = path.lineJoinStyle
    self.miterLimit = path.miterLimit
    self.flatness = path.flatness
  }

  // 103
  //+ (NSBezierPath *) circleAtPoint:(NSPoint)point
  static func circleAtPoint(point: CGPoint) -> UIBezierPath {

    let rect = CGRect(
      x: point.x - FBDebugPointSize * 0.5,
      y: point.y - FBDebugPointSize * 0.5,
      width: FBDebugPointSize,
      height: FBDebugPointSize);

    return UIBezierPath(ovalInRect: rect)
  }

  // 110
  //+ (NSBezierPath *) rectAtPoint:(NSPoint)point
  static func rectAtPoint(point: CGPoint) -> UIBezierPath {

    let rect = CGRect(
      x: point.x - FBDebugPointSize * 0.5,
      y: point.y - FBDebugPointSize * 0.5,
      width: FBDebugPointSize,
      height: FBDebugPointSize);

    return UIBezierPath(rect: rect)
  }

  // 117
  static func smallCircleAtPoint(point: CGPoint) -> UIBezierPath {

    let rect = CGRect(
      x: point.x - FBDebugSmallPointSize * 0.5,
      y: point.y - FBDebugSmallPointSize * 0.5,
      width: FBDebugSmallPointSize,
      height: FBDebugSmallPointSize);

    return UIBezierPath(ovalInRect: rect)
  }

  // 124
  //+ (NSBezierPath *) smallRectAtPoint:(NSPoint)point
  static func smallRectAtPoint(point: CGPoint) -> UIBezierPath {

    let rect = CGRect(
      x: point.x - FBDebugSmallPointSize * 0.5,
      y: point.y - FBDebugSmallPointSize * 0.5,
      width: FBDebugSmallPointSize,
      height: FBDebugSmallPointSize);

    return UIBezierPath(rect: rect)
  }

  // 131
  //+ (NSBezierPath *) triangleAtPoint:(NSPoint)point direction:(NSPoint)tangent
  static func triangleAtPoint(point: CGPoint, direction tangent: CGPoint) -> UIBezierPath {

    let endPoint = FBAddPoint(point, point2: FBScalePoint(tangent, scale: FBDebugPointSize * 1.5))
    let normal1 = FBLineNormal(point, endPoint)
    let normal2 = CGPoint(x: -normal1.x, y: -normal1.y)
    let basePoint1 = FBAddPoint(point, FBScalePoint(normal1, FBDebugPointSize * 0.5))
    let basePoint2 = FBAddPoint(point, FBScalePoint(normal2, FBDebugPointSize * 0.5))
    let path = UIBezierPath()
    path.moveToPoint(basePoint1)
    path.addLineToPoint(endPoint)
    path.addLineToPoint(basePoint2)
    path.addLineToPoint(basePoint1)
    path.closePath()

    return path
  }


}
