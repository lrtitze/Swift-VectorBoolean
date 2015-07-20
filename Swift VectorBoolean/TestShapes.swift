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
    println("Init with label \(label)")
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

  private func xtopShape() -> UIBezierPath {
    println("Be sure to override topShape")
    return UIBezierPath()
  }

  private func xotherShapes() -> UIBezierPath {
    println("Be sure to override otherShapes")
    return UIBezierPath()
  }
}

class TestShapeData {

  var count : Int {
    return shapes.count
  }
  let shapes : [TestShape] = [
    TestShape_Debug003(),
    TestShape_Rectangle_Overlapping_Rectangle(),
    TestShape_Circle_Overlapping_Rectangle(),
    TestShape_Debug(),
    TestShape_Debug001(),
    TestShape_Debug002(),
    TestShape_Circle_Overlapping_Rectangle(),
    TestShape_Circle_in_Rectangle(),
    TestShape_Rectangle_in_Circle(),
    TestShape_Circle_on_Rectangle()
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
    var rect1 = UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200))
    var circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 150+125, y: 150+125), withRadius: 125, toPath: circle)

    var joinedU = rect1.fb_union(circle)
    //var joinedD = rect1.fb_difference(circle)
    //var joinedI = rect1.fb_intersect(circle)
    //var joinedX = rect1.fb_xor(circle)

    return joinedU
  }

  func topShape() -> UIBezierPath {
    var circle = UIBezierPath()
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
    var rect1 = UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200))
    var rect2 = UIBezierPath(rect: CGRect(x: 150, y: 150, width: 250, height: 250))

    var joinedU = rect1.fb_union(rect2)
    //var joinedD = rect1.fb_difference(rect2)
    //var joinedI = rect1.fb_intersect(rect2)
    //var joinedX = rect1.fb_xor(rect2)

    return joinedU
  }

  func topShape() -> UIBezierPath {
    var circle = UIBezierPath()
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

    var holeyRectangle = UIBezierPath()
    //holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
    holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200)))
    //addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
    //var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
    var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
    //var allParts = holeyRectangle.fb_difference(circle)
    //var allParts = holeyRectangle.fb_union(circle)
    //var allParts = holeyRectangle.fb_intersect(circle)
    var allParts = holeyRectangle.fb_xor(circle)
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
    var circle = UIBezierPath()
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
    var arc2 = UIBezierPath()
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
    var arc1 = UIBezierPath()
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
    var circle = UIBezierPath()
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

class TestShape_Circle_in_Rectangle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Circle in Rectangle")
  }

  func otherShapes() -> UIBezierPath {
    return UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300))
  }

  func topShape() -> UIBezierPath {
    var circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125.0, toPath: circle)
    return circle
  }
}

class TestShape_Rectangle_in_Circle : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "Rectangle in Circle")
  }

  func otherShapes() -> UIBezierPath {
    var circle = UIBezierPath()
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
    var circle = UIBezierPath()
    addCircleAtPoint(CGPoint(x: 200, y: 200), withRadius: 185, toPath: circle)
    return circle
  }
}

/*
class TestShape_ : TestShape, SampleShapeMaker {

  init() {
    super.init(label: "AAAAAAAAAAAAAAAAAAA")
  }

  func otherShapes() -> UIBezierPath {
    println("TestShape - Debug002 - other")
  }

  func topShape() -> UIBezierPath {
    println("TestShape - Debug002 - top")
  }
}
*/

/*

    TestShape(
      label: "Rect Over Rect with Hole",
      // addHoleyRectangleWithRectangle
      //NSBezierPath *holeyRectangle = [NSBezierPath bezierPath];
      //[self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:holeyRectangle];
      //[self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:holeyRectangle];
      //[_view.canvas addPath:holeyRectangle withColor:[NSColor blueColor]];

      //NSBezierPath *rectangle = [NSBezierPath bezierPath];
      //[self addRectangle:NSMakeRect(180, 5, 100, 400) toPath:rectangle];
      //[_view.canvas addPath:rectangle withColor:[NSColor redColor]];

      other: {
        var holeyRectangle = UIBezierPath()
        holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
        addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
        return holeyRectangle
      },
      top: {
        return UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
      }
    ),

    TestShape(
      label: "Circle Overlapping Two Rects",
      // addCircleOnTwoRectangles
      //NSBezierPath *rectangles = [NSBezierPath bezierPath];
      //[self addRectangle:NSMakeRect(50, 5, 100, 400) toPath:rectangles];
      //[self addRectangle:NSMakeRect(350, 5, 100, 400) toPath:rectangles];
      //[_view.canvas addPath:rectangles withColor:[NSColor blueColor]];
      //
      //[self addCircleAtPoint:NSMakePoint(200, 200) withRadius:185];

      other: {
        var rectangles = UIBezierPath()
        rectangles.appendPath(UIBezierPath(rect: CGRect(x:  50, y: 5, width: 100, height: 400)))
        rectangles.appendPath(UIBezierPath(rect: CGRect(x: 350, y: 5, width: 100, height: 400)))
        return rectangles
      },
      top: {
        var circle = UIBezierPath()
        addCircleAtPoint(CGPoint(x: 200, y: 200), withRadius: 185, toPath: circle)
        return circle
      }
    ),

    TestShape(
      label: "Circle Overlapping Circle",
      // addCircleOverlappingCircle
      //NSBezierPath *circle = [NSBezierPath bezierPath];
      //[self addCircleAtPoint:NSMakePoint(355, 240) withRadius:125 toPath:circle];
      //[_view.canvas addPath:circle withColor:[NSColor blueColor]];
      //
      //[self addCircleAtPoint:NSMakePoint(210, 110) withRadius:100];

      other: {
        var circle = UIBezierPath()
        addCircleAtPoint(CGPoint(x: 355, y: 240), withRadius: 125, toPath: circle)
        return circle
      },
      top: {
        var circle = UIBezierPath()
        addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 100, toPath: circle)
        return circle
      }
    ),

    TestShape(
      label: "Complex Shapes",
      // addComplexShapes
      //NSBezierPath *holeyRectangle = [NSBezierPath bezierPath];
      //[self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:holeyRectangle];
      //[self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:holeyRectangle];
      //
      //NSBezierPath *rectangle = [NSBezierPath bezierPath];
      //[self addRectangle:NSMakeRect(180, 5, 100, 400) toPath:rectangle];
      //
      //NSBezierPath *allParts = [holeyRectangle fb_union:rectangle];
      //NSBezierPath *intersectingParts = [holeyRectangle fb_intersect:rectangle];
      //
      //[_view.canvas addPath:allParts withColor:[NSColor blueColor]];
      //[_view.canvas addPath:intersectingParts withColor:[NSColor redColor]];

      other: {
        var holeyRectangle = UIBezierPath()
        holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
        addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
        //var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
        //holeyRectangle.appendPath(circle)


        var rectangle = UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
        //var allParts = holeyRectangle.fb_union(rectangle)
        var allParts = holeyRectangle.fb_difference(rectangle)
        return allParts
      },
      top: {
        var circle = UIBezierPath()
        addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
//        var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
        return circle
      }
    ),


    TestShape(
      label: "Test Complex",
      // addComplexShapes
      //NSBezierPath *holeyRectangle = [NSBezierPath bezierPath];
      //[self addRectangle:NSMakeRect(50, 50, 350, 300) toPath:holeyRectangle];
      //[self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125 toPath:holeyRectangle];
      //
      //NSBezierPath *rectangle = [NSBezierPath bezierPath];
      //[self addRectangle:NSMakeRect(180, 5, 100, 400) toPath:rectangle];
      //
      //NSBezierPath *allParts = [holeyRectangle fb_union:rectangle];
      //NSBezierPath *intersectingParts = [holeyRectangle fb_intersect:rectangle];
      //
      //[_view.canvas addPath:allParts withColor:[NSColor blueColor]];
      //[_view.canvas addPath:intersectingParts withColor:[NSColor redColor]];

      other: {
        var holeyRectangle = UIBezierPath()
        holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
        addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)

        var rectangle = UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
        //var allParts = holeyRectangle.fb_union(rectangle)
        var allParts = holeyRectangle // holeyRectangle.fb_difference(rectangle)
        return allParts
      },
      top: {
        var rectangle = UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
        return rectangle
      }
    ),

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
  ]
  //  }
    //return _shapes!
  //}
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

