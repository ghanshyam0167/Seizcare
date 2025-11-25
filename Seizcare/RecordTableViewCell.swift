//
//  RecordTableViewCell.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

class RecordTableViewCell: UITableViewCell {

    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var seizureLevelLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        // Configure the view for the selected state
    }

}
