//
//  DashboardTableViewController.swift
//  Seizcare
//
//  Created by GS Agrawal on 24/11/25.
//

import UIKit

class DashboardTableViewController: UITableViewController {

    @IBOutlet weak var weeklyMonthlySegment: UISegmentedControl!
    @IBOutlet weak var recordCardView1: UIView!
    @IBOutlet weak var recordCardView0: UIView!
    @IBOutlet weak var bottomCardView1: UIView!
    @IBOutlet weak var bottomCardView0: UIView!
    @IBOutlet weak var recordsCardView: UIView!
    @IBOutlet weak var currentCardView3: UIView!
    @IBOutlet weak var currentCardView2: UIView!
    @IBOutlet weak var currentCardView1: UIView!
    @IBOutlet weak var currentCardView0: UIView!
    
    
    @IBOutlet weak var seizureDetectedRecordLabel01: UILabel!
    @IBOutlet weak var sleepRecordLabel01: UILabel!
    @IBOutlet weak var spo2RecordLabel01: UILabel!
    @IBOutlet weak var dateRecordLabel01: UILabel!
    @IBOutlet weak var seizureDetectedRecordLabel00: UILabel!
    @IBOutlet weak var sleepRecordLabel00: UILabel!
    @IBOutlet weak var spo2RecordLabel00: UILabel!
    @IBOutlet weak var dateRecordLabel00: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDataModel.shared.loginUser(email: "ghanshyam@example.com", password: "password121")
        
        [currentCardView0, currentCardView1, currentCardView2, currentCardView3,
             recordsCardView, bottomCardView0, bottomCardView1].forEach { view in
                view?.applyCardStyle()
            }
        [recordCardView0, recordCardView1].forEach { card in
                card?.applyRecordCardStyle()
            }
        styleSegmentControl()
        updateRecentRecords()
      
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRecentRecords()
    }

    func styleSegmentControl() {
        // Background of entire segmented control
        weeklyMonthlySegment.backgroundColor = UIColor(red: 237/255, green: 237/255, blue: 242/255, alpha: 1)
        weeklyMonthlySegment.selectedSegmentTintColor = .white

        // Corner radius
        weeklyMonthlySegment.layer.cornerRadius = 16
        weeklyMonthlySegment.layer.masksToBounds = true

        // Text attributes
        let normalText = [NSAttributedString.Key.foregroundColor: UIColor.black,
                          .font: UIFont.systemFont(ofSize: 16, weight: .medium)]
        let selectedText = [NSAttributedString.Key.foregroundColor: UIColor(red: 36/255, green: 104/255, blue: 244/255, alpha: 1),
                            .font: UIFont.systemFont(ofSize: 16, weight: .medium)]

        weeklyMonthlySegment.setTitleTextAttributes(normalText, for: .normal)
        weeklyMonthlySegment.setTitleTextAttributes(selectedText, for: .selected)
    }
    func updateRecentRecords() {
        let recent = SeizureRecordDataModel.shared.getLatestTwoRecordsForCurrentUser()

        // No records → hide both cards
        if recent.isEmpty {
            recordCardView0.isHidden = true
            recordCardView1.isHidden = true
            return
        }

        // If only ONE record
        if recent.count == 1 {
            let r0 = recent[0]
            updateCard(
                record: r0,
                seizureLabel: seizureDetectedRecordLabel00,
                sleepLabel: sleepRecordLabel00,
                spo2Label: spo2RecordLabel00,
                dateLabel: dateRecordLabel00
            )
            recordCardView0.isHidden = false
            recordCardView1.isHidden = true
            return
        }

        // If TWO records
        let r0 = recent[0]
        let r1 = recent[1]

        updateCard(
            record: r0,
            seizureLabel: seizureDetectedRecordLabel00,
            sleepLabel: sleepRecordLabel00,
            spo2Label: spo2RecordLabel00,
            dateLabel: dateRecordLabel00
        )

        updateCard(
            record: r1,
            seizureLabel: seizureDetectedRecordLabel01,
            sleepLabel: sleepRecordLabel01,
            spo2Label: spo2RecordLabel01,
            dateLabel: dateRecordLabel01
        )

        recordCardView0.isHidden = false
        recordCardView1.isHidden = false
    }


    

    func updateCard(record: SeizureRecord,
                    seizureLabel: UILabel,
                    sleepLabel: UILabel,
                    spo2Label: UILabel,
                    dateLabel: UILabel) {
        
        // For seizure level:
        if record.entryType == .automatic {
            seizureLabel.text = record.type?.rawValue.capitalized ?? "Automatic"
        } else {
            seizureLabel.text = record.title ?? "Manual Log"
        }

        // Duration (sleep label)
        if let duration = record.duration {
            let mins = Int(duration) / 60
            let secs = Int(duration) % 60
            sleepLabel.text = "Sleep: \(mins)m \(secs)s"
        } else {
            sleepLabel.text = "--"
        }

        // SpO2
        spo2Label.text = record.spo2 != nil ? "SPO2: \(record.spo2!)%" : "--"

        // Date
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        dateLabel.text = df.string(from: record.dateTime)
    }


}
extension UIView {
    func applyCardStyle() {
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        self.layer.borderWidth = 0.6
        self.backgroundColor = .white
        
        // Smooth shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.08
        self.layer.shadowRadius = 12
        self.layer.shadowOffset = CGSize(width: 0, height: 6)
    }
    
    func applyRecordCardStyle() {
           self.backgroundColor = .white
           self.layer.cornerRadius = 14
           self.layer.masksToBounds = false

           // Thin border
           self.layer.borderWidth = 1.0
           self.layer.borderColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1.0).cgColor
           
           // Very soft shadow
           self.layer.shadowColor = UIColor.black.cgColor
           self.layer.shadowOpacity = 0.04
           self.layer.shadowRadius = 4
           self.layer.shadowOffset = CGSize(width: 0, height: 2)
       }
    func applyRecordGroupedStyle() {
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        self.layer.borderWidth = 0.6
        self.backgroundColor = .white
        
        // Same smooth shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.08
        self.layer.shadowRadius = 12
        self.layer.shadowOffset = CGSize(width: 0, height: 6)
    }

}
