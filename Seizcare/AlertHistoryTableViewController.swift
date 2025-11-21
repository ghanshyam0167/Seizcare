import UIKit

class AlertHistoryTableViewController: UITableViewController {
    
    // MARK: - MODEL
    struct AlertItem {
        let icon: UIImage?
        let notification: String
        let details: String
        let time: String
        let date: Date
    }
    
    // MARK: - DATA ARRAYS
    var alerts: [AlertItem] = []
    var sections: [(title: String, items: [AlertItem])] = []
    
    
    // MARK: - OUTLET
    @IBOutlet var AlertHistoryTableView: UITableView!
    
    
    // MARK: - VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()

        AlertHistoryTableView.dataSource = self
        AlertHistoryTableView.delegate = self
        AlertHistoryTableView.separatorStyle = .none
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        
        alerts = [
            AlertItem(icon: UIImage(systemName: "staroflife.fill"),
                      notification: "Seizure Detected",
                      details: "Vanshika & 2 others notified",
                      time: "09:41",
                      date: formatter.date(from: "2025/10/13")!),

            AlertItem(icon: UIImage(systemName: "waveform.path.ecg"),
                      notification: "High Heart Rate",
                      details: "Take deep breaths",
                      time: "08:10",
                      date: formatter.date(from: "2025/10/13")!),

            AlertItem(icon: UIImage(systemName: "staroflife.fill"),
                      notification: "Seizure Detected",
                      details: "All emergency contacts notified",
                      time: "07:21",
                      date: formatter.date(from: "2025/10/12")!),

            AlertItem(icon: UIImage(systemName: "staroflife.fill"),
                      notification: "Seizure Detected",
                      details: "Vanshika & 2 others notified",
                      time: "09:41",
                      date: formatter.date(from: "2025/10/14")!),

            AlertItem(icon: UIImage(systemName: "staroflife.fill"),
                      notification: "Seizure Detected",
                      details: "All emergency contacts notified",
                      time: "08:15",
                      date: formatter.date(from: "2025/07/21")!)
        ]
        
        buildSections()
    }
    
    
    // MARK: - GROUP SECTIONS DYNAMICALLY
    func buildSections() {
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Group alerts by section title
        var grouped = Dictionary(grouping: alerts) { alert -> String in
            
            let alertDay = calendar.startOfDay(for: alert.date)
            
            if alertDay == today {
                return "TODAY"
            } else if alertDay == yesterday {
                return "YESTERDAY"
            } else {
                let df = DateFormatter()
                df.dateFormat = "dd MMM"
                return df.string(from: alert.date).uppercased()
            }
        }
        
        // Convert dictionary → sorted array
        sections = grouped
            .map { (key, value) in
                (title: key, items: value.sorted { $0.time > $1.time })
            }
            .sorted { $0.items.first!.date > $1.items.first!.date }
    }
    
    
    // MARK: - TABLE VIEW DATA SOURCE
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlertHistoryCell", for: indexPath) as! AlertHistoryTableViewCell
        
        let alert = sections[indexPath.section].items[indexPath.row]
        
        cell.iconImageView.image = alert.icon
        cell.NotificationLabel.text = alert.notification
        cell.notificationDetailsLabel.text = alert.details
        cell.timeLabel.text = alert.time
        
        return cell
    }
    
    
    // MARK: - CUSTOM SECTION HEADER
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.text = sections[section].title
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.darkGray.withAlphaComponent(0.9)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -5)
        ])
        
        return headerView
    }
}

