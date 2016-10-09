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

private func myPathApply(_ path: CGPath!, block: MyPathApplier) {
  let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
    let block = unsafeBitCast(info, to: MyPathApplier.self)
    block(element)
  }

  path.apply(info: unsafeBitCast(block, to: UnsafeMutableRawPointer.self), function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
}

public enum PathElement {
  case move(to: CGPoint)
  case line(to: CGPoint)
  case quadCurve(to: CGPoint, via: CGPoint)
  case cubicCurve(to: CGPoint, v1: CGPoint, v2: CGPoint)
  case close
}

public extension CGPath {

  func apply(_ fn: (PathElement) -> Void) {
    myPathApply(self) { element in
      let points = element.pointee.points
      switch (element.pointee.type) {

      case CGPathElementType.moveToPoint:
        fn(.move(to: points[0]))

      case .addLineToPoint:
        fn(.line(to: points[0]))

      case .addQuadCurveToPoint:
        fn(.quadCurve(to: points[1], via: points[0]))

      case .addCurveToPoint:
        fn(.cubicCurve(to: points[2], v1: points[0], v2: points[1]))

      case .closeSubpath:
        fn(.close)
      }
    }
  }
}
