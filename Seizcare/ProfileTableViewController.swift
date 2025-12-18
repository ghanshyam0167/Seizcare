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
    
    @IBOutlet weak var settingsCardContainer: UIView!
    var user : User?
    override func viewDidLoad() {
        super.viewDidLoad()
                profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
                profileImageView.clipsToBounds = true
        
        updateUI()
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        settingsCardContainer.applyDashboardCard()

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

    @IBAction func logoutButtonTapped(_ sender: Any) {
        let alert = UIAlertController(
                title: "Log Out",
                message: "Are you sure you want to log out?",
                preferredStyle: .alert
            )

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

            let logoutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
                self.performLogout()
            }

            alert.addAction(cancelAction)
            alert.addAction(logoutAction)

            present(alert, animated: true)
    }
    func performLogout() {
        UserDataModel.shared.logoutUser { success in
            if success {
                DispatchQueue.main.async {
                    self.goToLoginScreen()
                }
            }
        }
    }
    func goToLoginScreen() {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let loginVC = storyboard.instantiateViewController(
            withIdentifier: "SignInViewController"
        )

        let nav = UINavigationController(rootViewController: loginVC)

        if let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate {

            sceneDelegate.window?.rootViewController = nav
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
}



