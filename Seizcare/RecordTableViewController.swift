//
//  RecordTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

class RecordTableViewController: UITableViewController {

    let sectionTitles = ["OCTOBER", "SEPTEMBER", "AUGUST"]
    var records: [Record] = [
        Record(
            title: "Severe",
            date: "13 OCT",
            duration: "1 min 45 sec",
            severity: 2,
            symptoms: ["Dizziness", "Nausea", "Headache"],
            notes: "Felt dizzy and confused before the seizure.",
            location: "Chandigarh, Sector 14",
            heartRate: 118,
            spo2: 94
        ),
        
        Record(
            title: "Moderate",
            date: "02 OCT",
            duration: "50 sec",
            severity: 1,
            symptoms: ["Tired", "Body Ache"],
            notes: "Mild fatigue throughout the day before seizure.",
            location: "Mohali, Phase 7",
            heartRate: 102,
            spo2: 97
        ),
        
        Record(
            title: "Mild",
            date: "23 SEP",
            duration: "25 sec",
            severity: 0,
            symptoms: ["Déjà vu"],
            notes: "Short episode, but unusual smell detected.",
            location: "Panchkula, Sector 12",
            heartRate: 89,
            spo2: 98
        )
    ]
    var recordsBySection: [[Record]] = [[], [], []]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupRecordsByMonth()
        setupBottomSearchBar()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return recordsBySection[section].count
    }
    
    func setupBottomSearchBar() {
        let searchController = UISearchController(searchResultsController: nil)
           searchController.searchBar.placeholder = "Search"

           navigationItem.searchController = searchController
           
           // iOS 16+
           if #available(iOS 16.0, *) {
               navigationItem.preferredSearchBarPlacement = .stacked   // bottom style
           }
    }
    func groupRecordsByMonth() {
        // Clear old data
        recordsBySection = [[], [], []]

        for record in records {
            let dateUpper = record.date.uppercased()

            if dateUpper.contains("OCT") {
                recordsBySection[0].append(record)
            } else if dateUpper.contains("SEP") {
                recordsBySection[1].append(record)
            } else if dateUpper.contains("AUG") {
                recordsBySection[2].append(record)
            }
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! RecordTableViewCell
        
        cell.durationLabel.text = recordsBySection[indexPath.section][indexPath.row].duration
        cell.dateLabel.text = recordsBySection[indexPath.section][indexPath.row].date
        cell.seizureLevelLabel.text = recordsBySection[indexPath.section][indexPath.row].title

         

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRecordDetails" {

            // 1. Destination is a nav controller
            if let nav = segue.destination as? UINavigationController {

                // 2. Get the real details VC
                if let detailVC = nav.topViewController as? DetailRecordsTableViewController {

                    // 3. sender is the indexPath
                    if let indexPath = sender as? IndexPath {
                        let selectedRecord = recordsBySection[indexPath.section][indexPath.row]
                        detailVC.record = selectedRecord
                    }
                }
            }
        }
    }


    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(recordsBySection[indexPath.section][indexPath.row])
        let selectedRecord = recordsBySection[indexPath.section][indexPath.row]
        performSegue(withIdentifier: "showRecordDetails", sender: indexPath)
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
