//
//  TestShapes.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-12.
//  Copyright (c) 2015 Startside Softworks. All rights reserved.
//

import UIKit

protocol SampleShapeMaker {
  func topShape() -> UIBezierPath
  func otherShapes() -> UIBezierPath
}

class TestShape {
  var label : String
  private var _top : UIBezierPath?
  private var _other : UIBezierPath?

  var boundsOfPaths : CGRect {
    return CGRectUnion(top().bounds, other().bounds)
  }

  init(label:String) {
    self.label = label
  }

  func top() -> UIBezierPath {
    if let top = _top {
      return top
    } else {
      if let maker = self as? SampleShapeMaker {
        _top = maker.topShape()
      } else {
        _top = UIBezierPath()
      }
      return _top!
    }
  }

  func other() -> UIBezierPath {
    if let other = _other {
      return other
    } else {
      if let maker = self as? SampleShapeMaker {
        _other = maker.otherShapes()
      } else {
        _other = UIBezierPath()
      }
      return _other!
    }
  }
}

class TestShapeData {

  var count : Int {
    return shapes.count
  }
  let shapes : [TestShape] = [
    TestShape_Rectangle_Sharing_Edge_With_Rectangle(),
    TestShape_Rectangle_Overlapping_Rectangle(),
    TestShape_Tiny_Rectangle_Overlapping_Rectangle(),
    TestShape_Circle_Overlapping_Rectangle(),
    TestShape_Debug(),
    TestShape_Debug001(),
    TestShape_Debug002(),
    TestShape_Debug003(),
    TestShape_Circle_Overlapping_Rectangle(),     // 1
    TestShape_Circle_in_Rectangle(),              // 2
    TestShape_Rectangle_in_Circle(),              // 3
    TestShape_Circle_on_Rectangle(),              // 4
    TestShape_Rect_Over_Rect_w_Hole(),            // 5
    TestShape_Circle_Over_Two_Rects(),            // 6
    TestShape_Circle_Over_Circle(),               // 7
    TestShape_Complex_Shapes()                    // 8
  ]
}

// =================================================
// MARK: The set of bezier test case classes
// =================================================

class TestShape_Debug : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Debug")
  }

  func otherShapes() -> UIBezierPath {
    let rect1 = UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200))
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 150+125, y: 150+125), withRadius: 125, toPath: circle)

    let joinedU = rect1.fb_union(circle)
    //var joinedD = rect1.fb_difference(circle)
    //var joinedI = rect1.fb_intersect(circle)
    //var joinedX = rect1.fb_xor(circle)

    return joinedU
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
    //        var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
    return circle
  }
}

class TestShape_Debug001 : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Debug 001")
  }

  func otherShapes() -> UIBezierPath {
    let rect1 = UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200))
    let rect2 = UIBezierPath(rect: CGRect(x: 150, y: 150, width: 250, height: 250))

    let joinedU = rect1.fb_union(rect2)
    //var joinedD = rect1.fb_difference(rect2)
    //var joinedI = rect1.fb_intersect(rect2)
    //var joinedX = rect1.fb_xor(rect2)

    return joinedU
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
    //        var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
    return circle
  }
}

class TestShape_Debug002 : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Debug 002")
  }

  func otherShapes() -> UIBezierPath {

    let holeyRectangle = UIBezierPath()
    //holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
    holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200)))
    //addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
    //var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
    let circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
    //var allParts = holeyRectangle.fb_difference(circle)
    //var allParts = holeyRectangle.fb_union(circle)
    //var allParts = holeyRectangle.fb_intersect(circle)
    let allParts = holeyRectangle.fb_xor(circle)
    return allParts
    /*
    holeyRectangle.appendPath(circle)

    var rectangle = UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
    //var allParts = holeyRectangle.fb_union(rectangle)
    var allParts = holeyRectangle.fb_difference(rectangle)
    //var allParts = holeyRectangle.fb_intersect(rectangle)
    return holeyRectangle // allParts
    */
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
    //        var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
    return circle
  }
}

class TestShape_Debug003 : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Debug 003")
  }

  func otherShapes() -> UIBezierPath {
    let arc2 = UIBezierPath()
    arc2.moveToPoint(CGPoint(x: 0, y: 250))
    arc2.addCurveToPoint(
      CGPoint(x: 250, y: 0),
      controlPoint1: CGPoint(x: 138.071198, y: 250),
      controlPoint2: CGPoint(x: 250, y: 138.071198)
    )
    arc2.closePath()

    //let checkMe = LRTBezierPathWrapper(circle)

    return arc2
  }

  func topShape() -> UIBezierPath {
    let arc1 = UIBezierPath()
    arc1.moveToPoint(CGPoint(x: 250, y: 250))
    arc1.addCurveToPoint(
      CGPoint(x: 0, y: 0),
      controlPoint1: CGPoint(x: 250, y: 111.928802),
      controlPoint2: CGPoint(x: 138.071198, y: 0)
    )
    arc1.closePath()

    return arc1
  }
}

class TestShape_Circle_Overlapping_Rectangle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Circle Overlapping Rectangle")
  }

  func otherShapes() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 50, y: 50, width: 300, height: 200))
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 355, y: 240), withRadius: 125.0, toPath: circle)
    return circle
  }
}

class TestShape_Rectangle_Overlapping_Rectangle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Rectangle Overlapping Rectangle")
  }

  func otherShapes() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 50, y: 50, width: 300, height: 200))
  }

  func topShape() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 230, y: 115, width: 250, height: 250))
  }
}

class TestShape_Rectangle_Sharing_Edge_With_Rectangle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Shared Edge")
  }

  func otherShapes() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 0, y: 0, width: 10, height: 13))
  }

  func topShape() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 5, y: 0, width: 11, height: 8))
  }
}

class TestShape_Tiny_Rectangle_Overlapping_Rectangle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Tiny Rect Over Rect")
  }

  func otherShapes() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 50, y: 50, width: 30, height: 30))
  }

  func topShape() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 48, y: 48, width: 25, height: 25))
  }
}

class TestShape_Circle_in_Rectangle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Circle in Rectangle")
  }

  func otherShapes() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300))
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125.0, toPath: circle)
    return circle
  }
}

class TestShape_Rectangle_in_Circle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Rectangle in Circle")
  }

  func otherShapes() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 185.0, toPath: circle)
    return circle
  }

  func topShape() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 150, y: 150, width: 150, height: 150))
  }
}

class TestShape_Circle_on_Rectangle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Circle on Rectangle")
  }

  func otherShapes() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 15, y: 15, width: 370, height: 370))
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 200, y: 200), withRadius: 185, toPath: circle)
    return circle
  }
}

class TestShape_Rect_Over_Rect_w_Hole : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Rect Over Rect with Hole")
  }

  func otherShapes() -> UIBezierPath {
    let holeyRectangle = UIBezierPath()
    holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
    addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
    return holeyRectangle
  }

  func topShape() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
  }
}

class TestShape_Circle_Over_Two_Rects : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Circle Overlapping Two Rects")
  }

  func otherShapes() -> UIBezierPath {
    let rectangles = UIBezierPath()
    rectangles.appendPath(UIBezierPath(rect: CGRect(x:  50, y: 5, width: 100, height: 400)))
    rectangles.appendPath(UIBezierPath(rect: CGRect(x: 350, y: 5, width: 100, height: 400)))
    return rectangles
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 200, y: 200), withRadius: 185, toPath: circle)
    return circle
  }
}

class TestShape_Circle_Over_Circle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Circle Overlapping Circle")
  }

  func otherShapes() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 355, y: 240), withRadius: 125, toPath: circle)
    return circle
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 100, toPath: circle)
    return circle
  }
}

class TestShape_Complex_Shapes : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Complex Shapes")
  }

  func otherShapes() -> UIBezierPath {
    let holeyRectangle = UIBezierPath()
    holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
    addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)

    let rectangle = UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
    //let allParts = holeyRectangle.fb_intersect(rectangle)
    let allParts = holeyRectangle.fb_union(rectangle)

    return allParts
  }

  func topShape() -> UIBezierPath {
    let circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
    return circle
  }
}


/*
class TestShape_ : TestShape, SampleShapeMaker {

init() {
super.init(label: "AAAAAAAAAAAAAAAAAAA")
}

func otherShapes() -> UIBezierPath {
}

func topShape() -> UIBezierPath {
}
}
*/

/*
    TestShape(label: "More Complex Shapes"),
    TestShape(label: "Triangle Inside Rectangle"),
    TestShape(label: "Diamond Overlapping Rectangle"),
    TestShape(label: "Diamond Inside Rectangle"),
    TestShape(label: "Non-overlapping Contours"),
    TestShape(label: "More Non-overlapping Contours"),
    TestShape(label: "Concentric Contours"),
    TestShape(label: "More Concentric Contours"),
    TestShape(label: "Circle Overlapping Hole"),
    TestShape(label: "Rect w/Hole Overlapping Rect w/Hole"),
    TestShape(label: "Curve Overlapping Rectangle")
*/

func addCircleAtPoint(center: CGPoint, withRadius radius: CGFloat, toPath circle: UIBezierPath)
  {
    let FBMagicNumber: CGFloat = 0.55228475

    let controlPointLength = radius * FBMagicNumber
    circle.moveToPoint(CGPoint(x: center.x - radius, y: center.y))
    //[circle moveToPoint:NSMakePoint(center.x - radius, center.y)];

    circle.addCurveToPoint(
      CGPoint(x: center.x, y: center.y + radius),
      controlPoint1: CGPoint(x: center.x - radius, y: center.y + controlPointLength),
      controlPoint2: CGPoint(x: center.x - controlPointLength, y: center.y + radius)
    )
    //  [circle curveToPoint:NSMakePoint(center.x, center.y + radius) controlPoint1:NSMakePoint(center.x - radius, center.y + controlPointLength) controlPoint2:NSMakePoint(center.x - controlPointLength, center.y + radius)];

    circle.addCurveToPoint(
      CGPoint(x: center.x + radius, y: center.y),
      controlPoint1: CGPoint(x: center.x + controlPointLength, y: center.y + radius),
      controlPoint2: CGPoint(x: center.x + radius, y: center.y + controlPointLength)
    )
    //  [circle curveToPoint:NSMakePoint(center.x + radius, center.y) controlPoint1:NSMakePoint(center.x + controlPointLength, center.y + radius) controlPoint2:NSMakePoint(center.x + radius, center.y + controlPointLength)];

    circle.addCurveToPoint(
      CGPoint(x: center.x, y: center.y - radius),
      controlPoint1: CGPoint(x: center.x + radius, y: center.y - controlPointLength),
      controlPoint2: CGPoint(x: center.x + controlPointLength, y: center.y - radius)
    )
    //  [circle curveToPoint:NSMakePoint(center.x, center.y - radius) controlPoint1:NSMakePoint(center.x + radius, center.y - controlPointLength) controlPoint2:NSMakePoint(center.x + controlPointLength, center.y - radius)];

    circle.addCurveToPoint(
      CGPoint(x: center.x - radius, y: center.y),
      controlPoint1: CGPoint(x: center.x - controlPointLength, y: center.y - radius),
      controlPoint2: CGPoint(x: center.x - radius, y: center.y - controlPointLength)
    )
    //  [circle curveToPoint:NSMakePoint(center.x - radius, center.y) controlPoint1:NSMakePoint(x: center.x - controlPointLength, y: center.y - radius) controlPoint2:NSMakePoint(x: center.x - radius, y: center.y - controlPointLength)];
}

