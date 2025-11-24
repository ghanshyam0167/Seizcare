//
//  EmergencyContactsTableViewCell.swift
//  Seizcare
//
//  Created by Student on 21/11/25.
//

import UIKit

class EmergencyContactsTableViewCell: UITableViewCell {

    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    override func awakeFromNib() {
            super.awakeFromNib()

            avatarView.layer.cornerRadius = avatarView.frame.size.width / 2
            avatarView.clipsToBounds = true

            initialsLabel.textColor = .white
            initialsLabel.font = .systemFont(ofSize: 16, weight: .semibold)

            nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            phoneLabel.font = .systemFont(ofSize: 14, weight: .regular)
            phoneLabel.textColor = .secondaryLabel
        }

        func configure(with contact: EmergencyContact) {
            nameLabel.text = contact.name
            phoneLabel.text = contact.phone

            initialsLabel.text = initials(from: contact.name)
            avatarView.backgroundColor = colorForName(contact.name)
        }

        private func initials(from name: String) -> String {
            let parts = name.split(separator: " ")
            let letters = parts.compactMap { $0.first }
            return letters.map { String($0) }.joined()
        }

        private func colorForName(_ name: String) -> UIColor {
            let colors = [
                UIColor.systemBlue.withAlphaComponent(0.3),
                UIColor.systemGreen.withAlphaComponent(0.3),
                UIColor.systemYellow.withAlphaComponent(0.3),
                UIColor.systemPurple.withAlphaComponent(0.3),
                UIColor.systemPink.withAlphaComponent(0.3),
                UIColor.systemOrange.withAlphaComponent(0.3)
            ]
            return colors[(name.hashValue & 0x7FFFFFFF) % colors.count]
        }

}
