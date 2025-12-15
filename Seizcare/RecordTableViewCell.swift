//
//  RecordTableViewCell.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

class RecordTableViewCell: UITableViewCell {

    
    @IBOutlet weak var recordIconImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var seizureLevelLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Card style (matches Figma)
        cardView.layer.cornerRadius = 18
        cardView.layer.masksToBounds = false
        cardView.backgroundColor = .white

        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        // Configure the view for the selected state
    }

}
