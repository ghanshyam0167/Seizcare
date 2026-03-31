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
    
    @IBOutlet weak var section1CardContainer: UIView!
    @IBOutlet weak var section0CardContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        [section1CardContainer, section0CardContainer].forEach {
            $0?.applyDashboardCard()
        }
        profileImageView?.contentMode = .scaleAspectFill
        profileImageView?.clipsToBounds = true
        updateUI()

        // Listen for avatar changes from any screen (handles async upload timing)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(avatarDidChange),
            name: UserDataModel.avatarDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func avatarDidChange() {
        let avatarUrl = UserDataModel.shared.getCurrentUser()?.avatarUrl
        UIImageView.bustCache(for: avatarUrl ?? "")
        profileImageView?.load(urlString: avatarUrl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView?.applyCircle()
        if tableView.tableFooterView == nil {
            setupDeleteAccountButton()
        }
    }

    // MARK: - Update UI

    @IBSegueAction func goToEditScreen(_ coder: NSCoder) -> EditProfileTableViewController? {
        let controller = EditProfileTableViewController(coder: coder, user: user)
        controller?.onDismiss = { [weak self] in
            guard let self = self else { return }
            // Refresh local reference from shared model
            self.user = UserDataModel.shared.getCurrentUser()
            self.updateUI()
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

        if let h = user.height { heightRightLabel.text = "\(h) cm" }
        if let w = user.weight { weightRightLabel.text = "\(w) kg" }
        bloodGroupRightLabel.text = user.bloodGroup ?? "-"

        // Always load avatar from Supabase URL (no local storage)
        profileImageView?.load(urlString: user.avatarUrl)
    }
    @IBAction func unwindToProfile(_ segue: UIStoryboardSegue) {
        updateUI()    
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
    
    // MARK: - Account Deletion (App Store Compliance)
    
    private func setupDeleteAccountButton() {
        // Create a footer view slightly taller to provide margin
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 100))
        
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setTitle("Delete Account", for: .normal)
        deleteBtn.setTitleColor(.white, for: .normal)
        deleteBtn.backgroundColor = .systemRed
        deleteBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        deleteBtn.layer.cornerRadius = 12
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        
        footerView.addSubview(deleteBtn)
        
        NSLayoutConstraint.activate([
            deleteBtn.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            deleteBtn.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 30),
            deleteBtn.heightAnchor.constraint(equalToConstant: 50),
            deleteBtn.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20),
            deleteBtn.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -20)
        ])
        
        deleteBtn.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        
        tableView.tableFooterView = footerView
    }
    
    @objc private func deleteAccountTapped() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to permanently delete your account? This will remove all your data including seizure records, contacts, and health data. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.promptTypeDeleteConfirmation()
        })
        
        present(alert, animated: true)
    }
    
    private func promptTypeDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Final Confirmation",
            message: "Please type \"DELETE\" to confirm permanent account deletion.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "DELETE"
            textField.autocapitalizationType = .allCharacters
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, text == "DELETE" else {
                let errorAlert = UIAlertController(title: "Mismatch", message: "You did not type 'DELETE'. Account deletion cancelled.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
                return
            }
            
            self?.executeAccountDeletion()
        })
        
        present(alert, animated: true)
    }
    
    private func executeAccountDeletion() {
        // Show loading indicator
    
        let loadingAlert = UIAlertController(title: "Deleting Account...", message: "\n\nPlease wait.", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = CGPoint(x: 135.0, y: 75.0) // Arbitrary center based on standard alert sizes
        spinner.startAnimating()
        loadingAlert.view.addSubview(spinner)
        present(loadingAlert, animated: true)
        
        Task {
            do {
                try await UserDataModel.shared.deleteAccountAsync()
                
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        let successAlert = UIAlertController(title: "Success", message: "Your account has been deleted successfully.", preferredStyle: .alert)
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                            self?.navigateToLogin()
                        })
                        self.present(successAlert, animated: true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        let errorAlert = UIAlertController(title: "Deletion Failed", message: error.localizedDescription, preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        }
    }
    
    private func navigateToLogin() {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let loginVC = storyboard.instantiateViewController(
            withIdentifier: "SignInViewController"
        )
        let nav = UINavigationController(rootViewController: loginVC)
        if let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate {
            
            sceneDelegate.window?.rootViewController = nav
            sceneDelegate.window?.makeKeyAndVisible()
            
            if let window = sceneDelegate.window {
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
            }
        }
    }
}

