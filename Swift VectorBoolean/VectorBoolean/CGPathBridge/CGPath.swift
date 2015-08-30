//
// CGPath.swift
//
// Written by Zachary Waldowski
// from: https://gist.github.com/zwaldowski/e6aa7f3f81303a688ad4

import QuartzCore

private func demunge(@noescape fn: CGPath.Element -> Void)(ptr: UnsafePointer<CGPathElement>) {
    let points = ptr.memory.points
    switch ptr.memory.type {
    case CGPathElementType.MoveToPoint:
        fn(.Move(to: points[0]))
    case CGPathElementType.AddLineToPoint:
        fn(.Line(to: points[0]))
    case CGPathElementType.AddQuadCurveToPoint:
        fn(.QuadCurve(to: points[1], via: points[0]))
    case CGPathElementType.AddCurveToPoint:
        fn(.CubicCurve(to: points[2], v1: points[0], v2: points[1]))
    case CGPathElementType.CloseSubpath:
        fn(.Close)
    }
}

private func ~=(lhs: CGPathElementType, rhs: CGPathElementType) -> Bool {
    return rhs.rawValue == lhs.rawValue
}

public extension CGPath {
    
    enum Element {
        case Move(to: CGPoint)
        case Line(to: CGPoint)
        case QuadCurve(to: CGPoint, via: CGPoint)
        case CubicCurve(to: CGPoint, v1: CGPoint, v2: CGPoint)
        case Close
    }
    
    @asmname("_CGPathApplyWithBlock") private func ApplyToPath(path: CGPath, @noescape block: @convention(block) (UnsafePointer<CGPathElement>) -> Void)
    
    func apply(@noescape fn: Element -> Void) {
        ApplyToPath(self, block: demunge(fn))
    }
    
}
