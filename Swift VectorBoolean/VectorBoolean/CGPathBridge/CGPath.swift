//
// CGPath.swift
//
// Written by Zachary Waldowski
// from: https://gist.github.com/zwaldowski/e6aa7f3f81303a688ad4

import QuartzCore

private func demunge(@noescape fn: CGPath.Element -> Void)(ptr: UnsafePointer<CGPathElement>) {
    let points = ptr.memory.points
    switch ptr.memory.type {
    case kCGPathElementMoveToPoint:
        fn(.Move(to: points[0]))
    case kCGPathElementAddLineToPoint:
        fn(.Line(to: points[0]))
    case kCGPathElementAddQuadCurveToPoint:
        fn(.QuadCurve(to: points[1], via: points[0]))
    case kCGPathElementAddCurveToPoint:
        fn(.CubicCurve(to: points[2], via: points[0], via: points[1]))
    case kCGPathElementCloseSubpath:
        fn(.Close)
    default: break
    }
}

private func ~=(lhs: CGPathElementType, rhs: CGPathElementType) -> Bool {
    return rhs.value == lhs.value
}

public extension CGPath {
    
    enum Element {
        case Move(to: CGPoint)
        case Line(to: CGPoint)
        case QuadCurve(to: CGPoint, via: CGPoint)
        case CubicCurve(to: CGPoint, via: CGPoint, via: CGPoint)
        case Close
    }
    
    @asmname("_CGPathApplyWithBlock") private func ApplyToPath(path: CGPath, @noescape block: @objc_block (UnsafePointer<CGPathElement>) -> Void)
    
    func apply(@noescape fn: Element -> Void) {
        ApplyToPath(self, block: demunge(fn))
    }
    
}
