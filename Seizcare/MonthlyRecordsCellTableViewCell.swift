//
//  MonthlyRecordsCellTableViewCell.swift
//  Seizcare
//
//  Created by Student on 15/12/25.
//

import UIKit

protocol MonthlyRecordsCellDelegate: AnyObject {
    func didSelectRecord(_ record: SeizureRecord)
}

class MonthlyRecordsCell: UITableViewCell {

    weak var delegate: MonthlyRecordsCellDelegate?
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    private var records: [SeizureRecord] = []


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

        cardView.applyDashboardCard()
    }

    func configure(records: [SeizureRecord]) {
        self.records = records
        // FULL reset (important for reused cells)
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, record) in records.enumerated() {
                let row = RecordRowView(record: record)
                row.tag = index                      // 🔑 store index
                row.isUserInteractionEnabled = true  // 🔑 enable taps

                let tap = UITapGestureRecognizer(
                    target: self,
                    action: #selector(handleRowTap(_:))
                )
                row.addGestureRecognizer(tap)

                stackView.addArrangedSubview(row)
            }
    }
    func recordTapped(at index: Int) {
            let record = records[index]
            delegate?.didSelectRecord(record)
        }
    @objc private func handleRowTap(_ sender: UITapGestureRecognizer) {
        guard let row = sender.view else { return }
        let index = row.tag
        let record = records[index]
        delegate?.didSelectRecord(record)
    }



}
