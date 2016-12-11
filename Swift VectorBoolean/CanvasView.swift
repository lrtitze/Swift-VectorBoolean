//
//  CanvasView.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-12.
//  Copyright (c) 2015 Starside Softworks. All rights reserved.
//

import UIKit
import VectorBoolean

enum DisplayMode {
  case original
  case union
  case intersect
  case subtract
  case join
}

class PathItem {
  fileprivate var path: UIBezierPath
  fileprivate var color: UIColor

  init(path:UIBezierPath,color:UIColor) {
    self.path = path
    self.color = color
  }
}

class CanvasView: UIView {

  fileprivate var paths: [PathItem] = []
  var boundsOfPaths: CGRect = CGRect.zero

  fileprivate var _unionPath: UIBezierPath?
  fileprivate var _intersectPath: UIBezierPath?
  fileprivate var _differencePath: UIBezierPath?
  fileprivate var _xorPath: UIBezierPath?

  var displayMode: DisplayMode = .original {
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

  func addPath(_ path: UIBezierPath, withColor color: UIColor) {
    paths.append(PathItem(path: path, color: color))
    // we clear these because they're no longer valid
    _unionPath = nil
    _intersectPath = nil
    _differencePath = nil
    _xorPath = nil
  }

  fileprivate var viewScale = 1.0

  fileprivate var decorationLineWidth: CGFloat {
    return CGFloat(1.5 / viewScale)
  }

  func BoxFrame(_ point: CGPoint) -> CGRect
  {
    let visualWidth = CGFloat(9 / viewScale)
    let offset = visualWidth / 2
    let left = point.x - offset
    //let right = point.x + offset
    //let top = point.y + offset
    let bottom = point.y - offset
    return CGRect(x: left, y: bottom, width: visualWidth, height: visualWidth)
  }

  override func draw(_ rect: CGRect) {
    // fill with white before going further
    let background = UIBezierPath(rect: rect)
    UIColor.white.setFill()
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
    let expandedPathBounds = boundsOfPaths.insetBy(dx: -10, dy: -10)
    let pSz = expandedPathBounds.size
    let pOr = expandedPathBounds.origin
    let vSz = self.bounds.size

    let scaleX = vSz.width / pSz.width
    let scaleY = vSz.height / pSz.height

    let scale = min(scaleX, scaleY)
    viewScale = Double(scale)

    // obtain context
    let ctx = UIGraphicsGetCurrentContext()

    ctx?.saveGState();

    if scale == scaleX {
      let xTranslate = -(pOr.x * scale)
      let yTranslate = vSz.height - ((vSz.height-pSz.height*scale)/2.0) + (pOr.y*scale)
      ctx?.translateBy(x: xTranslate, y: yTranslate)
      ctx?.scaleBy(x: scale, y: -scale);
    } else {
      let xTranslate = ((vSz.width - pSz.width*scale)/2.0) - (pOr.x*scale)
      let yTranslate = vSz.height + (pOr.y * scale)
      ctx?.translateBy(x: xTranslate, y: yTranslate)
      ctx?.scaleBy(x: scale, y: -scale);
    }

    // Draw shapes now

    switch displayMode {

    case .original:
      drawOriginal()

    case .union:
      drawUnion()

    case .intersect:
      drawIntersect()

    case .subtract:
      drawSubtract()

    case .join:
      drawJoin()
    }

    // All done
    ctx?.restoreGState()
  }

  fileprivate func drawOriginal() {
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

        for item in bezier.elements {

          var showMe : UIBezierPath?

          switch item {

          case let .move(v):
            showMe = UIBezierPath(rect: BoxFrame(v))

          case let .line(v):
            // Convert lines to bezier curves as well.
            // Just set control point to be in the line formed by the end points
            showMe = UIBezierPath(rect: BoxFrame(v))

          case .quadCurve(let to, let cp):
            showMe = UIBezierPath(rect: BoxFrame(to))
            UIColor.black.setStroke()
            let cp1 = UIBezierPath(ovalIn: BoxFrame(cp))
            cp1.lineWidth = decorationLineWidth / 2
            cp1.stroke()
            break

          case .cubicCurve(let to, let v1, let v2):
            showMe = UIBezierPath(rect: BoxFrame(to))
            UIColor.black.setStroke()
            let cp1 = UIBezierPath(ovalIn: BoxFrame(v1))
            cp1.lineWidth = decorationLineWidth / 2
            cp1.stroke()
            let cp2 = UIBezierPath(ovalIn: BoxFrame(v2))
            cp2.lineWidth = decorationLineWidth / 2
            cp2.stroke()

          case .close:
            break
          }

          UIColor.red.setStroke()
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
      let curves1 = FBBezierCurve.bezierCurvesFromBezierPath(path1)
      let curves2 = FBBezierCurve.bezierCurvesFromBezierPath(path2)

      for curve1 in curves1 {
        for curve2 in curves2 {

          var unused: FBBezierIntersectRange?

          curve1.intersectionsWithBezierCurve(curve2, overlapRange: &unused) {

            (intersection: FBBezierIntersection) -> (setStop: Bool, stopValue:Bool) in

            if intersection.isTangent {
              UIColor.purple.setStroke()
            } else {
              UIColor.green.setStroke()
            }
            
            let inter = UIBezierPath(ovalIn: self.BoxFrame(intersection.location))
            inter.lineWidth = self.decorationLineWidth
            inter.stroke()
            
            return (false, false)
          }
        }
      }
    }
  }

  func drawEndPointsForPath(_ path: UIBezierPath) {
    let bezier = LRTBezierPathWrapper(path)

    //var previousPoint = CGPointZero

    for item in bezier.elements {

      var showMe : UIBezierPath?

      switch item {

      case let .move(v):
        showMe = UIBezierPath(rect: BoxFrame(v))

      case let .line(v):
        // Convert lines to bezier curves as well.
        // Just set control point to be in the line formed by the end points
        showMe = UIBezierPath(rect: BoxFrame(v))

      case .quadCurve(let to, let cp):
        showMe = UIBezierPath(rect: BoxFrame(to))
        UIColor.black.setStroke()
        let cp1 = UIBezierPath(ovalIn: BoxFrame(cp))
        cp1.lineWidth = decorationLineWidth / 2
        cp1.stroke()
        break

      case .cubicCurve(let to, let v1, let v2):
        showMe = UIBezierPath(rect: BoxFrame(to))
        UIColor.black.setStroke()
        let cp1 = UIBezierPath(ovalIn: BoxFrame(v1))
        cp1.lineWidth = decorationLineWidth / 2
        cp1.stroke()
        let cp2 = UIBezierPath(ovalIn: BoxFrame(v2))
        cp2.lineWidth = decorationLineWidth / 2
        cp2.stroke()

      case .close:
        break
        //previousPoint = CGPointZero
      }
      UIColor.red.setStroke()
      showMe?.lineWidth = decorationLineWidth
      showMe?.stroke()
    }
  }

  fileprivate func drawUnion() {
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

  fileprivate func drawIntersect() {
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

  fileprivate func drawSubtract() {
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

  fileprivate func drawJoin() {
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
