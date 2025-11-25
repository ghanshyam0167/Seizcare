//
//  ProfileViewTableViewController.swift
//  Seizcare
//
//  Created by Student on 25/11/25.
//

import UIKit



class ProfileViewTableViewController: UITableViewController {
    
    @IBOutlet weak var nameRightLabel: UILabel!
    @IBOutlet weak var emailRightLabel: UILabel!
    @IBOutlet weak var phoneRightLabel: UILabel!
    @IBOutlet weak var dobRightLabel: UILabel!
    @IBOutlet weak var genderRightLabel: UILabel!
    @IBOutlet weak var heightRightLabel: UILabel!
    @IBOutlet weak var weightRightLabel: UILabel!
    @IBOutlet weak var bloodGroupRightLabel: UILabel!
    
    var user = User(
        name: "Jasmeen Grewal",
        email: "jasmeen0614.be23@chitkara.edu.in",
        phone: "+91 7206306241",
        dob: "8 Aug 2005",
        gender: "Female",
        height: "170cm",
        weight: "60kg",
        bloodGroup: "B+"
    )


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        updateUI()
    }

    
    @IBSegueAction func goToEditProfile(_ coder: NSCoder) -> EditProfileTableViewController? {
        return EditProfileTableViewController(coder: coder, user : user)
    }
    
    func updateUI() {
        nameRightLabel.text = user.name
        emailRightLabel.text = user.email
        phoneRightLabel.text = user.phone
        dobRightLabel.text = user.dob
        genderRightLabel.text = user.gender
        heightRightLabel.text = user.height
        weightRightLabel.text = user.weight
        bloodGroupRightLabel.text = user.bloodGroup
    }


}
