//
//  TestShapes.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-12.
//  Copyright (c) 2015 Starside Softworks. All rights reserved.
//

import UIKit

class TestShape {
  var label : String
  var boundsOfPaths : CGRect
  var topShape: (() -> UIBezierPath)?
  var otherShapes: (() -> UIBezierPath)?

  init(label:String) {
    self.label = label
    println("Init with label \(label)")
    self.topShape = {
      return UIBezierPath()
    }
    self.otherShapes = {
      return UIBezierPath()
    }
    boundsOfPaths = CGRect.zeroRect
  }

  init(label:String, other: () -> UIBezierPath, top: () -> UIBezierPath) {
    println("Init with label \(label)")
    self.label = label
    self.topShape = top
    self.otherShapes = other
    boundsOfPaths = CGRectUnion(top().bounds, other().bounds)
  }
}

class TestShapeData {

  var count : Int {
    return shapes.count
  }
  let shapes : [TestShape] = [

    TestShape(
      label: "Debug",

      other: {
        println("TestShape - Debug - other")
        var rect1 = UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200))
        //var rect2 = UIBezierPath(rect: CGRect(x: 150, y: 150, width: 250, height: 200))
        var circle = UIBezierPath(ovalInRect: CGRect(x: 150, y: 150, width: 250, height: 250))

        var joinedU = rect1.fb_union(circle)
        //var joinedD = rect1.fb_difference(rect2)
        //var joinedI = rect1.fb_intersect(rect2)
        //var joinedX = rect1.fb_xor(rect2)

        return joinedU
      },

      top: {
        println("TestShape - Debug - top")
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
        //        var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
        return circle
      }
    ),

    TestShape(
      label: "Debug 002",

      other: {
        println("TestShape - Debug 002 - other")
        var holeyRectangle = UIBezierPath()
        //holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300)))
        holeyRectangle.appendPath(UIBezierPath(rect: CGRect(x: 50, y: 50, width: 250, height: 200)))
        //TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
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
      },
      top: {
        println("TestShape - Debug 002 - top")
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
        //        var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
        return circle
      }
    ),

    TestShape(
      label: "Circle Overlapping Rectangle",
      //[self addRectangle:NSMakeRect(50, 50, 300, 200)];
      //[self addCircleAtPoint:NSMakePoint(355, 240) withRadius:125];
      other: {
        return UIBezierPath(rect: CGRect(x: 50, y: 50, width: 300, height: 200))
      },
      top: {
        println("TestShape - Circle Overlapping Rect - other")
        //    [self addCircleAtPoint:NSMakePoint(355, 240) withRadius:125];
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 355, y: 240), withRadius: 125.0, toPath: circle)
        return circle
      }
    ),

    TestShape(
      label: "Circle in Rectangle",
      //[self addRectangle:NSMakeRect(50, 50, 350, 300)];
      //[self addCircleAtPoint:NSMakePoint(210, 200) withRadius:125];
      other: {
        return UIBezierPath(rect: CGRect(x: 50, y: 50, width: 350, height: 300))
      },
      top: {
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125.0, toPath: circle)
        return circle
      }
    ),

    TestShape(
      label: "Rectangle in Circle",
      //[self addRectangle:NSMakeRect(150, 150, 150, 150)];
      //[self addCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
      other: {
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 185.0, toPath: circle)
        return circle
      },
      top: {
        return UIBezierPath(rect: CGRect(x: 150, y: 150, width: 150, height: 150))
      }
    ),

    TestShape(
      label: "Circle on Rectangle",
      //[self addRectangle:NSMakeRect(15, 15, 370, 370)];
      //[self addCircleAtPoint:NSMakePoint(200, 200) withRadius:185];
      other: {
        return UIBezierPath(rect: CGRect(x: 15, y: 15, width: 370, height: 370))
      },
      top: {
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 200, y: 200), withRadius: 185, toPath: circle)
        return circle
      }
    ),

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
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
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
        TestShapeData.addCircleAtPoint(CGPoint(x: 200, y: 200), withRadius: 185, toPath: circle)
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
        TestShapeData.addCircleAtPoint(CGPoint(x: 355, y: 240), withRadius: 125, toPath: circle)
        return circle
      },
      top: {
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 100, toPath: circle)
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
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)
        //var circle = UIBezierPath(ovalInRect: CGRect(x: 210-125, y: 200-125, width: 250, height: 250))
        //holeyRectangle.appendPath(circle)


        var rectangle = UIBezierPath(rect: CGRect(x: 180, y: 5, width: 100, height: 400))
        //var allParts = holeyRectangle.fb_union(rectangle)
        var allParts = holeyRectangle.fb_difference(rectangle)
        return allParts
      },
      top: {
        var circle = UIBezierPath()
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 110), withRadius: 20, toPath: circle)
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
        TestShapeData.addCircleAtPoint(CGPoint(x: 210, y: 200), withRadius: 125, toPath: holeyRectangle)

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

  private static func addCircleAtPoint(center: CGPoint, withRadius radius: CGFloat, toPath circle: UIBezierPath)
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

}