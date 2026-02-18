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



    private var spo2ChartHost: UIHostingController<SpO2TimelineChart>?
    private var hrChartHost: UIHostingController<HeartRateTimelineChart>?

        override func viewDidLoad() {
            super.viewDidLoad()
            
            if #available(iOS 15.0, *) {
                    tableView.sectionHeaderTopPadding = 0
                }
            configureNavigationBarButton()
            applyDefaultTableBackground()
            navigationController?.applyWhiteNavBar()
            
            [topCardView, bottomCardView, mainDetailsCardView, spo2ChartContainerView, heartRateTimelineContainerView].forEach { view in
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

        // MARK: - Title Labels (Fixed Width + High Priority)
        let titleLabels = [
            durationTitleLabel,
            spo2TitleLabel,
            heartRateTitleLabel,
            locationTitleLabel
        ]

        titleLabels.forEach { label in
            guard let label else { return }

            label.numberOfLines = 1

            // 🔥 Give titles a fixed width (critical)
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

            // 🔥 Allow horizontal expansion
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)

            // Prevent vertical squishing
            label.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        // MARK: - Important: Remove any fixed height constraints
        (titleLabels + valueLabels).forEach { label in
            guard let label else { return }
            label.constraints.forEach { constraint in
                if constraint.firstAttribute == .height {
                    label.removeConstraint(constraint)
                }
            }
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
            setupSpO2Chart(for: record)
            setupHeartRateChart(for: record)
        } else {
            configureManual(record)
            hideSpO2Chart()
            hideHeartRateChart()
        }

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

        guard record.entryType == .automatic else {
            hideHeartRateChart()
            return
        }

        let timeline =
            HeartRateTimelineBuilder.generateTimeline(
                seizureTime: record.dateTime,
                seizureDuration: record.duration ?? 60
            )

        guard !timeline.isEmpty else {
            hideHeartRateChart()
            return
        }

        let chartView = HeartRateTimelineChart(
            data: timeline,
            seizureTime: record.dateTime,
            seizureDuration: record.duration ?? 60
        )

        let host = UIHostingController(rootView: chartView)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear

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


    // MARK: - SpO2 Chart Integration
    private func setupSpO2Chart(for record: SeizureRecord) {

        // Generate record-specific SpO2 timeline
        let timeline =
            SeizureRecordDataModel.shared.getSpO2Timeline(for: record)

        guard !timeline.isEmpty else {
            hideSpO2Chart()
            return
        }

        let chartView = SpO2TimelineChart(
            data: timeline,
            seizureTime: record.dateTime,
            seizureDuration: record.duration ?? 60
        )

        let host = UIHostingController(rootView: chartView)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear

        // Clean previous chart if exists
        spo2ChartHost?.view.removeFromSuperview()
        spo2ChartHost?.removeFromParent()

        spo2ChartHost = host
        addChild(host)
        spo2ChartContainerView.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: spo2ChartContainerView.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: spo2ChartContainerView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: spo2ChartContainerView.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: spo2ChartContainerView.bottomAnchor)
        ])

        host.didMove(toParent: self)

        spo2ChartContainerView.isHidden = false
        
    }
    private func hideSpO2Chart() {
        spo2ChartContainerView.isHidden = true
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
            
            if let desc = record.description, !desc.isEmpty {
                descriptionTextView.text = desc
                descriptionTextView.textColor = .label
            } else {
                descriptionTextView.text = placeholderText
                descriptionTextView.textColor = .tertiaryLabel
            }
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
    // MARK: - Table View Gap Fixes

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

            // ❌ Cancel
            alert.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel
            ))

            // 🗑️ Delete
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
