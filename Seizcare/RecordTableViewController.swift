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

class RecordTableViewController: UITableViewController {

    // Dynamic section titles
    var sectionTitles: [String] = []
    
    // Grouped records by month
    var recordsBySection: [[SeizureRecord]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loadAndGroupRecords()
        setupBottomSearchBar()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAndGroupRecords()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.loadAndGroupRecords()
        }
    }


    // MARK: - Load + Group
    func loadAndGroupRecords() {
        let records = SeizureRecordDataModel.shared.getRecordsForCurrentUser()
        // Group by month
        print(records)
        let grouped = Dictionary(grouping: records) { record -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            return formatter.string(from: record.dateTime).uppercased()
        }

        // Sort sections by most recent month first
        sectionTitles = grouped.keys.sorted { title1, title2 in
            let monthsOrder = ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
            return monthsOrder.firstIndex(of: title1)! > monthsOrder.firstIndex(of: title2)!
        }

        // Fill recordsBySection in the same order
        recordsBySection = sectionTitles.map { grouped[$0]!.sorted { $0.dateTime > $1.dateTime } }
        
        tableView.reloadData()
    }

    // MARK: - Search bar stacked (iOS 16)
    func setupBottomSearchBar() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
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
        return recordsBySection[section].count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! RecordTableViewCell
        let record = recordsBySection[indexPath.section][indexPath.row]

        // Format date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        let formattedDate = formatter.string(from: record.dateTime).uppercased()

        // Cell UI
        cell.dateLabel.text = formattedDate
        
        if record.entryType == .automatic {
            cell.seizureLevelLabel.text = record.type?.rawValue.capitalized ?? "Automatic"
            
            if let dur = record.duration {
                cell.durationLabel.text = formatDuration(dur)
            } else {
                cell.durationLabel.text = "--"
            }
        } else {
            // manual record
            cell.seizureLevelLabel.text = record.title ?? "Manual Log"
            cell.durationLabel.text = record.description ?? ""
        }

        return cell
    }

    // Convert seconds → "1 min 45 sec"
    func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins) min \(secs) sec"
    }

    // MARK: - Row Tap → Detail Screen
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showRecordDetails", sender: indexPath)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRecordDetails" {
            if let nav = segue.destination as? UINavigationController,
               let detailsVC = nav.topViewController as? DetailRecordsTableViewController,
               let indexPath = sender as? IndexPath {

                let selectedRecord = recordsBySection[indexPath.section][indexPath.row]
                detailsVC.record = selectedRecord
            }
        }
    }
}
