//
//  ShapesTableViewController.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-12.
//  Copyright (c) 2015 Startside Softworks. All rights reserved.
//

import UIKit

class ShapesTableViewController: UITableViewController {

  var shapeData : TestShapeData?
  var primeVC : ViewController?
  var currentSelection : Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
      style: .Plain,
      target: self,
      action:"dismiss")

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
      println("Gone")
    }
  }

  func dismissAndUpdate() {
    dismissViewControllerAnimated(true) {}
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

    dismissAndUpdate()
  }

  /*

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
