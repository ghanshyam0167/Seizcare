//
//  DashboardTableViewController.swift
//  Seizcare
//
//  Created by GS Agrawal on 24/11/25.
//

import UIKit
import SwiftUI

enum TrendDirection {
    case increased
    case decreased
    case noChange

    var icon: String {
        switch self {
        case .increased: return "↑"
        case .decreased: return "↓"
        case .noChange:  return "→"
        }
    }

    var text: String {
        switch self {
        case .increased: return "increased"
        case .decreased: return "decreased"
        case .noChange:  return "no change"
        }
    }

    var color: UIColor {
        switch self {
        case .increased: return .systemGreen
        case .decreased: return .systemRed
        case .noChange:  return .systemGray
        }
    }
}

class DashboardTableViewController: UITableViewController {
    
    @IBOutlet weak var mostCommonTimeStatusLabel: UILabel!
    @IBOutlet weak var avgDurationStatusLabel: UILabel!
    @IBOutlet weak var avgSeizureStatusLabel: UILabel!
    @IBOutlet weak var sleepDurationStatusLabel: UILabel!
    @IBOutlet weak var mostCommonTimeLabel: UILabel!
    @IBOutlet weak var avgDurationLabel: UILabel!
    @IBOutlet weak var avgMonthlySeizuresLabel: UILabel!
    @IBOutlet weak var sleepDurationLabel: UILabel!
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
    @IBOutlet weak var viewAllButton: UIButton? // Optional to prevent crash if not connected

    
    
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
    
    // MARK: - Records Section — Programmatic Views
    private let recordsHeaderView   = UIView()
    private let recordsTitleLabel   = UILabel()
    private let recordsActionButton = UIButton(type: .system)
    private let emptyStateView      = UIView()
    private let emptyTitleLabel     = UILabel()
    private let emptySubtitleLabel  = UILabel()
    private let emptyAddButton      = UIButton(type: .system)
    // Premium programmatic preview cards (replace storyboard recordCardView0/1)
    private let previewCard0        = UIView()
    private let previewCard1        = UIView()


    var user : User?
    let dashboardModel = DashboardDataModel.shared
    private var currentPeriod: DashboardPeriod = .current

    
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
        
        
        // Chart / records cards keep the original dashboard card style
        [recordsCardView, seizureFrequencyChartUpperView, sleepVsSeizureChartContainerView,
         timePatterChartContainerView, TriggerCorrelationChartContainerView].forEach {
            $0?.applyDashboardCard()
        }
        [recordCardView0, recordCardView1].forEach {
            $0?.applyRecordCard()
        }

        // Four metric cards — each gets a unique subtle tint
        currentCardView0?.applyMetricCard(tint: .systemIndigo)  // Sleep Quality
        currentCardView1?.applyMetricCard(tint: .systemOrange)  // Avg Seizures
        currentCardView2?.applyMetricCard(tint: .systemTeal)    // Avg Duration
        currentCardView3?.applyMetricCard(tint: .systemPurple)  // Most Common Time
        setupInsightsCards()
        setupRecordsSection()
        updateRecordsSection()
        setupPeriodMenu()
        setupPeriodButton()
        changePeriod(currentPeriod)
        setupSeizureChartTitle()
        setupSeizureChartFooter()
        addSleepVsSeizureChart()
        addTimePatternChart()
        addTriggerCorrelationChart()
    }
    
    func trend(current: Double, previous: Double, threshold: Double = 0.01) -> TrendDirection {
        if abs(current - previous) < threshold {
            return .noChange
        }
        return current > previous ? .increased : .decreased
    }
    
    func setupInsightsCards() {

        // ── Typography helpers ─────────────────────────────────────────────
        let titleFont    = UIFont.systemFont(ofSize: 15, weight: .bold)
        let valueFont    = UIFont.systemFont(ofSize: 21, weight: .regular)
        let subtitleFont = UIFont.systemFont(ofSize: 13, weight: .regular)

        // Apply consistent typography to all title/value/subtitle labels
        for label in [sleepDurationLabel, avgMonthlySeizuresLabel,
                      avgDurationLabel, mostCommonTimeLabel] {
            label?.font = valueFont
            label?.textColor = .label
        }
        for label in [sleepDurationStatusLabel, avgSeizureStatusLabel,
                      avgDurationStatusLabel, mostCommonTimeStatusLabel] {
            label?.font = subtitleFont
        }
        for label in [pipeLabel0, pipeLabel1, pipeLabel2, pipeLabel3] {
            label?.font = titleFont
            label?.textColor = .secondaryLabel
        }

        // ── Fetch Data (includes onboarding fallback) ──────────────────────
        let current  = dashboardModel.getDashboardSummary()
        let previous = dashboardModel.getDashboardSummary(forPreviousMonth: true)
        let hasRealRecords = !SeizureRecordDataModel.shared.getRecordsForCurrentUser().isEmpty

        // ── Sleep Quality ──────────────────────────────────────────────────
        sleepDurationLabel.text = "\(current.avgSleepHours.formatted(1)) hrs"
        if hasRealRecords {
            let sleepTrend = trend(current: current.avgSleepHours, previous: previous.avgSleepHours)
            sleepDurationStatusLabel.text      = "\(sleepTrend.icon) vs last month"
            sleepDurationStatusLabel.textColor = sleepTrend.color
        } else {
            sleepDurationStatusLabel.text      = "Based on initial setup"
            sleepDurationStatusLabel.textColor = .secondaryLabel
        }

        // ── Avg Seizures ───────────────────────────────────────────────────
        if current.avgMonthlySeizures > 0 {
            if current.avgMonthlySeizures < 1.0 {
                avgMonthlySeizuresLabel.text = "< 1 / month"
            } else {
                avgMonthlySeizuresLabel.text = "\(Int(current.avgMonthlySeizures)) / month"
            }
        } else {
            avgMonthlySeizuresLabel.text = "None"
        }
        
        if hasRealRecords {
            let seizureTrend = trend(current: current.avgMonthlySeizures, previous: previous.avgMonthlySeizures)
            avgSeizureStatusLabel.text      = "\(seizureTrend.icon) Seizures \(seizureTrend.text)"
            avgSeizureStatusLabel.textColor = seizureTrend.color
        } else {
            avgSeizureStatusLabel.text      = "Based on profile"
            avgSeizureStatusLabel.textColor = .secondaryLabel
        }

        // ── Avg Duration ───────────────────────────────────────────────────
        avgDurationLabel.text = current.avgDuration > 0 ? formatDuration(current.avgDuration) : "None"
        if hasRealRecords {
            let durationTrend = trend(current: current.avgDuration, previous: previous.avgDuration)
            avgDurationStatusLabel.text      = "\(durationTrend.icon) Duration \(durationTrend.text)"
            avgDurationStatusLabel.textColor = durationTrend.color
        } else {
            avgDurationStatusLabel.text      = "Estimated duration"
            avgDurationStatusLabel.textColor = .secondaryLabel
        }

        // ── Most Common Time ───────────────────────────────────────────────
        mostCommonTimeLabel.text = current.mostCommonTime.displayText
        if hasRealRecords {
            if current.mostCommonTime != previous.mostCommonTime {
                mostCommonTimeStatusLabel.text      = "Peak time shifted to \(current.mostCommonTime.displayText)"
                mostCommonTimeStatusLabel.textColor = .systemBlue
            } else {
                mostCommonTimeStatusLabel.text      = "Peak time unchanged"
                mostCommonTimeStatusLabel.textColor = .secondaryLabel
            }
        } else {
            mostCommonTimeStatusLabel.text      = "Common occurrence"
            mostCommonTimeStatusLabel.textColor = .secondaryLabel
        }
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

    func updateUI(){
        let user = UserDataModel.shared.getCurrentUser()
        guard let user else {return}
        
        let fullName = user.fullName
        let firstName = fullName.split(separator: " ").first.map(String.init) ?? fullName

        navigationItem.title = "Hey \(firstName)" 
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRecordsSection()
        setupInsightsCards()
    }

    
    // MARK: - Records Section Setup

    private func setupRecordsSection() {
        // Hide ALL storyboard subviews — we take full control programmatically
        recordsCardView.subviews.forEach { $0.isHidden = true }
        // Clip so nothing escapes the rounded card
        recordsCardView.clipsToBounds = true

        buildRecordsLayout()
        updateRecordsSection()
    }

    /// Builds the Records card layout as a single outer VStack:
    ///
    ///   recordsCardView
    ///     └── outerVStack  (pinned to all 4 edges with 16pt inset)
    ///           ├── headerRow  (Records title | +/View all button)
    ///           └── contentContainer
    ///                 ├── emptyStateView  (hidden when records exist)
    ///                 └── cardsStack      (hidden when no records)
    private func buildRecordsLayout() {

        // ── Header row (22pt semibold, 20pt padding) ──────────────────────
        recordsTitleLabel.text = "Records"
        recordsTitleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        recordsTitleLabel.textColor = .label
        recordsTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        recordsActionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        recordsActionButton.tintColor = .systemBlue
        recordsActionButton.setContentHuggingPriority(.required, for: .horizontal)
        recordsActionButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let headerRow = UIStackView(arrangedSubviews: [recordsTitleLabel, recordsActionButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .fill

        // ── Empty state ───────────────────────────────────────────────────
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 34, weight: .light)
        let iconView   = UIImageView(image: UIImage(systemName: "doc.text", withConfiguration: iconConfig))
        iconView.tintColor = .systemBlue.withAlphaComponent(0.45)
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 42).isActive = true

        emptyTitleLabel.text = "No Records Yet"
        emptyTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        emptyTitleLabel.textColor = .label
        emptyTitleLabel.textAlignment = .center

        emptySubtitleLabel.text = "Add your first seizure record to start tracking."
        emptySubtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emptySubtitleLabel.textColor = .secondaryLabel
        emptySubtitleLabel.textAlignment = .center
        emptySubtitleLabel.numberOfLines = 0

        var btnConfig = UIButton.Configuration.filled()
        btnConfig.title = "+ Add Record"
        btnConfig.baseForegroundColor = .white
        btnConfig.baseBackgroundColor = .systemBlue
        btnConfig.cornerStyle = .capsule
        btnConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24)
        btnConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var b = a; b.font = UIFont.systemFont(ofSize: 15, weight: .semibold); return b
        }
        emptyAddButton.configuration = btnConfig
        emptyAddButton.addTarget(self, action: #selector(addRecordTapped), for: .touchUpInside)

        let emptyVStack = UIStackView(arrangedSubviews: [iconView, emptyTitleLabel, emptySubtitleLabel, emptyAddButton])
        emptyVStack.axis = .vertical
        emptyVStack.alignment = .center
        emptyVStack.spacing = 10
        emptyVStack.setCustomSpacing(16, after: emptySubtitleLabel)

        emptyStateView.addSubview(emptyVStack)
        emptyVStack.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyVStack.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 16),
            emptyVStack.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: -16),
            emptyVStack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyVStack.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor),
            emptyVStack.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor)
        ])

        // ── Premium preview cards ─────────────────────────────────────────
        stylePreviewCard(previewCard0)
        stylePreviewCard(previewCard1)
        previewCard0.isHidden = true
        previewCard1.isHidden = true

        let cardsStack = UIStackView(arrangedSubviews: [previewCard0, previewCard1])
        cardsStack.axis = .vertical
        cardsStack.spacing = 10

        // ── Content container ─────────────────────────────────────────────
        let contentContainer = UIStackView(arrangedSubviews: [emptyStateView, cardsStack])
        contentContainer.axis = .vertical
        contentContainer.spacing = 0

        // ── Outer VStack drives card height ───────────────────────────────
        let outerVStack = UIStackView(arrangedSubviews: [headerRow, contentContainer])
        outerVStack.axis = .vertical
        outerVStack.spacing = 16
        outerVStack.translatesAutoresizingMaskIntoConstraints = false

        recordsCardView.addSubview(outerVStack)
        NSLayoutConstraint.activate([
            outerVStack.topAnchor.constraint(equalTo: recordsCardView.topAnchor, constant: 20),
            outerVStack.leadingAnchor.constraint(equalTo: recordsCardView.leadingAnchor, constant: 20),
            outerVStack.trailingAnchor.constraint(equalTo: recordsCardView.trailingAnchor, constant: -20),
            outerVStack.bottomAnchor.constraint(equalTo: recordsCardView.bottomAnchor, constant: -20)
        ])

        emptyStateView.isHidden = true
    }

    /// Applies the inner rounded card style (Apple Health aesthetic)
    private func stylePreviewCard(_ card: UIView) {
        card.backgroundColor = UIColor.secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.clipsToBounds = false
    }

    /// Populates a preview card with record data using stacked date/severity/duration layout.
    /// Clears previous content each time so it's safe to call repeatedly.
    private func populatePreviewCard(_ card: UIView, record: SeizureRecord) {
        // Remove old content
        card.subviews.forEach { $0.removeFromSuperview() }

        // ── Date label (top, prominent) ───────────────────────────────────
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        dateLabel.text = formatter.string(from: record.dateTime)
        dateLabel.font = .systemFont(ofSize: 17, weight: .medium)
        dateLabel.textColor = .label

        // ── Title / entry type ────────────────────────────────────────────
        let titleLabel = UILabel()
        if record.entryType == .automatic {
            titleLabel.text = "Automatic Detection"
        } else {
            titleLabel.text = record.title?.capitalized ?? "Manual Record"
        }
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .secondaryLabel

        // ── Severity row (colored dot + label) ────────────────────────────
        let severityColor: UIColor
        let severityText: String
        switch record.type {
        case .mild:     severityColor = .systemGreen;  severityText = "Mild"
        case .moderate: severityColor = .systemOrange; severityText = "Moderate"
        case .severe:   severityColor = .systemRed;    severityText = "Severe"
        default:        severityColor = .systemGray;   severityText = "Unknown"
        }

        let dot = UIView()
        dot.backgroundColor = severityColor
        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let severityLabel = UILabel()
        severityLabel.text = severityText
        severityLabel.font = .systemFont(ofSize: 14, weight: .medium)
        severityLabel.textColor = severityColor

        let severityRow = UIStackView(arrangedSubviews: [dot, severityLabel])
        severityRow.axis = .horizontal
        severityRow.alignment = .center
        severityRow.spacing = 6

        // ── Duration row ──────────────────────────────────────────────────
        let durationLabel = UILabel()
        if let dur = record.duration, dur > 0 {
            let mins = Int(dur) / 60
            let secs = Int(dur) % 60
            durationLabel.text = mins > 0 ? "\(mins)m \(secs)s duration" : "\(secs)s duration"
        } else {
            durationLabel.text = "Duration not recorded"
        }
        durationLabel.font = .systemFont(ofSize: 13, weight: .regular)
        durationLabel.textColor = .tertiaryLabel

        // ── Divider ───────────────────────────────────────────────────────
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.5)
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        // ── Assemble vertical stack ───────────────────────────────────────
        let vStack = UIStackView(arrangedSubviews: [dateLabel, titleLabel, divider, severityRow, durationLabel])
        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.setCustomSpacing(10, after: titleLabel)
        vStack.setCustomSpacing(10, after: divider)
        vStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }



    // MARK: - Records Section Update

    func updateRecordsSection() {
        let recent = SeizureRecordDataModel.shared.getLatestTwoRecordsForCurrentUser()

        if recent.isEmpty {
            showEmptyState(animated: false)
        } else {
            hideEmptyState(animated: false)

            populatePreviewCard(previewCard0, record: recent[0])
            previewCard0.isHidden = false

            if recent.count >= 2 {
                populatePreviewCard(previewCard1, record: recent[1])
                previewCard1.isHidden = false
            } else {
                previewCard1.isHidden = true
            }
        }
    }

    private func showEmptyState(animated: Bool = true) {
        previewCard0.isHidden = true
        previewCard1.isHidden = true

        // Switch header button to "+"
        recordsActionButton.removeTarget(nil, action: nil, for: .allEvents)
        recordsActionButton.setTitle(nil, for: .normal)
        recordsActionButton.setImage(UIImage(systemName: "plus"), for: .normal)
        recordsActionButton.addTarget(self, action: #selector(addRecordTapped), for: .touchUpInside)

        let show = { self.emptyStateView.isHidden = false }
        if animated {
            UIView.transition(with: recordsCardView, duration: 0.3,
                              options: .transitionCrossDissolve, animations: show)
        } else { show() }
    }


    private func hideEmptyState(animated: Bool = true) {
        // Switch header button to "View all"
        recordsActionButton.removeTarget(nil, action: nil, for: .allEvents)
        recordsActionButton.setImage(nil, for: .normal)
        recordsActionButton.setTitle("View all", for: .normal)
        recordsActionButton.addTarget(self, action: #selector(viewAllRecordsTapped), for: .touchUpInside)

        let hide = { self.emptyStateView.isHidden = true }
        if animated {
            UIView.transition(with: recordsCardView, duration: 0.3,
                              options: .transitionCrossDissolve, animations: hide)
        } else { hide() }
    }

    // MARK: - Button Actions

    @objc private func addRecordTapped() {
        let storyboard = UIStoryboard(name: "Records", bundle: nil)
        guard let addRecordVC = storyboard.instantiateViewController(
            withIdentifier: "AddRecordTableViewController"
        ) as? AddRecordTableViewController else { return }
        navigationController?.pushViewController(addRecordVC, animated: true)
    }


    @objc private func viewAllRecordsTapped() {
        performSegue(withIdentifier: "showRecords", sender: nil)
    }

    // Legacy updateCard kept for any external callers; new code uses populatePreviewCard.
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

    // Records cell (section 1, row 0) must self-size to fit empty state
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            return UITableView.automaticDimension
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView,
                            estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 1 ? 280 : 44
    }

    // SECTION HEADER HEIGHT
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return UITableView.automaticDimension
        }
        return 2
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
    
    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins)m \(secs)s"
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

extension Double {
    func formatted(_ decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f", self)
    }
    
    
}
