//
//  CanvasView.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-12.
//  Copyright (c) 2015 Startside Softworks. All rights reserved.
//

import UIKit

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

  var showPoints: Bool = false
  var showIntersections: Bool = true

  func clear() {
    paths = []
  }

  func addPath(path: UIBezierPath, withColor color: UIColor) {
    paths.append(PathItem(path: path, color: color))
  }

  func BoxFrame(point: CGPoint) -> CGRect
  {
    return CGRect(x: floor(point.x - 2) - 0.5, y: floor(point.y - 2) - 0.5, width: 5, height: 5)
  }

  override func drawRect(rect: CGRect) {
    // fill with white before going further
    let background = UIBezierPath(rect: rect)
    UIColor.whiteColor().setFill()
    background.fill()

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

    for pathItem in paths {
      pathItem.color.setFill()
      pathItem.path.fill()
      pathItem.path.stroke()  // was not in original
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
            UIColor.greenColor().setStroke()
            UIBezierPath(ovalInRect: BoxFrame(v1)).stroke()
            UIBezierPath(ovalInRect: BoxFrame(v2)).stroke()

          case let .Close:
            previousPoint = CGPointZero
          }
          UIColor.orangeColor().setStroke()
          showMe?.stroke()
        }
      }
    }

    // All done
    CGContextRestoreGState(ctx)
  }

}
