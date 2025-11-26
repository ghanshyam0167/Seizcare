//
//  DetailRecordsTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

class DetailRecordsTableViewController: UITableViewController {

    
    @IBOutlet weak var mapWrapperView: UIView!
    @IBOutlet weak var mainDetailsCardView: UIView!
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
    var shouldHideSection1: Bool {
        return record?.entryType == .manual
    }


        override func viewDidLoad() {
            super.viewDidLoad()
            applyDefaultTableBackground()
            navigationController?.applyWhiteNavBar()
            
            [topCardView, bottomCardView, mainDetailsCardView].forEach { view in
                view?.applyDashboardCard()
                }
            descriptionTextView.delegate = self
            mapWrapperView.layer.cornerRadius = 16
            mapWrapperView.clipsToBounds = true
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
    // MARK: - Section spacing & hiding (clean)
    private func refreshSectionVisibility(animated: Bool = false) {
        // If record changed after view loaded, force the table to recompute heights.
        let sectionSet = IndexSet(integer: 1)
        if animated {
            tableView.performBatchUpdates({
                tableView.reloadSections(sectionSet, with: .automatic)
            }, completion: nil)
        } else {
            tableView.reloadSections(sectionSet, with: .none)
        }
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        // hide section 1 when needed
        if shouldHideSection1 && section == 1 { return 0.01 }
        return section == 0 ? 0.01 : 2
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        if shouldHideSection1 && section == 1 { return UIView() }
        let v = UIView(); v.backgroundColor = .clear; return v
    }

    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        if shouldHideSection1 && section == 1 { return 0.01 }
        return 2
    }

    override func tableView(_ tableView: UITableView,
                            viewForFooterInSection section: Int) -> UIView? {
        if shouldHideSection1 && section == 1 { return UIView() }
        let v = UIView(); v.backgroundColor = .clear; return v
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if shouldHideSection1 && indexPath.section == 1 { return 0.01 }
        return UITableView.automaticDimension
    }

    // keep willDisplay to tweak visual appearance & remove separators when hidden
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        // content margins + transparent cell background
        cell.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 16, bottom: 2, right: 16)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        if shouldHideSection1 && indexPath.section == 1 {
            // make sure it doesn't show visual artifacts
            cell.isHidden = true
            cell.alpha = 0.0
            cell.selectionStyle = .none
        } else {
            cell.isHidden = false
            cell.alpha = 1.0
            cell.selectionStyle = .default
        }
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
