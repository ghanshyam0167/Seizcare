import UIKit

class SensitivityViewTableViewController: UITableViewController {

    let sensitivities = ["Low", "Medium", "High"]

    let descriptions = [
        "Triggers alerts only for strong seizure patterns",
        "Balanced detection for everyday use",
        "Highly sensitive, detects even mild activity"
    ]

    var selectedIndex = 1   // Default = Medium

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sensitivity"
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
    }

    // MARK: - Table Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        sensitivities.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "sensitivityCell",
            for: indexPath
        )

        cell.textLabel?.text = sensitivities[indexPath.row]
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        cell.detailTextLabel?.text = descriptions[indexPath.row]
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0

        cell.accessoryType = (indexPath.row == selectedIndex)
            ? .checkmark
            : .none

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row

        UserDefaults.standard.set(
            sensitivities[selectedIndex],
            forKey: "sensitivityLevel"
        )

        tableView.reloadData()
    }
}
