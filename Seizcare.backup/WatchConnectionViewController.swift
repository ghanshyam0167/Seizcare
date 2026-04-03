//
//  WatchConnectionViewController.swift
//  Seizcare
//
//  Presents the Apple Watch connection status and guides the user through pairing,
//  installing the Watch app, or opening the Watch app to become reachable.
//

import UIKit
import WatchConnectivity

class WatchConnectionViewController: UIViewController {

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    /// Card that holds the status indicator
    private let statusCard = UIView()
    private let statusIconView  = UIImageView()
    private let statusTitleLabel   = UILabel()
    private let statusSubtitleLabel = UILabel()

    /// Step-by-step guidance card
    private let stepsCard = UIView()
    private let stepsHeaderLabel = UILabel()

    private let step1View = WatchStepView(number: "1", text: "Make sure your Apple Watch is nearby and unlocked.")
    private let step2View = WatchStepView(number: "2", text: "Open the Seizcare app on your Apple Watch.")
    private let step3View = WatchStepView(number: "3", text: "If the app is not installed, open the Watch app on your iPhone → My Watch → Available Apps.")

    /// Prominent action button at the bottom
    private let connectButton = UIButton(type: .system)

    // MARK: - State

    private var currentStatus: WatchConnectionStatus = .notPaired

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Apple Watch"
        view.backgroundColor = UIColor.systemGroupedBackground
        navigationController?.applyWhiteNavBar()
        setupLayout()
        // Ensure WatchConnectivityManager is alive so WCSession is activated
        _ = WatchConnectivityManager.shared
        observeSessionNotification()
        refreshStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStatus()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notification Observation

    private func observeSessionNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionActivated),
            name: .watchSessionActivated,
            object: nil
        )
    }

    @objc private func handleSessionActivated() {
        refreshStatus()
    }

    // MARK: - Status Refresh

    private func refreshStatus() {
        currentStatus = WatchConnectivityManager.shared.checkCurrentStatus()
        updateStatusUI(for: currentStatus)
    }

    // MARK: - UI Update

    private func updateStatusUI(for status: WatchConnectionStatus) {
        // ── Icon ──────────────────────────────────────────────────────────────
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 52, weight: .medium)
        statusIconView.image  = UIImage(systemName: status.symbolName, withConfiguration: symbolConfig)
        statusIconView.tintColor = status.accentColor

        // ── Labels ────────────────────────────────────────────────────────────
        statusTitleLabel.text    = status.title
        statusTitleLabel.textColor = status.accentColor
        statusSubtitleLabel.text = status.subtitle

        // ── Card border flash ─────────────────────────────────────────────────
        statusCard.layer.borderColor = status.accentColor.withAlphaComponent(0.4).cgColor

        // ── Button ────────────────────────────────────────────────────────────
        let buttonTitle: String
        switch status {
        case .notSupported:
            buttonTitle = "Not Available"
            connectButton.isEnabled = false
        case .notPaired, .notInstalled:
            buttonTitle = "Open Watch App"
            connectButton.isEnabled = true
        case .notReachable:
            buttonTitle = "Refresh Status"
            connectButton.isEnabled = true
        case .connected:
            buttonTitle = "✓ Connected"
            connectButton.isEnabled = false
        }

        var config = UIButton.Configuration.filled()
        config.title = buttonTitle
        config.baseBackgroundColor = status == .connected ? .systemGreen : UIColor(red: 36/255, green: 104/255, blue: 244/255, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr
            a.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            return a
        }
        connectButton.configuration = config

        // ── Steps visibility ──────────────────────────────────────────────────
        stepsCard.isHidden = (status == .connected || status == .notSupported)
        step3View.isHidden = (status != .notInstalled)
    }

    // MARK: - Button Action

    @objc private func connectButtonTapped() {
        refreshStatus()     // always get the freshest state first

        switch currentStatus {
        case .notPaired:
            showAlert(
                title: "Pair an Apple Watch",
                message: "No Apple Watch is paired with your iPhone. Open the Apple Watch app to pair your watch.",
                primaryActionTitle: "Open Watch App",
                primaryAction: { WatchConnectivityManager.shared.openWatchApp() }
            )

        case .notInstalled:
            showAlert(
                title: "Install Watch App",
                message: "The Seizcare app is not installed on your Apple Watch.\n\nOpen the Watch app → My Watch → Available Apps, then install Seizcare.",
                primaryActionTitle: "Open Watch App",
                primaryAction: { WatchConnectivityManager.shared.openWatchApp() }
            )

        case .notReachable:
            showAlert(
                title: "Open Seizcare on Watch",
                message: "Your Apple Watch is paired and the app is installed, but it's not reachable right now.\n\nPlease open the Seizcare app on your Apple Watch.",
                primaryActionTitle: "OK",
                primaryAction: nil
            )

        case .connected:
            break   // Button is disabled in this state

        case .notSupported:
            break   // Button is disabled in this state
        }
    }

    // MARK: - Alert Helper

    private func showAlert(title: String,
                           message: String,
                           primaryActionTitle: String,
                           primaryAction: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let primary = UIAlertAction(title: primaryActionTitle, style: .default) { _ in
            primaryAction?()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(primary)
        if primaryAction != nil { alert.addAction(cancel) }
        present(alert, animated: true)
    }

    // MARK: - Layout

    private func setupLayout() {
        // ── ScrollView ────────────────────────────────────────────────────────
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // ── Status Card ───────────────────────────────────────────────────────
        setupStatusCard()
        contentView.addSubview(statusCard)
        statusCard.translatesAutoresizingMaskIntoConstraints = false

        // ── Steps Card ────────────────────────────────────────────────────────
        setupStepsCard()
        contentView.addSubview(stepsCard)
        stepsCard.translatesAutoresizingMaskIntoConstraints = false

        // ── Connect Button ────────────────────────────────────────────────────
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        contentView.addSubview(connectButton)

        NSLayoutConstraint.activate([
            statusCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            statusCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            stepsCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            stepsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stepsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            connectButton.topAnchor.constraint(equalTo: stepsCard.bottomAnchor, constant: 24),
            connectButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            connectButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            connectButton.heightAnchor.constraint(equalToConstant: 52),
            connectButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func setupStatusCard() {
        statusCard.applyDashboardCard()
        statusCard.layer.borderWidth = 1.5

        // Icon
        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        statusIconView.contentMode = .scaleAspectFit

        // Title
        statusTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        statusTitleLabel.textAlignment = .center
        statusTitleLabel.adjustsFontSizeToFitWidth = true

        // Subtitle
        statusSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        statusSubtitleLabel.textColor = .secondaryLabel
        statusSubtitleLabel.textAlignment = .center
        statusSubtitleLabel.numberOfLines = 0

        // Stack
        let stack = UIStackView(arrangedSubviews: [statusIconView, statusTitleLabel, statusSubtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        statusCard.addSubview(stack)
        NSLayoutConstraint.activate([
            statusIconView.heightAnchor.constraint(equalToConstant: 70),
            statusIconView.widthAnchor.constraint(equalToConstant: 70),

            stack.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -24)
        ])
    }

    private func setupStepsCard() {
        stepsCard.applyDashboardCard()

        stepsHeaderLabel.text = "How to connect"
        stepsHeaderLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        stepsHeaderLabel.textColor = .secondaryLabel
        stepsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        let stepStack = UIStackView(arrangedSubviews: [step1View, step2View, step3View])
        stepStack.axis = .vertical
        stepStack.spacing = 12
        stepStack.translatesAutoresizingMaskIntoConstraints = false

        stepsCard.addSubview(stepsHeaderLabel)
        stepsCard.addSubview(stepStack)

        NSLayoutConstraint.activate([
            stepsHeaderLabel.topAnchor.constraint(equalTo: stepsCard.topAnchor, constant: 16),
            stepsHeaderLabel.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 16),
            stepsHeaderLabel.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -16),

            stepStack.topAnchor.constraint(equalTo: stepsHeaderLabel.bottomAnchor, constant: 12),
            stepStack.leadingAnchor.constraint(equalTo: stepsCard.leadingAnchor, constant: 16),
            stepStack.trailingAnchor.constraint(equalTo: stepsCard.trailingAnchor, constant: -16),
            stepStack.bottomAnchor.constraint(equalTo: stepsCard.bottomAnchor, constant: -16)
        ])
    }
}

// MARK: - WatchStepView

/// A small numbered step row used inside the guidance card.
private class WatchStepView: UIView {

    init(number: String, text: String) {
        super.init(frame: .zero)
        setupWith(number: number, text: text)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupWith(number: String, text: String) {
        // Number badge
        let badge = UILabel()
        badge.text = number
        badge.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(red: 36/255, green: 104/255, blue: 244/255, alpha: 1)
        badge.layer.cornerRadius = 12
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 24).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 24).isActive = true

        // Text label
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [badge, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
