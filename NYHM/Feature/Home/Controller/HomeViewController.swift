//
//  HomeViewController.swift
//  NYHM
//
//  Created by Hafizh Mo on 12/06/22.
//

import Foundation
import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var homeView: HomeView!
    
    let repo = TranscriptionRepository.shared
    var transcriptions = [Transcriptions]()
    var filteredTranscriptions = [Transcriptions]()
    var currentSort = SortType.timeDesc
    
    let searchController = UISearchController()
    var searchBarIsEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !searchBarIsEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transcriptions = repo.showAll()
        homeView.setup(viewController: self)
        
        searchController.searchBar.barStyle = .black
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        transcriptions = repo.showAll()
        homeView.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toTranscriptionPageSegue" {
            if let dest = segue.destination as? TranscriptionViewController {
                dest.delegate = self
            }
        }
        
    }
    
    
    
}
