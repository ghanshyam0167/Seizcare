//
//  DashboardTableViewController.swift
//  Seizcare
//
//  Created by GS Agrawal on 24/11/25.
//

import UIKit

class DashboardTableViewController: UITableViewController {

    @IBOutlet weak var weeklyMonthlySegment: UISegmentedControl!
    @IBOutlet weak var recordCardView1: UIView!
    @IBOutlet weak var recordCardView0: UIView!
    @IBOutlet weak var bottomCardView1: UIView!
    @IBOutlet weak var bottomCardView0: UIView!
    @IBOutlet weak var recordsCardView: UIView!
    @IBOutlet weak var currentCardView3: UIView!
    @IBOutlet weak var currentCardView2: UIView!
    @IBOutlet weak var currentCardView1: UIView!
    @IBOutlet weak var currentCardView0: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDataModel.shared.loginUser(email: "ghanshyam@example.com", password: "password121")
        
        [currentCardView0, currentCardView1, currentCardView2, currentCardView3,
             recordsCardView, bottomCardView0, bottomCardView1].forEach { view in
                view?.applyCardStyle()
            }
        [recordCardView0, recordCardView1].forEach { card in
                card?.applyRecordCardStyle()
            }
        styleSegmentControl()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    func styleSegmentControl() {
        // Background of entire segmented control
        weeklyMonthlySegment.backgroundColor = UIColor(red: 237/255, green: 237/255, blue: 242/255, alpha: 1)
        weeklyMonthlySegment.selectedSegmentTintColor = .white

        // Corner radius
        weeklyMonthlySegment.layer.cornerRadius = 16
        weeklyMonthlySegment.layer.masksToBounds = true

        // Text attributes
        let normalText = [NSAttributedString.Key.foregroundColor: UIColor.black,
                          .font: UIFont.systemFont(ofSize: 16, weight: .medium)]
        let selectedText = [NSAttributedString.Key.foregroundColor: UIColor(red: 36/255, green: 104/255, blue: 244/255, alpha: 1),
                            .font: UIFont.systemFont(ofSize: 16, weight: .medium)]

        weeklyMonthlySegment.setTitleTextAttributes(normalText, for: .normal)
        weeklyMonthlySegment.setTitleTextAttributes(selectedText, for: .selected)
    }

    

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
extension UIView {
    func applyCardStyle() {
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        self.layer.borderWidth = 0.6
        self.backgroundColor = .white
        
        // Smooth shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.08
        self.layer.shadowRadius = 12
        self.layer.shadowOffset = CGSize(width: 0, height: 6)
    }
    
    func applyRecordCardStyle() {
           self.backgroundColor = .white
           self.layer.cornerRadius = 14
           self.layer.masksToBounds = false

           // Thin border
           self.layer.borderWidth = 1.0
           self.layer.borderColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1.0).cgColor
           
           // Very soft shadow
           self.layer.shadowColor = UIColor.black.cgColor
           self.layer.shadowOpacity = 0.04
           self.layer.shadowRadius = 4
           self.layer.shadowOffset = CGSize(width: 0, height: 2)
       }
    func applyRecordGroupedStyle() {
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        self.layer.borderWidth = 0.6
        self.backgroundColor = .white
        
        // Same smooth shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.08
        self.layer.shadowRadius = 12
        self.layer.shadowOffset = CGSize(width: 0, height: 6)
    }

}
