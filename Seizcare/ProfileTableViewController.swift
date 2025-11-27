//
//  ProfileTableViewController.swift
//  Seizcare
//
//  Created by Student on 20/11/25.
//

import UIKit

class ProfileTableViewController: UITableViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userEmailLabel: UILabel!
    
    var user : User?
    override func viewDidLoad() {
        super.viewDidLoad()
                profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
                profileImageView.clipsToBounds = true
        
        updateUI()

            }
    override func viewWillAppear(_ animated: Bool) {
        updateUI()
    }
    @objc func imageTapped() {
        performSegue(withIdentifier: "goToNextScreen", sender: self)
    }
    func updateUI(){
        user = UserDataModel.shared.getCurrentUser()
        guard let user = user else { return }
        userNameLabel.text = user.fullName
        userEmailLabel.text = user.email
    }

    
}



