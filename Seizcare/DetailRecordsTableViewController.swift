//
//  DetailRecordsTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit
import Charts
import SwiftUI

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
            
            [topCardView, bottomCardView, mainDetailsCardView, heartRateTimelineContainerView].forEach { view in
                view?.applyDashboardCard()
                }
            descriptionTextView.delegate = self
            
            // Configure dynamic label sizing
            configureDynamicLabels()
            
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarButton()
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
            setupHeartRateChart(for: record)
        } else {
            configureManual(record)
            hideHeartRateChart()
        }
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
            let shareItem = UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(shareTapped)
            )
            
            // Add Feedback Label option for automatic records if a matching ML session exists
            if let matchingSession = findDetectionSession(for: record) {
                let currentLabelTitle = matchingSession.feedbackLabel?.displayTitle ?? "Add Label"
                let feedbackItem = UIBarButtonItem(
                    title: currentLabelTitle,
                    style: .plain,
                    target: self,
                    action: #selector(feedbackTapped)
                )
                
                // Style it depending on whether we have a label
                if matchingSession.feedbackLabel != nil {
                    feedbackItem.tintColor = .systemGreen
                } else {
                    feedbackItem.tintColor = .systemBlue
                }
                
                navigationItem.rightBarButtonItems = [shareItem, feedbackItem]
            } else {
                navigationItem.rightBarButtonItems = [shareItem]
            }
        }
    }
    
    private func findDetectionSession(for record: SeizureRecord) -> DetectionSession? {
        let sessions = DetectionSessionStore.shared.allSessions()
        var closest: DetectionSession?
        var minDiff: TimeInterval = 300 // within 5 minutes
        for s in sessions {
            let diff = abs(s.timestamp.timeIntervalSince(record.dateTime))
            if diff < minDiff {
                minDiff = diff
                closest = s
            }
        }
        return closest
    }
    
    @objc private func feedbackTapped() {
        guard let record = record, let session = findDetectionSession(for: record) else { return }
        let vc = FeedbackViewController(sessionID: session.id, source: "history", initialLabel: session.feedbackLabel)
        
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        // When feedback is done, it dismisses. We can refresh the UI by adding an observer or just waiting.
        // the easiest way is to add a small delay and refresh, or let the user re-open.
        // Let's add an action handler to vc if it had one, or just refresh on viewWillAppear.
        present(vc, animated: true)
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

        guard record.entryType == .automatic else {
            hideHeartRateChart()
            return
        }

        let hrData = HeartRateTimelineBuilder.generateTimeline(for: record)

        guard !hrData.isEmpty else {
            hideHeartRateChart()
            return
        }

        let chartView = HeartRateTimelineChart(
            data: hrData,
            seizureTime: record.dateTime,
            seizureDuration: record.duration ?? 60
        )

        let host = UIHostingController(rootView: chartView)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = UIColor.clear

        // Clean previous chart
        hrChartHost?.view.removeFromSuperview()
        hrChartHost?.removeFromParent()

        hrChartHost = host
        addChild(host)
        heartRateTimelineContainerView.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: heartRateTimelineContainerView.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: heartRateTimelineContainerView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: heartRateTimelineContainerView.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: heartRateTimelineContainerView.bottomAnchor)
        ])

        host.didMove(toParent: self)
        heartRateTimelineContainerView.isHidden = false
    }
    private func hideHeartRateChart() {
        heartRateTimelineContainerView.isHidden = true
    }






        //  Automatic record display
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

            seizureLevelLabel.text = record.title ?? "Manual Log"

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
