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
        stackView.spacing = 12
        stackView.alignment = .fill

        cardView.applyDashboardCard()
    }

    func configure(alerts: [AppNotification]) {

        // Clear old rows
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Add rows using real model
        for alert in alerts {
            let row = AlertRowView(notification: alert)
            stackView.addArrangedSubview(row)
        }
    }

}
