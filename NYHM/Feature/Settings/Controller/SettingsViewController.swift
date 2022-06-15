//
//  SettingsViewController.swift
//  NYHM
//
//  Created by Hafizh Mo on 12/06/22.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet var settingsView: SettingsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsView.setup(viewController: self)
    }
}
