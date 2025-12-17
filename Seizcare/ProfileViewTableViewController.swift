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
    
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
       
        updateUI()
    }
    
    @IBSegueAction func goToEditScreen(_ coder: NSCoder) -> EditProfileTableViewController? {
        let controller = EditProfileTableViewController(coder: coder, user: user)

          controller?.onDismiss = { [weak self] in
              self?.user = UserDataModel.shared.getCurrentUser()
              self?.updateUI()
          }

          return controller
    }
    func updateUI() {
        user = UserDataModel.shared.getCurrentUser()
        guard let user = user else { return }

        nameRightLabel.text = user.fullName
        emailRightLabel.text = user.email
        phoneRightLabel.text = user.contactNumber
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dobRightLabel.text = formatter.string(from: user.dateOfBirth)
        
        genderRightLabel.text = user.gender.rawValue.capitalized
        
        if let h = user.height {
            heightRightLabel.text = "\(h) cm"
        }
        if let w = user.weight {
            weightRightLabel.text = "\(w) kg"
        }
        bloodGroupRightLabel.text = user.bloodGroup ?? "-"
    }
    
    @IBAction func unwindToProfile(_ segue: UIStoryboardSegue) {
        updateUI()    
    }



}
