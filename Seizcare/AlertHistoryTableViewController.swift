//
//  AlertHistoryTableViewController.swift
//  Seizcare
//

import UIKit

class AlertHistoryTableViewController: UITableViewController {

    // MARK: - Section Data (EXACTLY like RecordTableVC)

    var sectionTitles: [String] = []
    var notificationsBySection: [[AppNotification]] = []

    private var allNotifications: [AppNotification] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()

        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.systemGroupedBackground

        loadAndGroupNotifications()
    }

    // MARK: - Load + Group (MATCHES RecordTableVC)

    func loadAndGroupNotifications() {
        let notifications =
            NotificationDataModel.shared.getNotificationsForCurrentUser()

        allNotifications = notifications
        groupAndReload(notifications)
    }

    private func groupAndReload(_ notifications: [AppNotification]) {

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"

        let grouped = Dictionary(grouping: notifications) { notification in
            formatter.string(from: notification.dateTime).uppercased()
        }

        let monthsOrder = [
            "JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE",
            "JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"
        ]

        sectionTitles = grouped.keys.sorted {
            monthsOrder.firstIndex(of: $0)! > monthsOrder.firstIndex(of: $1)!
        }

        notificationsBySection = sectionTitles.map {
            grouped[$0]!.sorted { $0.dateTime > $1.dateTime }
        }

        tableView.reloadData()
    }

    // MARK: - TableView Sections

    override func numberOfSections(in tableView: UITableView) -> Int {
        sectionTitles.count
    }

    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        sectionTitles[section]
    }

    // MARK: - Rows (ONE row per month)

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        1
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "MonthlyAlertHistoryCell",
            for: indexPath
        ) as! MonthlyAlertHistoryCell

        let notifications = notificationsBySection[indexPath.section]
        cell.configure(alerts: notifications)

        cell.selectionStyle = .none
        return cell
    }

    // MARK: - Section Header Styling (same as before)

    override func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        20
    }

    override func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {

        let header = UIView()
        header.backgroundColor = .clear

        let label = UILabel()
        label.text = sectionTitles[section]
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray

        label.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -6)
        ])

        return header
    }

    override func tableView(
        _ tableView: UITableView,
        heightForFooterInSection section: Int
    ) -> CGFloat {
        20
    }

    override func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}
