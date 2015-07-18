//
//  UIBezierPath_Boolean.swift
//  Swift VectorBoolean for iOS
//
//  Based on NSBezierPath+Boolean - Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-05-19.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.

import UIKit

extension UIBezierPath {

  // 15
  //- (NSBezierPath *) fb_union:(NSBezierPath *)path
  func fb_union(path: UIBezierPath) -> UIBezierPath {
    var thisGraph = FBBezierGraph(path: self)
    var otherGraph = FBBezierGraph(path: path)
    var resultGraph = thisGraph.unionWithBezierGraph(otherGraph)
    var result = resultGraph.bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

  // 24
  //- (NSBezierPath *) fb_intersect:(NSBezierPath *)path
  func fb_intersect(path: UIBezierPath) -> UIBezierPath {
    var thisGraph = FBBezierGraph(path: self)
    var otherGraph = FBBezierGraph(path: path)
    var result = thisGraph.intersectWithBezierGraph(otherGraph).bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

  // 33
  //- (NSBezierPath *) fb_difference:(NSBezierPath *)path
  func fb_difference(path: UIBezierPath) -> UIBezierPath {
    var thisGraph = FBBezierGraph(path: self)
    var otherGraph = FBBezierGraph(path: path)
    var result = thisGraph.differenceWithBezierGraph(otherGraph).bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

  // 42
  //- (NSBezierPath *) fb_xor:(NSBezierPath *)path
  func fb_xor(path: UIBezierPath) -> UIBezierPath {
    var thisGraph = FBBezierGraph(path: self)
    var otherGraph = FBBezierGraph(path: path)
    var result = thisGraph.xorWithBezierGraph(otherGraph).bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

}