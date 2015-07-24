//
//  CanvasView.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-12.
//  Copyright (c) 2015 Startside Softworks. All rights reserved.
//

import UIKit

enum DisplayMode {
  case Original
  case Union
  case Intersect
  case Subtract
  case Join
}

class PathItem {
  private var path: UIBezierPath
  private var color: UIColor

  init(path:UIBezierPath,color:UIColor) {
    self.path = path
    self.color = color
  }
}

class CanvasView: UIView {

  private var paths: [PathItem] = []
  var boundsOfPaths: CGRect = CGRect.zeroRect

  private var _unionPath: UIBezierPath?
  private var _intersectPath: UIBezierPath?
  private var _differencePath: UIBezierPath?
  private var _xorPath: UIBezierPath?

  var displayMode: DisplayMode = .Original {
    didSet(previousMode) {
      if displayMode != previousMode {
        setNeedsDisplay()
      }
    }
  }

  var showPoints: Bool = false
  var showIntersections: Bool = true

  let vectorFillColor = UIColor(red: 0.4314, green:0.6784, blue:1.0000, alpha:1.0)
  let vectorStrokeColor = UIColor(red: 0.0392, green:0.3725, blue:1.0000, alpha:1.0)

  func clear() {
    paths = []
    _unionPath = nil
    _intersectPath = nil
    _differencePath = nil
    _xorPath = nil
  }

  func addPath(path: UIBezierPath, withColor color: UIColor) {
    paths.append(PathItem(path: path, color: color))
    // we clear these because they're no longer valid
    _unionPath = nil
    _intersectPath = nil
    _differencePath = nil
    _xorPath = nil
  }

  private var viewScale = 1.0

  private var decorationLineWidth: CGFloat {
    return CGFloat(1.5 / viewScale)
  }

  func BoxFrame(point: CGPoint) -> CGRect
  {
    let visualWidth = CGFloat(9 / viewScale)
    let offset = visualWidth / 2
    let left = point.x - offset
    let right = point.x + offset
    let top = point.y + offset
    let bottom = point.y - offset
    return CGRect(x: left, y: bottom, width: visualWidth, height: visualWidth)
  }

  override func drawRect(rect: CGRect) {
    // fill with white before going further
    let background = UIBezierPath(rect: rect)
    UIColor.whiteColor().setFill()
    background.fill()

    // When running my Xcode tests for geometry I want to
    // prevent the app shell from any geometry so I can
    // use breakpoints during test development.
    if paths.count == 0 {
      return
    }

    // calculate a useful scale and offset for drawing these paths
    // as large as possible in the middle of the display
    // expand size by 20 to provide a margin
    var expandedPathBounds = CGRectInset(boundsOfPaths, -10, -10)
    let pSz = expandedPathBounds.size
    let pOr = expandedPathBounds.origin
    var vSz = self.bounds.size

    let scaleX = vSz.width / pSz.width
    let scaleY = vSz.height / pSz.height

    let scale = min(scaleX, scaleY)
    viewScale = Double(scale)

    // obtain context
    let ctx = UIGraphicsGetCurrentContext()

    CGContextSaveGState(ctx);

    if scale == scaleX {
      let xTranslate = -(pOr.x * scale)
      let yTranslate = vSz.height - ((vSz.height-pSz.height*scale)/2.0) + (pOr.y*scale)
      CGContextTranslateCTM(ctx, xTranslate, yTranslate)
      CGContextScaleCTM(ctx, scale, -scale);
    } else {
      let xTranslate = ((vSz.width - pSz.width*scale)/2.0) - (pOr.x*scale)
      let yTranslate = vSz.height + (pOr.y * scale)
      CGContextTranslateCTM(ctx, xTranslate, yTranslate)
      CGContextScaleCTM(ctx, scale, -scale);
    }

    // Draw shapes now

    switch displayMode {

    case .Original:
      drawOriginal()

    case .Union:
      drawUnion()

    case .Intersect:
      drawIntersect()

    case .Subtract:
      drawSubtract()

    case .Join:
      drawJoin()
    }

    // All done
    CGContextRestoreGState(ctx)
  }

  private func drawOriginal() {
    // Draw shapes now

    for pathItem in paths {
      pathItem.color.setFill()
      pathItem.path.fill()
      pathItem.path.lineWidth = decorationLineWidth
      //pathItem.path.stroke()  // was not in original
    }

    // Draw on the end and control points
    if showPoints {
      for pathItem in paths {
        let bezier = LRTBezierPathWrapper(pathItem.path)

        var previousPoint = CGPointZero

        for item in bezier.elements {

          var showMe : UIBezierPath?

          switch item {

          case let .Move(v):
            showMe = UIBezierPath(rect: BoxFrame(v))

          case let .Line(v):
            // Convert lines to bezier curves as well.
            // Just set control point to be in the line formed by the end points
            showMe = UIBezierPath(rect: BoxFrame(v))

          case .QuadCurve(let to, let via):
            previousPoint = to

          case .CubicCurve(let to, let v1, let v2):
            showMe = UIBezierPath(rect: BoxFrame(to))
            UIColor.blackColor().setStroke()
            let cp1 = UIBezierPath(ovalInRect: BoxFrame(v1))
            cp1.lineWidth = decorationLineWidth / 2
            cp1.stroke()
            let cp2 = UIBezierPath(ovalInRect: BoxFrame(v2))
            cp2.lineWidth = decorationLineWidth / 2
            cp2.stroke()

          case let .Close:
            previousPoint = CGPointZero
          }
          UIColor.redColor().setStroke()
          showMe?.lineWidth = decorationLineWidth
          showMe?.stroke()
        }
      }
    }


    // If we have exactly two objects, show where they intersect
    if showIntersections && paths.count == 2 {

      let path1 = paths[0].path
      let path2 = paths[1].path
      // get both [FBBezierCurve] sets
      var curves1 = FBBezierCurve.bezierCurvesFromBezierPath(path1)
      var curves2 = FBBezierCurve.bezierCurvesFromBezierPath(path2)

      for curve1 in curves1 {
        for curve2 in curves2 {

          var unused: FBBezierIntersectRange?

          curve1.intersectionsWithBezierCurve(curve2, overlapRange: &unused) {

            (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

            if intersection.isTangent {
              UIColor.purpleColor().setStroke()
            } else {
              UIColor.greenColor().setStroke()
            }
            
            let inter = UIBezierPath(ovalInRect: self.BoxFrame(intersection.location))
            inter.lineWidth = self.decorationLineWidth
            inter.stroke()
            
            return (false, false)
          }
        }
      }
    }
  }

  func drawEndPointsForPath(path: UIBezierPath) {
    let bezier = LRTBezierPathWrapper(path)

    var previousPoint = CGPointZero

    for item in bezier.elements {

      var showMe : UIBezierPath?

      switch item {

      case let .Move(v):
        showMe = UIBezierPath(rect: BoxFrame(v))

      case let .Line(v):
        // Convert lines to bezier curves as well.
        // Just set control point to be in the line formed by the end points
        showMe = UIBezierPath(rect: BoxFrame(v))

      case .QuadCurve(let to, let via):
        previousPoint = to

      case .CubicCurve(let to, let v1, let v2):
        showMe = UIBezierPath(rect: BoxFrame(to))
        UIColor.blackColor().setStroke()
        let cp1 = UIBezierPath(ovalInRect: BoxFrame(v1))
        cp1.lineWidth = decorationLineWidth / 2
        cp1.stroke()
        let cp2 = UIBezierPath(ovalInRect: BoxFrame(v2))
        cp2.lineWidth = decorationLineWidth / 2
        cp2.stroke()

      case let .Close:
        previousPoint = CGPointZero
      }
      UIColor.redColor().setStroke()
      showMe?.lineWidth = decorationLineWidth
      showMe?.stroke()
    }
  }

  private func drawUnion() {
    if _unionPath == nil {
      if paths.count == 2 {
        _unionPath = paths[0].path.fb_union(paths[1].path)
      }
    }
    if let path = _unionPath {
      vectorFillColor.setFill()
      vectorStrokeColor.setStroke()
      path.fill()
      path.lineWidth = decorationLineWidth
      path.stroke()
      if showPoints {
        drawEndPointsForPath(path)
      }
    }
  }

  private func drawIntersect() {
    if _intersectPath == nil {
      if paths.count == 2 {
        _intersectPath = paths[0].path.fb_intersect(paths[1].path)
      }
    }
    if let path = _intersectPath {
      vectorFillColor.setFill()
      vectorStrokeColor.setStroke()
      path.fill()
      path.lineWidth = decorationLineWidth
      path.stroke()
      if showPoints {
        drawEndPointsForPath(path)
      }
    }
  }

  private func drawSubtract() {
    if _differencePath == nil {
      if paths.count == 2 {
        _differencePath = paths[0].path.fb_difference(paths[1].path)
      }
    }
    if let path = _differencePath {
      vectorFillColor.setFill()
      vectorStrokeColor.setStroke()
      path.fill()
      path.lineWidth = decorationLineWidth
      path.stroke()
      if showPoints {
        drawEndPointsForPath(path)
      }
    }
  }

  private func drawJoin() {
    if _xorPath == nil {
      if paths.count == 2 {
        _xorPath = paths[0].path.fb_xor(paths[1].path)
      }
    }
    if let path = _xorPath {
      vectorFillColor.setFill()
      vectorStrokeColor.setStroke()
      path.fill()
      path.lineWidth = decorationLineWidth
      path.stroke()
      if showPoints {
        drawEndPointsForPath(path)
      }
    }
  }
}
