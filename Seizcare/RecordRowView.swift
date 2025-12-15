//
//  RecordRowView.swift
//  Seizcare
//
//  Created by Student on 15/12/25.
//

import UIKit

final class RecordRowView: UIView {

    private let container = UIView()

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
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        icon.tintColor = .systemRed
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

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

        // 🔥 THIS is the row-height stabilizer
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
        titleLabel?.text = record.type?.rawValue.capitalized ?? "Manual Log"

        if let duration = record.duration {
            let mins = Int(duration) / 60
            let secs = Int(duration) % 60
            subtitleLabel?.text = "Duration: \(mins) min \(secs) sec"
        } else {
            subtitleLabel?.text = record.description
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        dateLabel?.text = formatter.string(from: record.dateTime).uppercased()
    }
}
