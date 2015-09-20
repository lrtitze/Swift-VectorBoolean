//
//  FBCurveLocation.swift
//  Swift VectorBoolean for iOS
//
//  Based on FBCurveLocation - Created by Andrew Finnell on 6/18/13.
//  Copyright (c) 2013 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-07-06.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import UIKit

class FBCurveLocation {

  var graph : FBBezierGraph?
  var contour : FBBezierContour?
  private var _edge : FBBezierCurve
  private var _parameter : Double
  private var _distance : Double

  init(edge: FBBezierCurve, parameter: Double, distance: Double) {
    _edge = edge
    _parameter = parameter
    _distance = distance
  }

  var edge : FBBezierCurve {
    return _edge
  }
  var parameter : Double {
    return _parameter
  }
  var distance : Double {
    return _distance
  }
}