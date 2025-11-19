//
//  RecordsViewController.swift
//  Seizcare
//
//  Created by Student on 19/11/25.
//

import UIKit

class RecordsViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!

        let sectionTitles = ["OCTOBER", "SEPTEMBER", "AUGUST"]

        override func viewDidLoad() {
            super.viewDidLoad()

            tableView.delegate = self
            tableView.dataSource = self
        }

        // MARK: - Section Headers
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return sectionTitles[section]
        }

        // MARK: - Required TableView Methods
        func numberOfSections(in tableView: UITableView) -> Int {
            return sectionTitles.count
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 3   // temporary — change to real data later
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath)
            return cell
        }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
