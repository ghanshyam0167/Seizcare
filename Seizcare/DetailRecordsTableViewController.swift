//
//  DetailRecordsTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit
import Charts
import SwiftUI
import HealthKit

class DetailRecordsTableViewController: UITableViewController {

    @IBOutlet weak var spo2ChartCell: UITableViewCell!
    @IBOutlet weak var heartRateChartCell: UITableViewCell!

    @IBOutlet weak var heartRateTimelineContainerView: UIView!
    @IBOutlet weak var spo2ChartContainerView: UIView!
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
    private var isManualRecord = false
    var shouldHideSection: Bool {
        return record?.entryType == .manual
    }



    private var hrChartHost: UIHostingController<HeartRateTimelineChart>?

        override func viewDidLoad() {
            super.viewDidLoad()
            
            if #available(iOS 15.0, *) {
                    tableView.sectionHeaderTopPadding = 0
                }
            configureNavigationBarButton()
            applyDefaultTableBackground()
            navigationController?.applyWhiteNavBar()
            
            [bottomCardView, mainDetailsCardView, heartRateTimelineContainerView].forEach { view in
                view?.applyDashboardCard()
            }
            topCardView?.backgroundColor = .clear
            descriptionTextView.delegate = self
            
            // Configure dynamic label sizing
            configureDynamicLabels()
            refineDetailsTypographyAndStyles()
            
            // Enable automatic cell height
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 300
            
            applyRecord()

        }
    
    private func configureDynamicLabels() {

        //  Title Labels (Fixed Width + High Priority)
        let titleLabels = [
            durationTitleLabel,
            spo2TitleLabel,
            heartRateTitleLabel,
            locationTitleLabel
        ]

        titleLabels.forEach { label in
            guard let label else { return }

            label.numberOfLines = 1

            //  Give titles a fixed width (critical)
            if label.constraints.first(where: { $0.firstAttribute == .width }) == nil {
                label.widthAnchor.constraint(equalToConstant: 120).isActive = true
            }

            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.setContentHuggingPriority(.required, for: .horizontal)
        }


        // MARK: - Value Labels (Flexible + Multiline)
        let valueLabels = [
            durationValueLabel,
            spo2ValueLabel,
            heartRateValueLabel,
            locationValueLabel
        ]

        valueLabels.forEach { label in
            guard let label else { return }

            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.textAlignment = .right

            // Allow horizontal expansion
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)

            // Prevent vertical squishing
            label.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        //  Important: Remove any fixed height constraints
        (titleLabels + valueLabels).forEach { label in
            guard let label else { return }
            label.constraints.forEach { constraint in
                if constraint.firstAttribute == .height {
                    label.removeConstraint(constraint)
                }
            }
        }
    }

    private func refineDetailsTypographyAndStyles() {
        // 1. Titles / Section Labels
        let labelFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let labelColor = UIColor(red: 44/255.0, green: 44/255.0, blue: 46/255.0, alpha: 1.0) // #2C2C2E
        
        [durationTitleLabel, spo2TitleLabel, heartRateTitleLabel, locationTitleLabel].forEach { lbl in
            lbl?.font = labelFont
            lbl?.textColor = labelColor
        }
        
        // 2. Values
        let valueFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        let valueColor = UIColor(red: 58/255.0, green: 58/255.0, blue: 60/255.0, alpha: 1.0) // #3A3A3C
        
        [durationValueLabel, spo2ValueLabel, heartRateValueLabel, locationValueLabel].forEach { lbl in
            lbl?.font = valueFont
            lbl?.textColor = valueColor
        }
        
        // Notes text view
        descriptionTextView?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        
        // 6. Top Card 
        seizureLevelLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        seizureLevelLabel?.textColor = UIColor.label
        
        dateLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dateLabel?.textColor = UIColor.secondaryLabel
        
        // 3. Layout Spacing
        [mainDetailsCardView, topCardView, bottomCardView].forEach { card in
            guard let card = card else { return }
            increaseStackViewSpacing(in: card)
        }
    }

    private func increaseStackViewSpacing(in view: UIView) {
        for subview in view.subviews {
            if let stack = subview as? UIStackView {
                if stack.axis == .vertical && stack.spacing < 14 {
                    stack.spacing = 16
                }
            }
            increaseStackViewSpacing(in: subview)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        [mainDetailsCardView, bottomCardView, topCardView].forEach { card in
            guard let card = card else { return }
            adjustDividersAndMiscLabels(in: card)
        }
    }

    private func adjustDividersAndMiscLabels(in view: UIView) {
        for subview in view.subviews {
            // Divider Lines condition
            if subview.frame.height > 0 && subview.frame.height <= 2.0 && subview.backgroundColor != .clear && !(subview is UILabel) && !(subview is UITextView) && !(subview is UIImageView) {
                subview.backgroundColor = UIColor(white: 0.65, alpha: 0.25)
                for constraint in subview.constraints where constraint.firstAttribute == .height {
                    constraint.constant = 0.5
                }
            }
            
            // Notes Label condition
            if let lbl = subview as? UILabel, lbl.text == "Notes" || lbl.text == "Description" {
                lbl.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                lbl.textColor = UIColor(red: 44/255.0, green: 44/255.0, blue: 46/255.0, alpha: 1.0)
            }
            
            adjustDividersAndMiscLabels(in: subview)
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
            view.endEditing(true)
    }
    private func applyRecord() {
        guard let record else { return }

        isManualRecord = (record.entryType == .manual)

        let formatter = DateFormatter()
        if record.entryType == .manual {
            formatter.dateFormat = "dd MMM yyyy"
        } else {
            formatter.dateFormat = "dd MMM yyyy, hh:mm a"
        }
        dateLabel.text = formatter.string(from: record.dateTime)

        configureNavigationBarButton()

        if record.entryType == .automatic {
            configureAutomatic(record)
        } else {
            configureManual(record)
        }
        setupHeartRateChart(for: record)
        // SpO2 chart section is permanently hidden
        spo2ChartContainerView.isHidden = true

        tableView.reloadData()
    }

    private func configureNavigationBarButton() {
        guard let record else { return }

        if record.entryType == .manual {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Edit",
                style: .plain,
                target: self,
                action: #selector(editTapped)
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(shareTapped)
            )
        }
    }
    @objc private func editTapped() {
        guard let record else { return }

        let storyboard = UIStoryboard(name: "Records", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "AddRecordTableViewController"
        ) as? AddRecordTableViewController else {
            assertionFailure("AddRecordTableViewController not found in Records.storyboard")
            return
        }
                
        vc.recordToEdit = record
        vc.onDismiss = { [weak self] in
            self?.refreshUI()
        }

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }


    @objc private func shareTapped() {
        guard let record else { return }

        let summary = """
        Seizure Record
        Date: \(dateLabel.text ?? "")
        Duration: \(formatDuration(record.duration ?? 0))
        SpO₂: \(record.spo2 ?? 0)%
        Heart Rate: \(record.heartRate ?? 0) bpm
        """

        let vc = UIActivityViewController(
            activityItems: [summary],
            applicationActivities: nil
        )

        present(vc, animated: true)
    }

    private func setupHeartRateChart(for record: SeizureRecord) {
        let seizureTime = record.dateTime
        let startDate = seizureTime.addingTimeInterval(-2 * 3600) // 2 hours before
        let endDate = seizureTime.addingTimeInterval(2 * 3600) // 2 hours after
        let duration = record.duration ?? 60.0
        
        // Temporarily prepare the container while data arrives
        heartRateTimelineContainerView.isHidden = false
        
        HealthKitManager.shared.fetchHeartRateData(from: startDate, to: endDate) { [weak self] samples in
            guard let self = self else { return }
            
            var hrData: [HeartRateTimelinePoint] = []
            let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            
            for sample in samples {
                let bpm = Int(sample.quantity.doubleValue(for: hrUnit))
                let timestamp = sample.startDate
                
                let phase: HeartRatePhase
                if timestamp < seizureTime {
                    phase = .before
                } else if timestamp > seizureTime.addingTimeInterval(duration) {
                    phase = .after
                } else {
                    phase = .during
                }
                
                hrData.append(HeartRateTimelinePoint(timestamp: timestamp, bpm: bpm, phase: phase))
            }
            
            // Fallback for simulators or profiles without permissions/data
            if hrData.isEmpty {
                hrData = HeartRateTimelineBuilder.generateTimeline(for: record)
            }
            
            guard !hrData.isEmpty else {
                self.hideHeartRateChart()
                return
            }
            
            let chartView = HeartRateTimelineChart(
                data: hrData,
                seizureTime: seizureTime,
                seizureDuration: duration,
                recordedPeak: record.heartRate
            )
            
            let host = UIHostingController(rootView: chartView)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.view.backgroundColor = UIColor.clear
            
            // Clean previous chart
            self.hrChartHost?.view.removeFromSuperview()
            self.hrChartHost?.removeFromParent()
            
            self.hrChartHost = host
            self.addChild(host)
            self.heartRateTimelineContainerView.addSubview(host.view)
            
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: self.heartRateTimelineContainerView.topAnchor),
                host.view.leadingAnchor.constraint(equalTo: self.heartRateTimelineContainerView.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: self.heartRateTimelineContainerView.trailingAnchor),
                host.view.bottomAnchor.constraint(equalTo: self.heartRateTimelineContainerView.bottomAnchor),
                host.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 320)
            ])
            
            host.didMove(toParent: self)
            
            // Force the UITableView to recalculate its AutoLayout dimensions asynchronously
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }
    private func hideHeartRateChart() {
        heartRateTimelineContainerView.isHidden = true
    }






        //  Automatic record display
        func configureAutomatic(_ record: SeizureRecord) {
            seizureLevelLabel.isHidden = false
            seizureLevelLabel.text = record.type?.rawValue.capitalized

            durationTitleLabel.text = "Duration"
            durationValueLabel.text = record.duration != nil ? formatDuration(record.duration!) : "--"
            
            spo2TitleLabel.text = "SpO₂"
            spo2ValueLabel.text = record.spo2 != nil ? "\(record.spo2!)%" : "--"
            
            heartRateTitleLabel.text = "Heart Rate"
            heartRateValueLabel.text = record.heartRate != nil ? "\(record.heartRate!) bpm" : "--"
            
            locationTitleLabel.text = "Location"
            locationValueLabel.text = record.location ?? "--"
            
            if let desc = record.description, !desc.isEmpty {
                descriptionTextView.text = desc
                descriptionTextView.textColor = .label
            } else {
                descriptionTextView.text = placeholderText
                descriptionTextView.textColor = .tertiaryLabel
            }
        }

        //  Manual record display (same UI, changed meaning)
        func configureManual(_ record: SeizureRecord) {

            seizureLevelLabel.isHidden = true
            dateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            dateLabel.textColor = .label

            durationTitleLabel.text = "Seizure Level"
            durationValueLabel.text = record.type?.rawValue.capitalized ?? "Not available"

            spo2TitleLabel.text = "Triggers"
            if let triggers = record.triggers, !triggers.isEmpty {
                let names = triggers.map { $0.displayName }
                spo2ValueLabel.text = names.joined(separator: ", ")
            } else {
                spo2ValueLabel.text = "None"
            }

            heartRateTitleLabel.text = "Duration"

            if let dur = record.duration {
                heartRateValueLabel.text = formatDuration(dur)
            } else {
                heartRateValueLabel.text = "No duration"
            }

            locationTitleLabel.text = "Time of Day"
            locationValueLabel.text = record.timeBucket.rawValue.capitalized
            
            if let desc = record.description, !desc.isEmpty {
                descriptionTextView.text = desc
                descriptionTextView.textColor = .label
            } else {
                descriptionTextView.text = placeholderText
                descriptionTextView.textColor = .tertiaryLabel
            }
        }

        func formatDuration(_ seconds: TimeInterval) -> String {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(mins) min \(secs) sec"
        }
    //  Table View Gap Fixes

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hide headers for manual records in sections 2 & 3
        if isManualRecord && (section == 2 || section == 3) {
            return CGFloat.leastNonzeroMagnitude
        }
        if !isManualRecord && (section == 5){
            return CGFloat.leastNonzeroMagnitude
        }
        return 3
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Hide footers for manual records in sections 2 & 3
        if isManualRecord && (section == 2 || section == 3) {
            return CGFloat.leastNonzeroMagnitude
        }
        if !isManualRecord && (section == 5){
            return CGFloat.leastNonzeroMagnitude
        }
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isManualRecord && (section == 2 || section == 3) {
            return 0
        }
        if !isManualRecord && (section == 5){
            return 0
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    // Ensure you aren't accidentally returning views for the hidden sections
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }


    func refreshUI() {
        guard let r = record else { return }
           record = SeizureRecordDataModel.shared
               .getAllRecords()
               .first { $0.id == r.id }

           applyRecord()
    }
    
    @IBAction func deleteRecordButtonTapped(_ sender: Any) {
            guard let record = record else { return }

            let alert = UIAlertController(
                title: "Delete Record",
                message: "Are you sure you want to delete this record? This action cannot be undone.",
                preferredStyle: .alert
            )

            //  Cancel
            alert.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel
            ))

            //  Delete
            alert.addAction(UIAlertAction(
                title: "Delete",
                style: .destructive,
                handler: { [weak self] _ in
                    guard let self else { return }

                    // Find index safely
                    let records = SeizureRecordDataModel.shared.getAllRecords()
                    if let index = records.firstIndex(where: { $0.id == record.id }) {
                        SeizureRecordDataModel.shared.deleteRecord(at: index)
                    }

                    // Notify parent (records list)
                    self.onDismiss?()

                    // Close details screen
                    self.navigationController?.popViewController(animated: true)
                }
            ))

            present(alert, animated: true)
    }
    
}

    private let placeholderText = "Add your notes here..."



extension DetailRecordsTableViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText && textView.textColor == .tertiaryLabel {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let record = record else { return }
        
        // Trim whitespace
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Determine what to save
        // If text is empty OR text is the placeholder, save as empty string/nil logic
        let finalText: String
        if trimmedText.isEmpty || (textView.text == placeholderText && textView.textColor == .tertiaryLabel) {
            finalText = ""
            // Restore placeholder
            textView.text = placeholderText
            textView.textColor = .tertiaryLabel
        } else {
            finalText = trimmedText
        }

        SeizureRecordDataModel.shared.updateRecordDescription(
            id: record.id,
            newDescription: finalText
        )

        self.record?.description = finalText
        onDismiss?()
    }
}
