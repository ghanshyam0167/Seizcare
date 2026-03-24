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
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
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
                
                // Add separator if NOT the last record
                if index < records.count - 1 {
                    let sepContainer = UIView()
                    let separator = UIView()
                    separator.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
                    separator.translatesAutoresizingMaskIntoConstraints = false
                    separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                    
                    sepContainer.addSubview(separator)
                    sepContainer.translatesAutoresizingMaskIntoConstraints = false
                    
                    NSLayoutConstraint.activate([
                        separator.trailingAnchor.constraint(equalTo: sepContainer.trailingAnchor),
                        separator.leadingAnchor.constraint(equalTo: sepContainer.leadingAnchor, constant: 16),
                        separator.topAnchor.constraint(equalTo: sepContainer.topAnchor),
                        separator.bottomAnchor.constraint(equalTo: sepContainer.bottomAnchor)
                    ])
                    stackView.addArrangedSubview(sepContainer)
                }
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
