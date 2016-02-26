//
// CGPath.swift
//
// Written by Zachary Waldowski
// from: https://gist.github.com/zwaldowski/e6aa7f3f81303a688ad4
//
// Reworked for XCode 7 using info from Rob Mayoff found here: http://stackoverflow.com/a/26307538

import QuartzCore

typealias MyPathApplier = @convention(block) (UnsafePointer<CGPathElement>) -> Void
// Note: You must declare MyPathApplier as @convention(block), because
// if you don't, you get "fatal error: can't unsafeBitCast between
// types of different sizes" at runtime, on Mac OS X at least.

private func myPathApply(path: CGPath!, block: MyPathApplier) {
  let callback: @convention(c) (UnsafeMutablePointer<Void>, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
    let block = unsafeBitCast(info, MyPathApplier.self)
    block(element)
  }

  CGPathApply(path, unsafeBitCast(block, UnsafeMutablePointer<Void>.self), unsafeBitCast(callback, CGPathApplierFunction.self))
}

public extension CGPath {

  func apply(fn: Element -> Void) {
    myPathApply(self) { element in
      let points = element.memory.points
      switch (element.memory.type) {

      case CGPathElementType.MoveToPoint:
        fn(.Move(to: points[0]))

      case .AddLineToPoint:
        fn(.Line(to: points[0]))

      case .AddQuadCurveToPoint:
        fn(.QuadCurve(to: points[1], via: points[0]))

      case .AddCurveToPoint:
        fn(.CubicCurve(to: points[2], v1: points[0], v2: points[1]))

      case .CloseSubpath:
        fn(.Close)
      }
    }
  }
}
