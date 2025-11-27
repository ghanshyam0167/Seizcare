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
    
    
    @IBOutlet weak var pipeLabel3: UILabel!
    @IBOutlet weak var pipeLabel2: UILabel!
    @IBOutlet weak var pipeLabel1: UILabel!
    @IBOutlet weak var pipeLabel0: UILabel!
    
    @IBOutlet weak var seizureDetectedRecordLabel01: UILabel!
    @IBOutlet weak var sleepRecordLabel01: UILabel!
    @IBOutlet weak var spo2RecordLabel01: UILabel!
    @IBOutlet weak var dateRecordLabel01: UILabel!
    @IBOutlet weak var seizureDetectedRecordLabel00: UILabel!
    @IBOutlet weak var sleepRecordLabel00: UILabel!
    @IBOutlet weak var spo2RecordLabel00: UILabel!
    @IBOutlet weak var dateRecordLabel00: UILabel!
    
    var user : User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        applySectionSpacing()
        
        pipeLabel0.setContentHuggingPriority(.required, for: .horizontal)
        pipeLabel1.setContentHuggingPriority(.required, for: .horizontal)
        
        pipeLabel2.setContentHuggingPriority(.required, for: .horizontal)
        pipeLabel3.setContentHuggingPriority(.required, for: .horizontal)
        
        
        [currentCardView0, currentCardView1, currentCardView2, currentCardView3,
             recordsCardView, bottomCardView0, bottomCardView1].forEach {
                $0?.applyDashboardCard()
            }
            [recordCardView0, recordCardView1].forEach {
                $0?.applyRecordCard()
            }
        
        weeklyMonthlySegment.applyPrimaryStyle()
        updateRecentRecords()
        
    }
    func updateUI(){
        let user = UserDataModel.shared.getCurrentUser()
        guard let user else {return}
        
        let fullName = user.fullName
        let firstName = fullName.split(separator: " ").first.map(String.init) ?? fullName

        navigationItem.title = "Hey \(firstName)" 
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRecentRecords()
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
        
        // Seizure Type
        seizureLabel.text = "Seizure: " + (record.type?.rawValue.capitalized ?? "-")
        
        
        // Duration
        if let duration = record.duration {
            let mins = Int(duration) / 60
            let secs = Int(duration) % 60
            sleepLabel.text = "Duration: \(mins)m \(secs)s"
        } else {
            sleepLabel.text = "Duration: --"
        }
        
        
        // SPO2 OR Title
        if record.entryType == .automatic {
            // Automatic record shows SPO2
            spo2Label.text = "SPO₂: \(record.spo2 ?? 0)%"
        } else {
            // Manual record shows Title
            spo2Label.text = "Title: \(record.title?.capitalized ?? "-")"
        }
        
        
        // Date
        dateLabel.text = DateFormats.fullDate.string(from: record.dateTime)

    }

    
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
    // Section Spacing for STATIC TABLE VIEW
    
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {

        if section == 0 {
            return UITableView.automaticDimension
        }
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {

        if section == 0 {
            return nil
        }

        let spacer = UIView()
        spacer.backgroundColor = .clear
        return spacer
    }

   
    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            viewForFooterInSection section: Int) -> UIView? {
        let spacer = UIView()
        spacer.backgroundColor = .clear
        return spacer
    }
}
