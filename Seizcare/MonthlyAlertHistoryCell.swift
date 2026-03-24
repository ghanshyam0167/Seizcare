//
//  MonthlyAlertHistoryCell.swift
//  Seizcare
//
//  Created by Student on 16/12/25.
//

import UIKit

class MonthlyAlertHistoryCell: UITableViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var stackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        cardView.applyDashboardCard()
    }

    func configure(alerts: [AppNotification]) {

        // Clear old rows
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Add rows using real model
        for (index, alert) in alerts.enumerated() {
            let row = AlertRowView(notification: alert)
            stackView.addArrangedSubview(row)
            
            // Add separator between rows
            if index < alerts.count - 1 {
                let dividerWrap = UIView()
                dividerWrap.translatesAutoresizingMaskIntoConstraints = false
                
                let divider = UIView()
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
                dividerWrap.addSubview(divider)
                
                NSLayoutConstraint.activate([
                    divider.leadingAnchor.constraint(equalTo: dividerWrap.leadingAnchor, constant: 56), // Align with text (16 + 28 icon + 12 gap)
                    divider.trailingAnchor.constraint(equalTo: dividerWrap.trailingAnchor),
                    divider.topAnchor.constraint(equalTo: dividerWrap.topAnchor),
                    divider.bottomAnchor.constraint(equalTo: dividerWrap.bottomAnchor),
                    divider.heightAnchor.constraint(equalToConstant: 0.5)
                ])
                stackView.addArrangedSubview(dividerWrap)
            }
        }
    }

}
