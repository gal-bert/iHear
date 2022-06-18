//
//  SettingsViewController+DataSource.swift
//  NYHM
//
//  Created by Rizki Faris on 15/06/22.
//

import Foundation
import UIKit

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: WaveformSwitchCell.identifier, for: indexPath) as! WaveformSwitchCell
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddNewTagCell.identifier, for: indexPath) as! AddNewTagCell
            return cell
        } else {
            let cell : TagTableCell = tableView.dequeueReusableCell(withIdentifier: "tagTableCellSB") as! TagTableCell
            return cell
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return CGFloat(110)
        } else if indexPath.section == 2 {
            return CGFloat(50)
        } else {
            
            let ctn = CGFloat(tagArr.count) * CGFloat(50)
            return ctn
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionName: String
        switch section {
            case 0:
                sectionName = ""
            case 1:
                sectionName = NSLocalizedString("MANAGE TAGS", comment: "MANAGE TAGS")
            // ...
            default:
                sectionName = ""
        }
        return sectionName
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.red
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.lightGray
    }
}
