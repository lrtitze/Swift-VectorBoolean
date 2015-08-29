//
//  ViewController.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-07.
//  Copyright (c) 2015 Startside Softworks. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate {

  @IBOutlet var canvasView: CanvasView!
  @IBOutlet var operationLabel: UILabel!

  @IBOutlet var shapesButton: UIBarButtonItem!
  @IBOutlet var optionsButton: UIBarButtonItem!

  @IBOutlet var segmentedControl: UISegmentedControl!

  var blankDisplay = false

  var showEndpoints = false {
    didSet(previousEndpoints) {
      if showEndpoints != previousEndpoints {
        canvasView.showPoints = showEndpoints
        canvasView.setNeedsDisplay()
      }
    }
  }

  var showIntersections = true {
    didSet(previousIntersections) {
      if showIntersections != previousIntersections {
        canvasView.showIntersections = showIntersections
        canvasView.setNeedsDisplay()
      }
    }
  }
  private var shapeData = TestShapeData()
  var currentShapesetIndex : Int = 0


  override func viewDidLoad() {
    super.viewDidLoad()

    // CREDIT: This concept comes from Matt Neuburg's
    // Stack Overflow answer: http://stackoverflow.com/a/24344459
    let envDict = NSProcessInfo.processInfo().environment
    if envDict["TESTING"] != nil {
      self.blankDisplay = true
    }

    loadCanvas()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    canvasView.setNeedsDisplay()
  }

  func updateCanvas() {
    canvasView.clear()
    operationLabel.text = "Original"
    canvasView.displayMode = .Original
    segmentedControl.selectedSegmentIndex = 0
    loadCanvas()
    canvasView.setNeedsDisplay()
  }

  func popClosed() {
    shapesButton.enabled = true
    optionsButton.enabled = true
  }

  @IBAction func modeSelect(sender: UISegmentedControl) {
    switch segmentedControl.selectedSegmentIndex {
    case 0:
      self.operationLabel.text = "Original"
      canvasView.displayMode = .Original
    case 1:
      self.operationLabel.text = "Union"
      canvasView.displayMode = .Union
    case 2:
      self.operationLabel.text = "Intersect"
      canvasView.displayMode = .Intersect
    case 3:
      self.operationLabel.text = "Subtract"
      canvasView.displayMode = .Subtract
    case 4:
      self.operationLabel.text = "Join"
      canvasView.displayMode = .Join
    default:
      self.operationLabel.text = "Unknown"
    }
  }


  func loadCanvas() {
    canvasView.clear()
    canvasView.showPoints = self.showEndpoints
    canvasView.showIntersections = self.showIntersections
    // TODO: This will be only when currentMode == .Original

    if !blankDisplay {
      loadCanvasWithOriginals()
    }
  }

  func loadCanvasWithOriginals() {

    let current = shapeData.shapes[currentShapesetIndex]

    // a pair of colors that works well with the UI
    //let lowShade = UIColor(hue:0.5869, saturation:1, brightness:1, alpha:1)
    let lowShade = UIColor(hue:0.5869, saturation:0.9, brightness:1, alpha:1)
    //let topShade = UIColor(hue:0.0232, saturation:0.902, brightness:1, alpha:1)
    let topShade = UIColor(hue:0.0232, saturation:0.62, brightness:1, alpha:1)

    // We use a freshly generated version of the test shapes so
    // that there's no worry about them being modified beyond repair.
    canvasView.addPath(current.other(), withColor: lowShade)
    canvasView.addPath(current.top(), withColor: topShade)

    // Tell the canvas what the bounds are for use with
    // the "Original" form of these paths, rather than having
    // the scaling calculated when the displayed test shapes
    // have been modified by a boolean operation
    canvasView.boundsOfPaths = current.boundsOfPaths
  }

  override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
    if identifier == "showShapeSelector" {
      return true
    } else if identifier == "showOptions" {
      return true
    }
    return true
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showShapeSelector" {
      if let destNav = segue.destinationViewController as? UINavigationController {
        if let popPC = destNav.popoverPresentationController {
          popPC.passthroughViews = nil
          popPC.delegate = self
          optionsButton.enabled = false
        }
        if let vc = destNav.topViewController as? ShapesTableViewController {
          vc.shapeData = self.shapeData
          vc.primeVC = self
          vc.currentSelection = currentShapesetIndex
        }
      }
    } else if segue.identifier == "showOptions" {
      if let destNav = segue.destinationViewController as? UINavigationController {
        if let popPC = destNav.popoverPresentationController {
          popPC.passthroughViews = nil
          popPC.delegate = self
          shapesButton.enabled = false
        }
        if let vc = destNav.topViewController as? OptionsViewController {
          vc.primeVC = self
        }
      }
    }
  }

  func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    // Give the popover a PresentationStyle.None for iPhone
    return UIModalPresentationStyle.None
  }

}

extension ViewController: UIPopoverPresentationControllerDelegate {

  func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
    popClosed()
  }

  func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {

    let nav = UINavigationController(rootViewController: controller.presentedViewController)
    return nav
  }

}
