//
//  DetailRecordsTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

class DetailRecordsTableViewController: UITableViewController {

    @IBOutlet weak var locationValueLabel: UILabel!
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var heartRateValueLabel: UILabel!
    @IBOutlet weak var heartRateTitleLabel: UILabel!
    @IBOutlet weak var spo2ValueLabel: UILabel!
    @IBOutlet weak var spo2TitleLabel: UILabel!
    @IBOutlet weak var durationTitleLabel: UILabel!
    @IBOutlet weak var durationValueLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seizureLevelLabel: UILabel!
    
    var record: Record?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let record = record else {
            print("data not coming")
            return }

           seizureLevelLabel.text = record.title
           durationValueLabel.text = record.duration
           dateLabel.text = record.date
           spo2ValueLabel.text = "\(record.spo2)%"
           heartRateValueLabel.text = "\(record.heartRate) bpm"
           locationValueLabel.text = record.location
    
    }

}
