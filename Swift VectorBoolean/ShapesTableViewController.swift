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

    if wantCancelButtonOnPhone && UI_USER_INTERFACE_IDIOM() != .pad {
      navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
        style: .plain,
        target: self,
        action: #selector(ShapesTableViewController.dismissVC))
    }

    // Uncomment the following line to preserve selection between presentations
    self.clearsSelectionOnViewWillAppear = false

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
  }

  override func viewWillAppear(_ animated: Bool) {
    tableView.selectRow(at: IndexPath(item: currentSelection, section: 0), animated: true, scrollPosition: UITableViewScrollPosition.middle)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  func dismissVC() {
    self.dismiss(animated: true) {
      self.primeVC?.popClosed()
    }
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ _tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return nil
  }

  override func tableView(_ _tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let shapeData = shapeData {
      return shapeData.count
    }
    return 19
  }

  override func tableView (_ _tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "testShapeCell")
    if let shapeData = shapeData {
      let testShape = shapeData.shapes[(indexPath as NSIndexPath).row]
      cell.textLabel!.text = testShape.label
    } else {
      cell.textLabel!.text = "Broken \((indexPath as NSIndexPath).row)"
    }
    if (indexPath as NSIndexPath).row == currentSelection {
      cell.accessoryType = UITableViewCellAccessoryType.checkmark
    }
    return cell
  }

  // MARK: Table View Selection

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    if let primeVC = primeVC {
      primeVC.currentShapesetIndex = (indexPath as NSIndexPath).row
      primeVC.updateCanvas()
    }

    dismissVC()
  }

}
