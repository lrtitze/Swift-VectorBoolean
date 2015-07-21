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

  var showEndpoints = false
  var showIntersections = true
  private var shapeData = TestShapeData()
  var currentShapesetIndex : Int = 0


  override func viewDidLoad() {
    super.viewDidLoad()

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
    loadCanvas()
    canvasView.setNeedsDisplay()
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

  @IBAction func doShapes(sender: AnyObject) {

//    if UI_USER_INTERFACE_IDIOM() == .Pad, let sender = sender as? UIBarButtonItem {
//      actionSheet.showFromBarButtonItem(sender, animated: true)
//    } else {
//      actionSheet.showInView(self.view)
//    }
//    actionSheet.tag = 200


  }

  @IBAction func doOptions(sender: AnyObject) {
    let endpointText : String
    if showEndpoints {
      endpointText = "Hide end/control points"
    } else {
      endpointText = "Show end/control points"
    }

    let intersectionText : String
    if showIntersections {
      intersectionText = "Hide intersections"
    } else {
      intersectionText = "Show intersections"
    }

    let alertController = UIAlertController(
      title: "Display Options",
      message: "Choose whether or not to view details related to the structure of the shapes and their intersections.",
      preferredStyle: .ActionSheet
    )

    let endpoints = UIAlertAction(
      title: endpointText,
      style: .Default,
      handler: { (action) -> Void in
        self.showEndpoints = !self.showEndpoints
        self.updateCanvas()
      }
    )

    let intersections = UIAlertAction(
      title: intersectionText,
      style: .Default,
      handler: { (action) -> Void in
        self.showIntersections = !self.showIntersections
        self.updateCanvas()
      }
    )

    alertController.addAction(endpoints)
    alertController.addAction(intersections)

    if let popoverController = alertController.popoverPresentationController, sender = sender as? UIBarButtonItem {
      popoverController.barButtonItem = sender
    }

    presentViewController(alertController, animated: true, completion: nil)
  }

  func loadCanvas() {
    canvasView.clear()
    canvasView.showPoints = self.showEndpoints
    canvasView.showIntersections = self.showIntersections
    // TODO: This will be only when currentMode == .Original
    loadCanvasWithOriginals()
  }

  func loadCanvasWithOriginals() {

    let current = shapeData.shapes[currentShapesetIndex]

    // We use a freshly generated version of the test shapes so
    // that there's no worry about them being modified beyond repair.
    canvasView.addPath(current.other(), withColor: UIColor.blueColor())
    canvasView.addPath(current.top(), withColor: UIColor.redColor())

    // Tell the canvas what the bounds are for use with
    // the "Original" form of these paths, rather than having
    // the scaling calculated when the displayed test shapes
    // have been modified by a boolean operation
    canvasView.boundsOfPaths = current.boundsOfPaths
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showShapeSelector" {
      if let destNav = segue.destinationViewController as? UINavigationController {
        if let popPC = destNav.popoverPresentationController {
          popPC.delegate = self
        }
        if let vc = destNav.topViewController as? ShapesTableViewController {
          vc.shapeData = self.shapeData
          vc.primeVC = self
          vc.currentSelection = currentShapesetIndex
        }
      }
    }
  }

  func adaptivePresentationStyleForPresentationController(controller: UIPresentationController!, traitCollection: UITraitCollection!) -> UIModalPresentationStyle {
    // Give the popover a PresentationStyle.None for iPhone
    return UIModalPresentationStyle.None //UIModalPresentationNone
  }

}

extension ViewController: UIPopoverPresentationControllerDelegate {

  func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
    let btnDone = UIBarButtonItem(title: "Done", style: .Done, target: self, action: "dismiss")
    let nav = UINavigationController(rootViewController: controller.presentedViewController)
    nav.topViewController.navigationItem.leftBarButtonItem = btnDone
    return nav
  }

}
