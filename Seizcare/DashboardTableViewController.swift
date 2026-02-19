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
        // ── Setup Graph Structure (Persistent Header + Content) ─────────────
        let contentContainer = setupGraphStructure(
            in: triggerCorrelationChart,
            title: "Trigger Correlation"
        )
        
        // ── emptyStateView ────────────────────────────────────────────────
        let emptyStateView = makeChartEmptyState(
            symbol: "bolt.horizontal.circle",
            title: "No Trigger Insights Yet",
            subtitle: "Log seizures and triggers to discover patterns.",
            tint: .systemOrange.withAlphaComponent(0.45)
        )
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── chartContainerView ────────────────────────────────────────────
        let chartContainerView = UIView()
        chartContainerView.backgroundColor = .clear
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(chartContainerView)
        NSLayoutConstraint.activate([
            chartContainerView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            chartContainerView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            chartContainerView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            chartContainerView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── Trigger Condition ─────────────────────────────────────────────
        let triggerData = dashboardModel.getTriggerCorrelation()
        let hasRecords = !SeizureRecordDataModel.shared.getRecordsForCurrentUser().isEmpty
        let hasData = hasRecords && !triggerData.isEmpty

        chartContainerView.isHidden = !hasData
        emptyStateView.isHidden = hasData

        guard hasData else {
            contentContainer.bringSubviewToFront(emptyStateView)
            return
        }

        // ── Embed chart into chartContainerView ───────────────────────────
        let chartView = TriggerCorrelationChart(data: triggerData)
        let hostingVC = UIHostingController(rootView: chartView)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(hostingVC.view)
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
        hostingVC.didMove(toParent: self)
    }


    func addTimePatternChart() {
        // ── Setup Graph Structure (Persistent Header + Content) ─────────────
        let contentContainer = setupGraphStructure(
            in: timePatternChart,
            title: "Time of Day Pattern"
        )

        // ── emptyStateView ────────────────────────────────────────────────
        let emptyStateView = makeChartEmptyState(
            symbol: "clock.arrow.circlepath",
            title: "No Time Pattern Yet",
            subtitle: "Log seizure records to see when they occur most often."
        )
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── chartContainerView ────────────────────────────────────────────
        let chartContainerView = UIView()
        chartContainerView.backgroundColor = .clear
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(chartContainerView)
        NSLayoutConstraint.activate([
            chartContainerView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            chartContainerView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            chartContainerView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            chartContainerView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── Guard: show empty state when no records ───────────────────────
        let hasRecords = !SeizureRecordDataModel.shared.getRecordsForCurrentUser().isEmpty
        chartContainerView.isHidden = !hasRecords
        emptyStateView.isHidden = hasRecords

        guard hasRecords else {
            contentContainer.bringSubviewToFront(emptyStateView)
            return
        }

        // ── Embed chart into chartContainerView ───────────────────────────
        let data = dashboardModel.getTimeOfDayPattern(months: 3)
        let chart = TimePatternChart(data: data)
        let hostingVC = UIHostingController(rootView: chart)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(hostingVC.view)
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
        hostingVC.didMove(toParent: self)
    }


    func addSleepVsSeizureChart() {
        // ── Setup Graph Structure (Persistent Header + Content) ─────────────
        let contentContainer = setupGraphStructure(
            in: sleepVsSeizureChart,
            title: "Sleep vs Seizures"
        )

        // ── emptyStateView ────────────────────────────────────────────────
        let emptyStateView = makeChartEmptyState(
            symbol: "chart.line.uptrend.xyaxis",
            title: "No Insights Available",
            subtitle: "Log seizures and sleep to unlock comparisons."
        )
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── chartContainerView ────────────────────────────────────────────
        let chartContainerView = UIView()
        chartContainerView.backgroundColor = .clear
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(chartContainerView)
        NSLayoutConstraint.activate([
            chartContainerView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            chartContainerView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            chartContainerView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            chartContainerView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── Guard: show empty state when no records ───────────────────────
        let hasRecords = !SeizureRecordDataModel.shared.getRecordsForCurrentUser().isEmpty
        chartContainerView.isHidden = !hasRecords
        emptyStateView.isHidden = hasRecords

        guard hasRecords else {
            contentContainer.bringSubviewToFront(emptyStateView)
            return
        }

        // ── Embed chart into chartContainerView ───────────────────────────
        let data = dashboardModel.getSleepVsSeizure()
        let chart = SleepVsSeizureChart(data: data)
        let hostingVC = UIHostingController(rootView: chart)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(hostingVC.view)
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
        ])
        hostingVC.didMove(toParent: self)
    }

    // MARK: - Chart Empty State Helper

    /// Returns a self-centering empty state view. The stack is centered
    /// inside the container using centerX/centerY — no clipping, no frames.
    private func makeChartEmptyState(symbol: String, title: String, subtitle: String,
                                      tint: UIColor = .systemBlue.withAlphaComponent(0.4)) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .light) // Reduced to 28pt as requested
        let iconView = UIImageView(image: UIImage(systemName: symbol, withConfiguration: iconConfig))
        iconView.tintColor = tint
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .vertical)
        iconView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12 // Adjusted spacing
        stack.setCustomSpacing(16, after: iconView)
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            // Center the stack inside the container
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            // Prevent overflow on narrow screens
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            // Keep stack within vertical bounds
            stack.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 0),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: 0)
        ])
        return container
    }

    /// Helper to create the standard Graph Card structure:
    /// - Header (Title + Optional Subtitle) pinned to top
    /// - Content Container (fills remaining space)
    /// Returns the content container where charts/empty states should be added.
    private func setupGraphStructure(in parentView: UIView, title: String, subtitle: String? = nil) -> UIView {
        parentView.subviews.forEach { $0.removeFromSuperview() }
        parentView.clipsToBounds = true

        // 1. Header (Title)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .darkGray
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20)
        ])

        var topAnchorForContent = titleLabel.bottomAnchor
        let topPaddingForContent: CGFloat = 20

        // 2. Subtitle (Optional)
        if let sub = subtitle {
            let subLabel = UILabel()
            subLabel.text = sub
            subLabel.font = .preferredFont(forTextStyle: .caption2)
            subLabel.textColor = .tertiaryLabel
            subLabel.numberOfLines = 0
            subLabel.textAlignment = .left
            subLabel.translatesAutoresizingMaskIntoConstraints = false
            parentView.addSubview(subLabel)

            NSLayoutConstraint.activate([
                subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
                subLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 20),
                subLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -20)
            ])
            topAnchorForContent = subLabel.bottomAnchor
        }

        // 3. Content Container
        let contentContainer = UIView()
        contentContainer.backgroundColor = .clear
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(contentContainer)
        
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: topAnchorForContent, constant: topPaddingForContent),
            contentContainer.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -20) // Bottom padding
        ])
        
        return contentContainer
    }


    func setupSeizureChartFooter() {
        let hasRecords = !SeizureRecordDataModel.shared.getRecordsForCurrentUser().isEmpty

        // Hide footer entirely when there are no records
        seizureChartBottomIcon.isHidden = !hasRecords
        seizureChartBottomMetricsLabel.isHidden = !hasRecords
        guard hasRecords else { return }

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
        seizureChartLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
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
        // ── Clear all previous content ────────────────────────────────────
        seizureFrequencyChartContainer.subviews.forEach { $0.removeFromSuperview() }
        seizureFrequencyChartContainer.clipsToBounds = true

        // ── contentContainer fills the storyboard chart container ─────────
        let contentContainer = UIView()
        contentContainer.backgroundColor = .clear
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        seizureFrequencyChartContainer.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: seizureFrequencyChartContainer.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: seizureFrequencyChartContainer.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: seizureFrequencyChartContainer.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: seizureFrequencyChartContainer.bottomAnchor)
        ])

        // ── emptyStateView ────────────────────────────────────────────────
        let emptyStateView = makeChartEmptyState(
            symbol: "chart.bar.fill",
            title: "No Data Yet",
            subtitle: "Start logging seizures to see frequency trends."
        )
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── chartContainerView ────────────────────────────────────────────
        let chartContainerView = UIView()
        chartContainerView.backgroundColor = .clear
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(chartContainerView)
        NSLayoutConstraint.activate([
            chartContainerView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            chartContainerView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            chartContainerView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            chartContainerView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        // ── Guard: show empty state when no records ───────────────────────
        let hasRecords = !SeizureRecordDataModel.shared.getRecordsForCurrentUser().isEmpty
        chartContainerView.isHidden = !hasRecords
        emptyStateView.isHidden = hasRecords

        // Hide/show comparison footer alongside chart
        seizureChartBottomIcon.isHidden = !hasRecords
        seizureChartBottomMetricsLabel.isHidden = !hasRecords

        guard hasRecords else {
            contentContainer.bringSubviewToFront(emptyStateView)
            UIView.transition(with: seizureFrequencyChartContainer, duration: 0.3,
                              options: .transitionCrossDissolve, animations: nil)
            return
        }

        // ── Embed chart into chartContainerView ───────────────────────────
        let data = dashboardModel.getSeizureFrequency(period: period)
        let sortedData = data.sorted { $0.date < $1.date }

        let chartView = SeizureFrequencyChart(data: sortedData, period: period)
        let hostingVC = UIHostingController(rootView: chartView)

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(hostingVC.view)
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor)
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
        dateLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        // ── Title / entry type ────────────────────────────────────────────
        let titleLabel = UILabel()
        if record.entryType == .automatic {
            titleLabel.text = "Automatic Detection"
        } else {
            titleLabel.text = record.title?.capitalized ?? "Manual Record"
        }
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

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
        severityLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let severityRow = UIStackView(arrangedSubviews: [dot, severityLabel])
        severityRow.axis = .horizontal
        severityRow.alignment = .center
        severityRow.spacing = 6
        severityRow.setContentCompressionResistancePriority(.required, for: .vertical)

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
        durationLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        // ── Divider ───────────────────────────────────────────────────────
        let divider = UIView()
        divider.backgroundColor = .systemGray4
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        // ── Assemble vertical stack ───────────────────────────────────────
        let vStack = UIStackView(arrangedSubviews: [dateLabel, titleLabel, divider, severityRow, durationLabel])
        vStack.axis = .vertical
        vStack.spacing = 6
        vStack.setCustomSpacing(10, after: titleLabel)
        vStack.setCustomSpacing(10, after: divider)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.distribution = .fill // Ensure it fills the space
        
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
        
        // Force the table view to fully reload to ensure row heights are correct
        // This is more reliable than beginUpdates/endUpdates for dynamic content in static table views
        tableView.reloadData()
    }

    private func showEmptyState(animated: Bool = true) {
        previewCard0.isHidden = true
        previewCard1.isHidden = true

        // Hide header button (the upper + button) completely in empty state
        // as we already have a large CTA button in the empty state view.
        recordsActionButton.isHidden = true
        recordsActionButton.removeTarget(nil, action: nil, for: .allEvents)

        let show = { self.emptyStateView.isHidden = false }
        if animated {
            UIView.transition(with: recordsCardView, duration: 0.3,
                              options: .transitionCrossDissolve, animations: show)
        } else { show() }
    }


    private func hideEmptyState(animated: Bool = true) {
        // Show "View all" button when records exist
        recordsActionButton.isHidden = false
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
