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

    var user: User?

    // MARK: - Design Tokens
    private let accentBlue = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1)
    private let cardCornerRadius: CGFloat = 16
    private let cardShadowOpacity: Float = 0.08
    private let cardShadowRadius: CGFloat = 8
    private let cardShadowOffset = CGSize(width: 0, height: 4)
    private let iconCircleSize: CGFloat = 36
    private let rowHeight: CGFloat = 56

    // MARK: - Programmatic Views
    private let scrollContent = UIView()

    // Profile header card
    private let profileCard = UIView()
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let profileChevron = UIImageView()

    // Safety section
    private let safetyTitleLabel = UILabel()
    private let safetyCard = UIView()

    // Preferences section
    private let prefsTitleLabel = UILabel()
    private let prefsCard = UIView()

    // Logout button
    private let logoutButton = UIButton(type: .system)

    // MARK: - Settings Rows Data
    private struct SettingsRow {
        let icon: String
        let title: String
        let segueID: String
    }

    private let safetyRows: [SettingsRow] = [
        SettingsRow(icon: "person.3.fill", title: "Emergency Contacts", segueID: "goToEmergencyContacts"),
        SettingsRow(icon: "slider.horizontal.3", title: "Sensitivity", segueID: "goToSensitivity")
    ]

    private let prefsRows: [SettingsRow] = [
        SettingsRow(icon: "globe", title: "Language", segueID: "goToLanguage"),
        SettingsRow(icon: "applewatch", title: "Connect your watch", segueID: "")
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Settings"
        navigationController?.applyWhiteNavBar()

        // Hide ALL storyboard subviews — we take full programmatic control
        tableView.subviews.forEach { subview in
            if subview !== tableView.backgroundView {
                subview.isHidden = true
            }
        }
        // Use a plain scroll view approach on top of the table
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        applyDefaultTableBackground()

        buildUI()
        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update scroll content size
        let bottomPadding: CGFloat = 40
        let contentHeight = logoutButton.frame.maxY + bottomPadding
        tableView.contentSize = CGSize(width: tableView.bounds.width, height: max(contentHeight, tableView.bounds.height))
    }

    // MARK: - Build UI

    private func buildUI() {
        // Add a content container to the tableView
        scrollContent.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(scrollContent)

        NSLayoutConstraint.activate([
            scrollContent.topAnchor.constraint(equalTo: tableView.topAnchor),
            scrollContent.leadingAnchor.constraint(equalTo: tableView.frameLayoutGuide.leadingAnchor),
            scrollContent.trailingAnchor.constraint(equalTo: tableView.frameLayoutGuide.trailingAnchor)
        ])

        buildProfileCard()
        buildSection(titleLabel: safetyTitleLabel, title: "SAFETY", card: safetyCard, rows: safetyRows, topAnchor: profileCard.bottomAnchor, topConstant: 28)
        buildSection(titleLabel: prefsTitleLabel, title: "PREFERENCES", card: prefsCard, rows: prefsRows, topAnchor: safetyCard.bottomAnchor, topConstant: 28)
        buildLogoutButton()

        // Bottom anchor for scroll content
        NSLayoutConstraint.activate([
            scrollContent.bottomAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 40)
        ])
    }

    // MARK: - Profile Header Card

    private func buildProfileCard() {
        profileCard.translatesAutoresizingMaskIntoConstraints = false
        scrollContent.addSubview(profileCard)
        applyCardStyle(to: profileCard)

        // Avatar
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.image = UIImage(systemName: "person.fill")
        avatarView.tintColor = accentBlue
        avatarView.contentMode = .center
        avatarView.backgroundColor = accentBlue.withAlphaComponent(0.08)
        avatarView.layer.cornerRadius = 30
        avatarView.clipsToBounds = true
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = accentBlue.withAlphaComponent(0.2).cgColor
        profileCard.addSubview(avatarView)

        // Name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = .label
        profileCard.addSubview(nameLabel)

        // Email
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        emailLabel.textColor = .secondaryLabel
        profileCard.addSubview(emailLabel)

        // Chevron
        profileChevron.translatesAutoresizingMaskIntoConstraints = false
        profileChevron.image = UIImage(systemName: "chevron.right")
        profileChevron.tintColor = .tertiaryLabel
        profileChevron.contentMode = .scaleAspectFit
        profileCard.addSubview(profileChevron)

        NSLayoutConstraint.activate([
            profileCard.topAnchor.constraint(equalTo: scrollContent.topAnchor, constant: 20),
            profileCard.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 16),
            profileCard.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor, constant: -16),

            avatarView.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            nameLabel.bottomAnchor.constraint(equalTo: profileCard.centerYAnchor, constant: -1),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: profileChevron.leadingAnchor, constant: -8),

            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.topAnchor.constraint(equalTo: profileCard.centerYAnchor, constant: 3),
            emailLabel.trailingAnchor.constraint(lessThanOrEqualTo: profileChevron.leadingAnchor, constant: -8),

            profileChevron.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),
            profileChevron.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
            profileChevron.widthAnchor.constraint(equalToConstant: 12),
            profileChevron.heightAnchor.constraint(equalToConstant: 18),

            profileCard.heightAnchor.constraint(equalToConstant: 88)
        ])

        // Tap gesture for profile
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileCardTapped))
        profileCard.addGestureRecognizer(tap)
        profileCard.isUserInteractionEnabled = true
    }

    // MARK: - Settings Section Builder

    private func buildSection(titleLabel: UILabel, title: String, card: UIView, rows: [SettingsRow], topAnchor: NSLayoutYAxisAnchor, topConstant: CGFloat) {

        // Section title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        scrollContent.addSubview(titleLabel)

        // Card
        card.translatesAutoresizingMaskIntoConstraints = false
        scrollContent.addSubview(card)
        applyCardStyle(to: card)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: topConstant),
            titleLabel.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 28),

            card.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            card.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor, constant: -16)
        ])

        // Build rows inside card
        var previousRowBottom: NSLayoutYAxisAnchor = card.topAnchor
        for (index, row) in rows.enumerated() {
            let rowView = buildSettingsRow(icon: row.icon, title: row.title, tag: index, segueID: row.segueID, parent: card)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(rowView)

            NSLayoutConstraint.activate([
                rowView.topAnchor.constraint(equalTo: previousRowBottom),
                rowView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                rowView.heightAnchor.constraint(equalToConstant: rowHeight)
            ])

            // Divider (not after last row)
            if index < rows.count - 1 {
                let divider = UIView()
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
                card.addSubview(divider)
                NSLayoutConstraint.activate([
                    divider.topAnchor.constraint(equalTo: rowView.bottomAnchor),
                    divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 64),
                    divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                    divider.heightAnchor.constraint(equalToConstant: 0.5)
                ])
                previousRowBottom = divider.bottomAnchor
            } else {
                previousRowBottom = rowView.bottomAnchor
            }
        }

        // Card bottom constraint
        card.bottomAnchor.constraint(equalTo: previousRowBottom).isActive = true
    }

    // MARK: - Single Settings Row

    private func buildSettingsRow(icon: String, title: String, tag: Int, segueID: String, parent: UIView) -> UIView {
        let container = UIView()

        // Icon circle
        let iconCircle = UIView()
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.backgroundColor = accentBlue.withAlphaComponent(0.1)
        iconCircle.layer.cornerRadius = iconCircleSize / 2
        container.addSubview(iconCircle)

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = accentBlue
        iconImageView.contentMode = .scaleAspectFit
        iconCircle.addSubview(iconImageView)

        // Title label
        let titleLbl = UILabel()
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 16, weight: .medium)
        titleLbl.textColor = .label
        container.addSubview(titleLbl)

        // Chevron
        let chevron = UIImageView()
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.image = UIImage(systemName: "chevron.right")
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        container.addSubview(chevron)

        NSLayoutConstraint.activate([
            iconCircle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconCircle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconCircle.widthAnchor.constraint(equalToConstant: iconCircleSize),
            iconCircle.heightAnchor.constraint(equalToConstant: iconCircleSize),

            iconImageView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18),

            titleLbl.leadingAnchor.constraint(equalTo: iconCircle.trailingAnchor, constant: 14),
            titleLbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Tap gesture
        if !segueID.isEmpty {
            container.accessibilityIdentifier = segueID
            let tap = UITapGestureRecognizer(target: self, action: #selector(settingsRowTapped(_:)))
            container.addGestureRecognizer(tap)
            container.isUserInteractionEnabled = true
        }

        return container
    }

    // MARK: - Logout Button

    private func buildLogoutButton() {
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle("Log Out", for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        logoutButton.backgroundColor = .white
        logoutButton.layer.cornerRadius = 25
        logoutButton.layer.shadowColor = UIColor.black.cgColor
        logoutButton.layer.shadowOpacity = 0.06
        logoutButton.layer.shadowRadius = 8
        logoutButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        scrollContent.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: prefsCard.bottomAnchor, constant: 36),
            logoutButton.centerXAnchor.constraint(equalTo: scrollContent.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalTo: scrollContent.widthAnchor, constant: -64),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Card Style Helper

    private func applyCardStyle(to view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = cardCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = cardShadowOpacity
        view.layer.shadowRadius = cardShadowRadius
        view.layer.shadowOffset = cardShadowOffset
        view.clipsToBounds = false
    }

    // MARK: - Update UI

    func updateUI() {
        user = UserDataModel.shared.getCurrentUser()
        guard let user = user else { return }
        nameLabel.text = user.fullName
        emailLabel.text = user.email

        // Load saved profile photo
        if let savedPhoto = ProfilePhotoManager.shared.load() {
            avatarView.image = savedPhoto
            avatarView.contentMode = .scaleAspectFill
        }

        // Also update storyboard outlets (kept for compatibility)
        userNameLabel?.text = user.fullName
        userEmailLabel?.text = user.email
    }

    // MARK: - Actions

    @objc private func profileCardTapped() {
        performSegue(withIdentifier: "goToNextScreen", sender: self)
    }

    @objc private func settingsRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let segueID = gesture.view?.accessibilityIdentifier, !segueID.isEmpty else { return }
        performSegue(withIdentifier: segueID, sender: self)
    }

    @objc private func logoutTapped() {
        logoutButtonTapped(self)
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

    // MARK: - TableView Overrides (hide storyboard cells)

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
}
