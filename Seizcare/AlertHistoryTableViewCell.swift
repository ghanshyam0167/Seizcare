//
//  AlertHistoryTableViewCell.swift
//  Seizcare
//
//  Created by Diya Sharma on 21/11/25.
//

import UIKit

class AlertHistoryTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    
    @IBOutlet weak var NotificationLabel: UILabel!
    
    
    @IBOutlet weak var notificationDetailsLabel: UILabel!
    
    
    @IBOutlet weak var timeLabel: UILabel!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
