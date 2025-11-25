//
//  DetailRecordsTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

class DetailRecordsTableViewController: UITableViewController {

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var bottomCardView: UIView!
    @IBOutlet weak var topCardView: UIView!
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
    
    var onDismiss: (() -> Void)?
    var record: SeizureRecord?

        override func viewDidLoad() {
            super.viewDidLoad()
            [topCardView, bottomCardView].forEach { view in
                    view?.applyCardStyle()
                }
            descriptionTextView.delegate = self


            guard let record = record else {
                print("❌ No record passed!")
                return
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, hh:mm a"
            dateLabel.text = formatter.string(from: record.dateTime)

            if record.entryType == .automatic {
                configureAutomatic(record)
            } else {
                configureManual(record)
            }
        }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Force end editing (calls textViewDidEndEditing)
        view.endEditing(true)
        
        // Save description even if delegate didn’t fire
        if let updatedText = descriptionTextView.text,
           let record = record {
            
            SeizureRecordDataModel.shared.updateRecordDescription(
                id: record.id,
                newDescription: updatedText
            )
            
            self.record?.description = updatedText
            onDismiss?()
            print("✅ Saved on viewWillDisappear")
        }
    }


        // MARK: - Automatic record display
        func configureAutomatic(_ record: SeizureRecord) {

            seizureLevelLabel.text = record.type?.rawValue.capitalized

            durationTitleLabel.text = "Duration"
            durationValueLabel.text = record.duration != nil ? formatDuration(record.duration!) : "--"
            
            spo2TitleLabel.text = "SpO₂"
            spo2ValueLabel.text = record.spo2 != nil ? "\(record.spo2!)%" : "--"
            
            heartRateTitleLabel.text = "Heart Rate"
            heartRateValueLabel.text = record.heartRate != nil ? "\(record.heartRate!) bpm" : "--"
            
            locationTitleLabel.text = "Location"
            locationValueLabel.text = record.location ?? "--"
            
            descriptionTextView.text = record.description
        }

        // MARK: - Manual record display (same UI, changed meaning)
        func configureManual(_ record: SeizureRecord) {

            seizureLevelLabel.text = record.title ?? "Manual Log"

            durationTitleLabel.text = "Seizure Level"
            durationValueLabel.text = record.type?.rawValue.capitalized ?? "Not available"

            spo2TitleLabel.text = "Symptoms"
            if let symptoms = record.symptoms, !symptoms.isEmpty {
                spo2ValueLabel.text = symptoms.joined(separator: ", ")
            } else {
                spo2ValueLabel.text = "None"
            }

            heartRateTitleLabel.text = "Duration"

            if let dur = record.duration {
                heartRateValueLabel.text = formatDuration(dur)
            } else {
                heartRateValueLabel.text = "No duration"
            }

            locationTitleLabel.text = "Entry Type"
            locationValueLabel.text = "Manual"
            
            descriptionTextView.text = record.description
        }

        func formatDuration(_ seconds: TimeInterval) -> String {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins) min \(secs) sec"
        }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.1 : 6   // first section + others
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 2   // space between sections
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 16, bottom: 2, right: 16)
    }
    func refreshUI() {
        guard let record = record else { return }
        descriptionTextView.text = record.description
    }

    }

extension DetailRecordsTableViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let updatedText = textView.text,
              let record = record else { return }

        // Update in your data model
        SeizureRecordDataModel.shared.updateRecordDescription(id: record.id, newDescription: updatedText)

        print("✅ Description updated for record:", record.id)
        self.record?.description = updatedText
        refreshUI()
    }

}
