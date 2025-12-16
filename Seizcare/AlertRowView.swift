//
//  AlertRowView.swift
//  Seizcare
//

import UIKit

enum AlertIcon {
    case seizure
    case heartRate
    case spo2
    case summary
    case generic

    var image: UIImage? {
        switch self {
        case .seizure:
            return UIImage(systemName: "exclamationmark.triangle.fill")
        case .heartRate:
            return UIImage(systemName: "waveform.path.ecg")
        case .spo2:
            return UIImage(systemName: "heart.text.square.fill")
        case .summary:
            return UIImage(systemName: "chart.bar.xaxis")
        case .generic:
            return UIImage(systemName: "bell.fill")
        }
    }

    var tintColor: UIColor {
        switch self {
        case .seizure:
            return .systemRed
        case .heartRate:
            return .systemOrange
        case .spo2:
            return .systemBlue
        case .summary:
            return .systemPurple
        case .generic:
            return .secondaryLabel
        }
    }
}


final class AlertRowView: UIView {

    private let container = UIView()
    private weak var iconView: UIImageView?

    private weak var titleLabel: UILabel?
    private weak var subtitleLabel: UILabel?
    private weak var timeLabel: UILabel?

    // MARK: - Init

    init(notification: AppNotification) {
        super.init(frame: .zero)
        setupUI()
        configure(notification)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Setup

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Icon
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true
        self.iconView = icon

        // Title
        let title = UILabel()
        title.font = .systemFont(ofSize: 16, weight: .semibold)

        // Subtitle
        let subtitle = UILabel()
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 2

        // Time label
        let time = UILabel()
        time.font = .systemFont(ofSize: 14)
        time.textColor = .secondaryLabel
        time.textAlignment = .right

        let rowStack = UIStackView(arrangedSubviews: [icon, textStack, time])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        container.heightAnchor
            .constraint(greaterThanOrEqualToConstant: 56)
            .isActive = true

        // Save refs
        self.titleLabel = title
        self.subtitleLabel = subtitle
        self.timeLabel = time
    }

    // MARK: - Configure

    private func configure(_ notification: AppNotification) {

        // Icon from ENUM (not model)
        let icon = notification.alertIcon
        iconView?.image = icon.image
        iconView?.tintColor = icon.tintColor

        // Text
        titleLabel?.text = notification.title
        subtitleLabel?.text = notification.description ?? ""

        // Time
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        timeLabel?.text = formatter.string(from: notification.dateTime).uppercased()
    }
}



extension AppNotification {

    var alertIcon: AlertIcon {
        let title = title.lowercased()

        if title.contains("seizure") {
            return .seizure
        }

        if title.contains("heart") {
            return .heartRate
        }

        if title.contains("spo₂") || title.contains("spo2") || title.contains("oxygen") {
            return .spo2
        }

        if title.contains("summary") {
            return .summary
        }

        return .generic
    }
}

