//
//  DashboardTableViewController.swift
//  Seizcare
//
//  Created by GS Agrawal on 24/11/25.
//

import UIKit
import SwiftUI

class DashboardTableViewController: UITableViewController {

    @IBOutlet weak var TriggerCorrelationChartContainerView: UIView!
    @IBOutlet weak var triggerCorrelationChart: UIView!
    @IBOutlet weak var timePatterChartContainerView: UIView!
    @IBOutlet weak var timePatternChart: UIView!
    @IBOutlet weak var sleepVsSeizureChartContainerView: UIView!
    @IBOutlet weak var sleepVsSeizureChart: UIView!
    @IBOutlet weak var seizureChartBottomMetricsLabel: UILabel!
    @IBOutlet weak var seizureChartBottomIcon: UIImageView!
    @IBOutlet weak var seizureChartLabel: UILabel!
    @IBOutlet weak var periodButton: UIButton!
    @IBOutlet weak var seizureFrequencyChartContainer: UIView!

    @IBOutlet weak var seizureFrequencyChartUpperView: UIView!
    @IBOutlet weak var recordCardView1: UIView!
    @IBOutlet weak var recordCardView0: UIView!
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
    let dashboardModel = DashboardDataModel.shared
    private var currentPeriod: DashboardPeriod = .current

    
    override func viewDidLoad() {
        super.viewDidLoad()


        
        UserDataModel.shared.loginUser(email: "ghanshyam@example.com", password: "password121")
 
        updateUI()
        
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        applySectionSpacing()
        
        pipeLabel0.setContentHuggingPriority(.required, for: .horizontal)
        pipeLabel1.setContentHuggingPriority(.required, for: .horizontal)
        
        pipeLabel2.setContentHuggingPriority(.required, for: .horizontal)
        pipeLabel3.setContentHuggingPriority(.required, for: .horizontal)
        
        
        [currentCardView0, currentCardView1, currentCardView2, currentCardView3,
             recordsCardView, seizureFrequencyChartUpperView,sleepVsSeizureChartContainerView,timePatterChartContainerView,TriggerCorrelationChartContainerView].forEach {
                $0?.applyDashboardCard()
            }
            [recordCardView0, recordCardView1].forEach {
                $0?.applyRecordCard()
            }
        
        updateRecentRecords()
        setupPeriodMenu()
        setupPeriodButton()
        changePeriod(currentPeriod)
        setupSeizureChartTitle()
        setupSeizureChartFooter()
        addSleepVsSeizureChart()
        addTimePatternChart()
        addTriggerCorrelationChart()
    }
    
    
    func addTriggerCorrelationChart() {

        // 1️⃣ Fetch data from model
        let triggerData = dashboardModel.getTriggerCorrelation()

        // Safety check
        guard !triggerData.isEmpty else { return }

        // 2️⃣ Create SwiftUI chart
        let chartView = TriggerCorrelationChart(data: triggerData)

        // 3️⃣ Embed using UIHostingController
        let hostingVC = UIHostingController(rootView: chartView)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        triggerCorrelationChart.addSubview(hostingVC.view)

        NSLayoutConstraint.activate([
            hostingVC.view.leadingAnchor.constraint(equalTo: triggerCorrelationChart.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: triggerCorrelationChart.trailingAnchor),
            hostingVC.view.topAnchor.constraint(equalTo: triggerCorrelationChart.topAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: triggerCorrelationChart.bottomAnchor)
        ])

        hostingVC.didMove(toParent: self)
    }

    func addTimePatternChart() {

        let data = dashboardModel.getTimeOfDayPattern(months: 3)

        let chart = TimePatternChart(data: data)
        let hostingVC = UIHostingController(rootView: chart)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        timePatternChart.addSubview(hostingVC.view)

        NSLayoutConstraint.activate([
            hostingVC.view.leadingAnchor.constraint(equalTo: timePatternChart.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: timePatternChart.trailingAnchor),
            hostingVC.view.topAnchor.constraint(equalTo: timePatternChart.topAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: timePatternChart.bottomAnchor)
        ])

        hostingVC.didMove(toParent: self)
    }

    func addSleepVsSeizureChart() {

        let data = dashboardModel.getSleepVsSeizure()

        let chart = SleepVsSeizureChart(data: data)
        let hostingVC = UIHostingController(rootView: chart)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        sleepVsSeizureChart.addSubview(hostingVC.view)

        NSLayoutConstraint.activate([
            hostingVC.view.leadingAnchor.constraint(equalTo: sleepVsSeizureChart.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: sleepVsSeizureChart.trailingAnchor),
            hostingVC.view.topAnchor.constraint(equalTo: sleepVsSeizureChart.topAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: sleepVsSeizureChart.bottomAnchor)
        ])

        hostingVC.didMove(toParent: self)
    }


    func setupSeizureChartFooter() {

        let currentAvg = dashboardModel.getCurrentPeriodAverage(period: currentPeriod)
        let previousAvg = dashboardModel.getPreviousPeriodAverage(period: currentPeriod)

        let insight = SeizureInsightGenerator.generate(
            current: currentAvg,
            previous: previousAvg,
            period: currentPeriod
        )

        // ---------- ICON ----------
        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: 14,
            weight: .semibold,
            scale: .medium
        )

        seizureChartBottomIcon.image = UIImage(
            systemName: insight.iconName,
            withConfiguration: symbolConfig
        )?.withRenderingMode(.alwaysTemplate)

        seizureChartBottomIcon.tintColor = insight.color
        seizureChartBottomIcon.contentMode = .scaleAspectFit

        // ---------- LABEL ----------
        seizureChartBottomMetricsLabel.text = insight.text
        seizureChartBottomMetricsLabel.font =
            UIFont.systemFont(ofSize: 14, weight: .medium)
        seizureChartBottomMetricsLabel.textColor =
            UIColor.darkGray.withAlphaComponent(0.9)
        seizureChartBottomMetricsLabel.numberOfLines = 0
    }


    func setupSeizureChartTitle() {
        seizureChartLabel.text = "Seizure Frequency"
        seizureChartLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        seizureChartLabel.textColor = UIColor.darkGray
        seizureChartLabel.numberOfLines = 1
    }

    func setupPeriodButton() {
        periodButton.setTitle(currentPeriod.title, for: .normal)
        periodButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)

        periodButton.semanticContentAttribute = .forceRightToLeft
        periodButton.tintColor = .darkGray
        periodButton.setTitleColor(.darkGray, for: .normal)

        periodButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        periodButton.contentEdgeInsets = UIEdgeInsets(
            top: 4,
            left: 8,
            bottom: 4,
            right: 8
        )

        periodButton.showsMenuAsPrimaryAction = true
    }


    func changePeriod(_ period: DashboardPeriod) {
        currentPeriod = period
        periodButton.setTitle(period.title, for: .normal)
        updatePeriod(period)
        setupPeriodMenu()
        setupSeizureChartFooter()
    }

    func setupPeriodMenu() {
        let daily = UIAction(
            title: "Daily",
            state: currentPeriod == .current ? .on : .off
        ) { _ in
            self.changePeriod(.current)
        }

        let weekly = UIAction(
            title: "Weekly",
            state: currentPeriod == .weekly ? .on : .off
        ) { _ in
            self.changePeriod(.weekly)
        }

        let monthly = UIAction(
            title: "Monthly",
            state: currentPeriod == .monthly ? .on : .off
        ) { _ in
            self.changePeriod(.monthly)
        }

        periodButton.menu = UIMenu(children: [daily, weekly, monthly])
    }

    
    func updatePeriod(_ period: DashboardPeriod) {

        // Remove old chart
        seizureFrequencyChartContainer.subviews.forEach {
            $0.removeFromSuperview()
        }

        // Add new chart for selected period
        addSeizureFrequencyChart(period: period)
    }



    func addSeizureFrequencyChart(period: DashboardPeriod) {

        let data = dashboardModel.getSeizureFrequency(period: period)
        let sortedData = data.sorted { $0.date < $1.date }

        let chartView = SeizureFrequencyChart(
            data: sortedData,
            period: period
        )

        let hostingVC = UIHostingController(rootView: chartView)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        seizureFrequencyChartContainer.addSubview(hostingVC.view)

        NSLayoutConstraint.activate([
            hostingVC.view.leadingAnchor.constraint(equalTo: seizureFrequencyChartContainer.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: seizureFrequencyChartContainer.trailingAnchor),
            hostingVC.view.topAnchor.constraint(equalTo: seizureFrequencyChartContainer.topAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: seizureFrequencyChartContainer.bottomAnchor)
        ])

        hostingVC.didMove(toParent: self)
    }

    func debugDashboardData() {

            print("\n================ DASHBOARD DEBUG ================\n")

            // ------------------------------
            // TOP 4 CARDS
            // ------------------------------
            let summary = dashboardModel.getDashboardSummary()

            print("📊 DASHBOARD SUMMARY")
            print("Avg Monthly Seizures:", summary.avgMonthlySeizures)
            print("Most Common Time:", summary.mostCommonTime.rawValue)
            print("Avg Duration (sec):", summary.avgDuration)
            print("Avg Sleep (hrs):", summary.avgSleepHours)

            print("\n-----------------------------------------------\n")

            // ------------------------------
            // SEIZURE FREQUENCY
            // ------------------------------
            print("📈 DAILY FREQUENCY")
            dashboardModel.getDailyFrequency().forEach {
                print("Date:", $0.date, "| Count:", $0.count)
            }

            print("\n📈 WEEKLY FREQUENCY")
            dashboardModel.getWeeklyFrequency().forEach {
                print("Week Start:", $0.date, "| Count:", $0.count)
            }

            print("\n📈 MONTHLY FREQUENCY")
            dashboardModel.getMonthlyFrequency().forEach {
                print("Month Start:", $0.date, "| Count:", $0.count)
            }

            print("\n-----------------------------------------------\n")

            // ------------------------------
            // TIME OF DAY PATTERN
            // ------------------------------
            print("🕒 TIME OF DAY PATTERN")
            dashboardModel.getTimeOfDayPattern().forEach {
                print("Bucket:", $0.bucket.rawValue, "| Count:", $0.count)
            }

            print("\n-----------------------------------------------\n")

            // ------------------------------
            // SLEEP VS SEIZURE
            // ------------------------------
            print("😴 SLEEP VS SEIZURE")
            dashboardModel.getSleepVsSeizure().forEach {
                print(
                    "Date:", $0.date,
                    "| Sleep:", String(format: "%.1f", $0.sleepHours),
                    "| Seizures:", $0.seizureCount
                )
            }

            print("\n-----------------------------------------------\n")

            // ------------------------------
            // TRIGGER CORRELATION
            // ------------------------------
            print("⚠️ TRIGGER CORRELATION")
            dashboardModel.getTriggerCorrelation().forEach {
                print(
                    "Trigger:", $0.trigger.rawValue,
                    "| Percent:", String(format: "%.1f%%", $0.percent)
                )
            }

            print("\n=============== END DEBUG =================\n")
        }
        
    
    func updateUI(){
        
//        tableView.estimatedSectionHeaderHeight = 0
//        tableView.estimatedSectionFooterHeight = 0
//        tableView.estimatedRowHeight = 200
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
        
        // MARK: - Seizure Type
        seizureLabel.text = "Seizure: " + (record.type?.rawValue.capitalized ?? "-")
        
        
        // MARK: - Duration
        if let duration = record.duration {
            let mins = Int(duration) / 60
            let secs = Int(duration) % 60
            sleepLabel.text = "Duration: \(mins)m \(secs)s"
        } else {
            sleepLabel.text = "Duration: --"
        }
        
        
        // MARK: - SPO2 OR Title
        if record.entryType == .automatic {
            // Automatic record shows SPO2
            spo2Label.text = "SPO₂: \(record.spo2 ?? 0)%"
        } else {
            // Manual record shows Title
            spo2Label.text = "Title: \(record.title?.capitalized ?? "-")"
        }
        
        
        // MARK: - Date
        dateLabel.text = DateFormats.fullDate.string(from: record.dateTime)

    }

    
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
    // MARK: - Section Spacing for STATIC TABLE VIEW
    // SECTION HEADER HEIGHT
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {

        if section == 0 {
            return UITableView.automaticDimension   // allow “Current Status” to show normally
        }
        return 2   // spacing above all other sections
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    // FOOTER (space below each section)
    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        return 2
    }
//
    override func tableView(_ tableView: UITableView,
                            viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension DashboardPeriod {
    var title: String {
        switch self {
        case .current:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }
}
