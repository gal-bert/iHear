//
//  SettingsViewController+Delegate.swift
//  NYHM
//
//  Created by Rizki Faris on 14/06/22.
//

import Foundation
import UIKit

extension SettingsViewController: UITableViewDelegate, AddNewDelegate {
    func reloadData() {
        tagArr = tagRepo.getAll()
        settingsView.tableView.reloadData()
        print("Delegate parent success!")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
