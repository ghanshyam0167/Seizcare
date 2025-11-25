//
//  ProfileTableViewController.swift
//  Seizcare
//
//  Created by Student on 20/11/25.
//

import UIKit

class ProfileTableViewController: UITableViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // Make circular profile image
                profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
                profileImageView.clipsToBounds = true

            }
    @objc func imageTapped() {
        performSegue(withIdentifier: "goToNextScreen", sender: self)
    }

    
}



