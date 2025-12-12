//
//  DashboardTableViewController.swift
//  Seizcare
//
//  Created by GS Agrawal on 24/11/25.
//

import UIKit
import DGCharts

class DashboardTableViewController: UITableViewController {
    var barChart = BarChartView()

    @IBOutlet weak var seizureFrequencyChart: UIView!
    
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
             recordsCardView, bottomCardView0, bottomCardView1, seizureFrequencyChart].forEach {
                $0?.applyDashboardCard()
            }
            [recordCardView0, recordCardView1].forEach {
                $0?.applyRecordCard()
            }
        
        weeklyMonthlySegment.applyPrimaryStyle()
        updateRecentRecords()
        
        setupChartContainer()
        setupChartAppearance()
        updateChartData()
        barChart.renderer = RoundedBarChartRenderer(
            dataProvider: barChart,
            animator: barChart.chartAnimator,
            viewPortHandler: barChart.viewPortHandler
        )

    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        barChart.frame = seizureFrequencyChart.bounds
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
        return 1   // spacing above all other sections
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {

        if section == 0 {
            return nil   // storyboard header will be shown
        }

        let spacer = UIView()
        spacer.backgroundColor = .clear
        return spacer
    }

    // FOOTER (space below each section)
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
    func setupChartContainer() {
        barChart.frame = seizureFrequencyChart.bounds
        barChart.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        seizureFrequencyChart.addSubview(barChart)
    }
    func setupChartAppearance() {

        barChart.legend.enabled = false
        barChart.rightAxis.enabled = false
        barChart.doubleTapToZoomEnabled = false
        barChart.pinchZoomEnabled = false
        barChart.dragEnabled = false
        barChart.setScaleEnabled(false)
        barChart.drawBarShadowEnabled = false
        barChart.drawGridBackgroundEnabled = false

        // X-Axis
        let xAxis = barChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.valueFormatter = IndexAxisValueFormatter(values: ["Jan","Feb","Mar","Apr","May","Jun"])
        xAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        xAxis.labelTextColor = UIColor.darkGray
        xAxis.granularity = 1

        // Y-Axis
        let leftAxis = barChart.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.gridColor = UIColor.lightGray.withAlphaComponent(0.2)
        leftAxis.drawAxisLineEnabled = false
        leftAxis.labelFont = UIFont.systemFont(ofSize: 12)
        leftAxis.labelTextColor = UIColor.lightGray

        // Hide right axis
        barChart.rightAxis.enabled = false

        // Animation
        barChart.animate(yAxisDuration: 0.7)

    }

    func updateChartData() {
        let values = [8, 12, 10, 15, 7, 11]
        var entries: [BarChartDataEntry] = []

        for (i, v) in values.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: Double(v)))
        }

        let dataSet = BarChartDataSet(entries: entries)

        // Figma pastel colors
        dataSet.colors = [
            UIColor(red: 0.78, green: 0.51, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.40, green: 0.67, blue: 0.67, alpha: 1.0),
            UIColor(red: 0.47, green: 0.68, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.55, green: 0.53, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.53, green: 0.80, blue: 0.93, alpha: 1.0),
            UIColor(red: 0.62, green: 0.78, blue: 1.0, alpha: 1.0)
        ]

        // REMOVE labels above bars
        dataSet.drawValuesEnabled = false

        let data = BarChartData(dataSet: dataSet)
        data.barWidth = 0.4

        barChart.data = data
        barChart.setNeedsLayout()
        barChart.layoutIfNeeded()
    }

}

class RoundedBarChartView: BarChartView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async { [weak self] in
            self?.onLayout?()
        }
    }
}


import DGCharts
import UIKit

final class RoundedBarChartRenderer: BarChartRenderer {

    // Match base initializer isolation
    nonisolated
    override init(dataProvider: BarChartDataProvider,
                  animator: Animator,
                  viewPortHandler: ViewPortHandler) {
        super.init(dataProvider: dataProvider,
                   animator: animator,
                   viewPortHandler: viewPortHandler)
    }

    // Override the data-drawing entry point used by Chart library
    nonisolated
    override func drawData(context: CGContext) {
        guard
            let dataProvider = dataProvider,
            let barData = dataProvider.barData
        else { return }

        // Loop datasets and draw rounded bars for bar datasets
        for dataSetIndex in 0 ..< barData.dataSetCount {
            guard
                let dataSet = barData[dataSetIndex] as? BarChartDataSetProtocol,
                dataSet.entryCount > 0
            else { continue }

            drawRoundedDataSet(context: context,
                               dataSet: dataSet,
                               dataSetIndex: dataSetIndex,
                               dataProvider: dataProvider,
                               barData: barData)
        }
    }

    private func drawRoundedDataSet(
        context: CGContext,
        dataSet: BarChartDataSetProtocol,
        dataSetIndex: Int,
        dataProvider: BarChartDataProvider,
        barData: BarChartData
    ) {
        // Transformer for the axis the dataset belongs to
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)

        // bar width from barData (DGCharts exposes this)
        let barWidth = barData.barWidth

        // We'll build a simple buffer [left, top, right, bottom] per bar (in value coords)
        var valueRect = CGRect.zero

        context.saveGState()

        // iterate entries
        for entryIndex in 0 ..< dataSet.entryCount {
            guard let e = dataSet.entryForIndex(entryIndex) as? BarChartDataEntry else { continue }

            // value-space rectangle for the bar (centered at x, extends to y)
            let x = CGFloat(e.x)
            let y = CGFloat(e.y)

            // left/right in value coords
            let left = x - CGFloat(barWidth) / 2.0
            let right = x + CGFloat(barWidth) / 2.0

            // top/bottom in value coords — chart uses positive/negative y to determine direction
            // keep bars growing from 0 to y (works for positive-only data; adjust if needed)
            let topValue = max(y, 0)
            let bottomValue = min(y, 0)

            valueRect.origin.x = left
            valueRect.origin.y = topValue
            valueRect.size.width = right - left
            valueRect.size.height = bottomValue - topValue

            // Convert value-space rect -> pixels
            trans.rectValueToPixel(&valueRect)

            // If rect is degenerate, skip
            if valueRect.isEmpty || valueRect.width.isNaN || valueRect.height.isNaN { continue }


            // Top-left & top-right corners rounded
            let radius: CGFloat = 6.0
            let path = UIBezierPath(
                roundedRect: valueRect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: radius, height: radius)
            )

            // Obtain color for this entry (dataSet.color(atIndex:) expects an Int index)
            let color = dataSet.color(atIndex: entryIndex)
            context.setFillColor(color.cgColor)
            context.addPath(path.cgPath)
            context.fillPath()
        }

        context.restoreGState()
    }
}
