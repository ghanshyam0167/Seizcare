//
//  RecordRowView.swift
//  Seizcare
//
//  Created by Student on 15/12/25.
//

import UIKit

enum RecordIcon {

    case manual
    case mild
    case moderate
    case severe

    var image: UIImage? {
        switch self {
        case .manual:
            return UIImage(systemName: "book.closed.fill")

        case .mild:
            return UIImage(systemName: "exclamationmark.triangle")

        case .moderate:
            return UIImage(systemName: "exclamationmark.triangle.fill")

        case .severe:
            return UIImage(systemName: "exclamationmark.triangle.fill")
        }
    }

    var tintColor: UIColor {
        switch self {
        case .manual:
            return UIColor.systemBlue

        case .mild:
            return UIColor.systemOrange

        case .moderate:
            return UIColor.systemRed.withAlphaComponent(0.85)

        case .severe:
            return UIColor.systemRed
        }
    }
}


final class RecordRowView: UIView {

    private let container = UIView()
    private weak var iconView: UIImageView?


    init(record: SeizureRecord) {
        super.init(frame: .zero)
        setupUI()
        configure(record)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Main horizontal row
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        self.iconView = icon

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .right

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit

        chevron.widthAnchor.constraint(equalToConstant: 10).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let rightStack = UIStackView(arrangedSubviews: [dateLabel, chevron])
        rightStack.axis = .horizontal
        rightStack.spacing = 6
        rightStack.alignment = .center

        let rowStack = UIStackView(arrangedSubviews: [icon, textStack, rightStack])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])
        
        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        // Save refs
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel
        self.dateLabel = dateLabel
    }

    private weak var titleLabel: UILabel?
    private weak var subtitleLabel: UILabel?
    private weak var dateLabel: UILabel?

    private func configure(_ record: SeizureRecord) {

        let icon = record.recordIcon
        iconView?.image = icon.image
        iconView?.tintColor = icon.tintColor

        if record.entryType == .manual {
            titleLabel?.text = record.title?.localized() ?? "Manual Log".localized()
        } else {
            titleLabel?.text = record.type?.displayText ?? "Seizure".localized()
        }

        if let duration = record.duration {
            let mins = Int(duration) / 60
            let secs = Int(duration) % 60
            let minStr = "min".localized()
            let secStr = "sec".localized()
            let durationTitle = "Duration".localized()
            subtitleLabel?.text = "\(durationTitle): \(mins) \(minStr) \(secs) \(secStr)"
        } else {
            subtitleLabel?.text = record.description?.localized()
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.code)
        formatter.dateFormat = "dd MMM"
        dateLabel?.text = formatter.string(from: record.dateTime).uppercased()
    }

}

extension SeizureRecord {

    var recordIcon: RecordIcon {
        // Manual entry
        if entryType == .manual {
            return .manual
        }

        // Automatic entry → severity based
        switch type {
        case .mild:
            return .mild
        case .moderate:
            return .moderate
        case .severe:
            return .severe
        default:
            return .moderate
        }
    }
}
