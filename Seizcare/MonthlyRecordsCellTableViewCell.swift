//
//  MonthlyRecordsCellTableViewCell.swift
//  Seizcare
//
//  Created by Student on 15/12/25.
//

import UIKit

class MonthlyRecordsCell: UITableViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var stackView: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20
        cardView.layer.masksToBounds = false

        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardView.applyDashboardCard()
    }

    func configure(records: [SeizureRecord]) {

        // FULL reset (important for reused cells)
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for record in records {
            let row = RecordRowView(record: record)
            stackView.addArrangedSubview(row)
        }
    }


}
