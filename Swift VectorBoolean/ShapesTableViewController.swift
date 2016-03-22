//
//  ShapesTableViewController.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-12.
//  Copyright (c) 2015 Starside Softworks. All rights reserved.
//

import UIKit

class ShapesTableViewController: UITableViewController {

  var shapeData : TestShapeData?
  var primeVC : ViewController?
  var currentSelection : Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    let wantCancelButtonOnPhone = true
    // NOTE: The cancel button makes it easier to dismiss the list.

    if wantCancelButtonOnPhone && UI_USER_INTERFACE_IDIOM() != .Pad {
      navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
        style: .Plain,
        target: self,
        action: "dismiss") // #selector(ShapesTableViewController.dismiss))
    }

    // Uncomment the following line to preserve selection between presentations
    self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
  }

  override func viewWillAppear(animated: Bool) {
    tableView.selectRowAtIndexPath(NSIndexPath(forItem: currentSelection, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.Middle)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  func dismiss() {
    dismissViewControllerAnimated(true) {
      self.primeVC?.popClosed()
    }
  }

  // MARK: - Table view data source

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return nil
  }

  override func tableView(_tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let shapeData = shapeData {
      return shapeData.count
    }
    return 19
  }

  override func tableView (_tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

    let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "testShapeCell")
    if let shapeData = shapeData {
      let testShape = shapeData.shapes[indexPath.row]
      cell.textLabel!.text = testShape.label
    } else {
      cell.textLabel!.text = "Broken \(indexPath.row)"
    }
    if indexPath.row == currentSelection {
      cell.accessoryType = UITableViewCellAccessoryType.Checkmark
    }
    return cell
  }

  // MARK: Table View Selection

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    if let primeVC = primeVC {
      primeVC.currentShapesetIndex = indexPath.row
      primeVC.updateCanvas()
    }

    dismiss()
  }

}
