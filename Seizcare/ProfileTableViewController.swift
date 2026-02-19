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
            title: "Log Out".localized(),
            message: "Are you sure you want to log out?".localized(),
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(
            title: "Log Out".localized(),
            style: .destructive,
            handler: { _ in
                // Clear user session
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                UserDefaults.standard.removeObject(forKey: "currentUserEmail")
                
                // Navigate to onboarding
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC = storyboard.instantiateViewController(withIdentifier: "OnboardingViewController")
                
                if let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate,
                   let window = sceneDelegate.window {
                    window.rootViewController = onboardingVC
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
                }
            }
        ))

        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))

        // iPad support
        if let popover = alert.popoverPresentationController {
             popover.sourceView = sender as? UIView
             popover.sourceRect = (sender as? UIView)?.bounds ?? CGRect.zero
         }

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



