//
//  RecordTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

//
//  RecordTableViewController.swift
//  Seizcare
//

import UIKit

class RecordTableViewController: UITableViewController,UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""

        if query.isEmpty {
            isSearching = false
            groupAndReload(allRecords)
            return
        }

        isSearching = true

        let filtered = allRecords.filter { record in
            let titleMatch = record.title?.lowercased().contains(query) ?? false
            let typeMatch = record.type?.rawValue.lowercased().contains(query) ?? false
            let descMatch = record.description?.lowercased().contains(query) ?? false

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMMM yyyy"
            let dateMatch = formatter.string(from: record.dateTime).lowercased().contains(query)

            return titleMatch || typeMatch || descMatch || dateMatch
        }

        groupAndReload(filtered)
    }

    

    // Dynamic section titles
    var sectionTitles: [String] = []
    
    // Grouped records by month
    var recordsBySection: [[SeizureRecord]] = []
    
    private var allRecords: [SeizureRecord] = []
    private var isSearching = false


    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        loadAndGroupRecords()
        setupBottomSearchBar()
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.systemGroupedBackground
    }
    
    
    // MARK: - Load + Group
    func loadAndGroupRecords() {
        let records = SeizureRecordDataModel.shared.getRecordsForCurrentUser()
            allRecords = records
            groupAndReload(records)
    }
    private func groupAndReload(_ records: [SeizureRecord]) {
        // Group by "Month Year" (e.g., "NOVEMBER 2025")
        let grouped = Dictionary(grouping: records) { record -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: record.dateTime).uppercased()
        }

        // Sort section titles by the actual date of the records (Descending: Newest first)
        sectionTitles = grouped.keys.sorted { title1, title2 in
            // Get ANY record from the group to representative date
            let date1 = grouped[title1]?.first?.dateTime ?? Date.distantPast
            let date2 = grouped[title2]?.first?.dateTime ?? Date.distantPast
            return date1 > date2
        }

        // Map sorted titles to sorted records
        recordsBySection = sectionTitles.map {
            grouped[$0]!.sorted { $0.dateTime > $1.dateTime }
        }

        tableView.reloadData()
    }


    // MARK: - Search bar stacked (iOS 16)
    func setupBottomSearchBar() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search records"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self

        navigationItem.searchController = searchController

        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }

        definesPresentationContext = true
    }


    // MARK: - TableView Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    // MARK: - Rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
                withIdentifier: "MonthlyRecordsCell",
                for: indexPath
            ) as! MonthlyRecordsCell

            let records = recordsBySection[indexPath.section]
            cell.delegate = self
            cell.configure(records: records)
        
        return cell
    }

    // Convert seconds → "1 min 45 sec"
    func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins) min \(secs) sec"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addRecord" {
               if let nav = segue.destination as? UINavigationController,
                  let addVC = nav.topViewController as? AddRecordTableViewController {

                   addVC.onDismiss = { [weak self] in
                       print("🔥 AddRecord dismissed — refreshing list")
                       self?.loadAndGroupRecords()
                   }
               }
           }
        if segue.identifier == "showRecordDetails",
           let detailsVC = segue.destination as? DetailRecordsTableViewController,
           let record = sender as? SeizureRecord {

            detailsVC.record = record
            detailsVC.onDismiss = { [weak self] in

                self?.loadAndGroupRecords()
            }
        }
    }
    @IBAction func unwindToDashboard(_ segue: UIStoryboardSegue) {
        print("Returned from Add Record screen")
    }
}

extension RecordTableViewController: MonthlyRecordsCellDelegate {
    func didSelectRecord(_ record: SeizureRecord) {
        performSegue(withIdentifier: "showRecordDetails", sender: record)
    }
}
