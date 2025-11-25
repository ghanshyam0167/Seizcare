import UIKit

class AlertHistoryTableViewController: UITableViewController {
    
    struct AlertItem {
        let icon: String
        let notification: String
        let details: String
        let time: String
        let date: Date
    }
    
    var sections: [(title: String, items: [AlertItem])] = []
    
    @IBOutlet weak var AlertHistoryTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let logged = UserDataModel.shared.loginUser(email: "ghanshyam@example.com", password: "Twins241")

            print("TEMP LOGIN SUCCESS:", logged)
        AlertHistoryTableView.dataSource = self
        AlertHistoryTableView.delegate = self
        AlertHistoryTableView.separatorStyle = .none
        AlertHistoryTableView.backgroundColor = .systemGroupedBackground
        AlertHistoryTableView.rowHeight = UITableView.automaticDimension
        AlertHistoryTableView.estimatedRowHeight = 80
        
        loadNotificationsFromDataModel()
    }
    
    
    // ========================================================
    // MARK: LOAD + CONVERT DATA MODEL TO ALERT ITEMS
    // ========================================================
    func loadNotificationsFromDataModel() {
        let notifications = NotificationDataModel.shared.getNotificationsForCurrentUser()
        print(notifications)
        
        let dfTime = DateFormatter()
        dfTime.dateFormat = "HH:mm"
        
        var alertItems: [AlertItem] = []
        
        for n in notifications {
            let item = AlertItem(
                icon: n.iconName,
                notification: n.title,
                details: n.description ?? "",
                time: dfTime.string(from: n.dateTime),
                date: n.dateTime
            )
            alertItems.append(item)
        }
        
        // Now group them into sections
        buildSections(from: alertItems)
    }
    
    
    // ========================================================
    // MARK: GROUPING SECTIONS BASED ON DATE
    // ========================================================
    func buildSections(from alerts: [AlertItem]) {
        let df = DateFormatter()
        df.dateFormat = "dd MMM"
        
        let grouped = Dictionary(grouping: alerts) { alert -> String in
            df.string(from: alert.date).uppercased()
        }
        
        sections = grouped
            .map { (title: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.items.first!.date > $1.items.first!.date }
        
        tableView.reloadData()
    }
    
    
    // ========================================================
    // MARK: ICON STYLING
    // ========================================================
    func styleIcon(_ imageView: UIImageView,
                   symbol: String,
                   fg: UIColor,
                   bg: UIColor) {
        
        imageView.image = UIImage(systemName: symbol)
        imageView.tintColor = fg
        imageView.backgroundColor = bg
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 34),
            imageView.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
    }
    
    
    // ========================================================
    // MARK: TABLE VIEW DATA SOURCE
    // ========================================================
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AlertHistoryCell",
            for: indexPath
        ) as! AlertHistoryTableViewCell
        
        let alert = sections[indexPath.section].items[indexPath.row]
        
        // ICON LOGIC
        if alert.notification.lowercased().contains("seizure") {
            styleIcon(cell.iconImageView,
                      symbol: "exclamationmark.triangle.fill",
                      fg: UIColor(red: 0.65, green: 0.20, blue: 0.20, alpha: 1),
                      bg: UIColor(red: 1, green: 0.93, blue: 0.93, alpha: 1))
            
        } else if alert.notification.lowercased().contains("heart") {
            styleIcon(cell.iconImageView,
                      symbol: "waveform.path.ecg",
                      fg: UIColor(red: 0.25, green: 0.40, blue: 1.0, alpha: 1),
                      bg: UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1))
            
        } else {
            // fallback to SF symbol stored in model if any
            styleIcon(cell.iconImageView,
                      symbol: alert.icon,
                      fg: .white,
                      bg: UIColor(red: 0.20, green: 0.45, blue: 0.85, alpha: 1))
        }
        
        cell.NotificationLabel.text = alert.notification
        cell.notificationDetailsLabel.text = alert.details
        cell.timeLabel.text = alert.time
        
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        return cell
    }
    
    
    // ========================================================
    // MARK: SECTION HEADERS
    // ========================================================
    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        45
    }
    
    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        
        let label = UILabel()
        label.text = sections[section].title
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
    
    
    // ========================================================
    // MARK: FOOTERS
    // ========================================================
    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        16
    }
    
    override func tableView(_ tableView: UITableView,
                            viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}
