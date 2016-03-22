//
//  OptionsViewController.swift
//  Swift VectorBoolean
//
//  Created by Leslie Titze on 2015-07-21.
//  Copyright (c) 2015 Starside Softworks. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {

  var primeVC : ViewController?

  @IBOutlet var controlPointsSwitch: UISwitch!
  @IBOutlet var intersectionsSwitch: UISwitch!

  override func viewWillAppear(animated: Bool) {
    let currentPreferredSize = self.preferredContentSize
    self.preferredContentSize = CGSize.zero
    let newSize = CGSize(width: currentPreferredSize.width, height: 300)
    self.preferredContentSize = newSize
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    //preferredContentSize = CGSize(width: 0, height: 400)

    if let primeVC = primeVC {
      controlPointsSwitch.on = primeVC.showEndpoints
      intersectionsSwitch.on = primeVC.showIntersections
    }

    let wantDoneButtonOnPhone = true
    // NOTE: The done button makes it easier to dismiss the controls.

    if wantDoneButtonOnPhone && UI_USER_INTERFACE_IDIOM() != .Pad {
      navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
        style: .Plain,
        target: self,
        action: "dismiss") // #selector(OptionsViewController.dismiss))
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  @IBAction func endpointsSwitchChanged(sender: UISwitch) {
    if let primeVC = primeVC {
      primeVC.showEndpoints = sender.on
    }
  }

  @IBAction func intersectionsSwitchChanged(sender: UISwitch) {
    if let primeVC = primeVC {
      primeVC.showIntersections = sender.on
    }
  }

  func dismiss() {
    dismissViewControllerAnimated(true) {
      self.primeVC?.popClosed()
    }
  }

  // MARK: - Navigation
  /*
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  */

}
