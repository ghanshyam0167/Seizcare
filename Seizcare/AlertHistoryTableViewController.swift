//
//  AlertHistoryTableViewController.swift
//  Seizcare
//

import UIKit

class AlertHistoryTableViewController: UITableViewController {

    // Section Data
    var sectionTitles: [String] = []
    var notificationsBySection: [[AppNotification]] = []
    private var allNotifications: [AppNotification] = []

    // Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400

        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()

        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.systemGroupedBackground

        setupRefreshControl()
        loadAndGroupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshAndReload()
    }

    // MARK: - Refresh Logic

    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    @objc private func handleRefresh() {
        print("🔃 [AlertHistoryVC] Manual refresh triggered")
        
        if allNotifications.isEmpty {
            print("🧪 [AlertHistoryVC] No notifications found, seeding a test one...")
            NotificationDataModel.shared.addNotification(type: .testNotification)
        }
        
        refreshAndReload()
    }

    private func refreshAndReload() {
        print("🔄 [AlertHistoryVC] refreshAndReload() started")
        Task {
            await NotificationDataModel.shared.refreshNotifications()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.loadAndGroupNotifications()
                self.refreshControl?.endRefreshing()
                print("✅ [AlertHistoryVC] Refresh complete")
            }
        }
    }

    // MARK: - Load + Group

    func loadAndGroupNotifications() {
        let notifications = NotificationDataModel.shared.getNotificationsForCurrentUser()
        allNotifications = notifications
        groupAndReload(notifications)
    }

    private func groupAndReload(_ notifications: [AppNotification]) {
        print("📊 [AlertHistoryVC] groupAndReload() with \(notifications.count) notifications")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: notifications) { notification in
            formatter.string(from: notification.dateTime)
        }

        sectionTitles = grouped.keys.sorted {
            let d1 = formatter.date(from: $0) ?? .distantPast
            let d2 = formatter.date(from: $1) ?? .distantPast
            return d1 > d2
        }
        
        print("📑 [AlertHistoryVC] Grouped into \(sectionTitles.count) sections: \(sectionTitles)")

        notificationsBySection = sectionTitles.map {
            grouped[$0]!.sorted { $0.dateTime > $1.dateTime }
        }

        print("🔄 [AlertHistoryVC] Reloading table view")
        tableView.reloadData()
    }

    // MARK: - TableView Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("🔍 [AlertHistoryVC] Dequeuing cell for section \(indexPath.section)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MonthlyAlertHistoryCell", for: indexPath) as! MonthlyAlertHistoryCell

        let notifications = notificationsBySection[indexPath.section]
        print("📦 [AlertHistoryVC] Configuring cell with \(notifications.count) alerts")
        cell.configure(alerts: notifications)

        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}
