import UIKit

// MARK: - Navigation Bar Styles
extension UINavigationController {

    func applyTransparentNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }

    func applyWhiteNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }
}


// MARK: - UIView Card Styles
extension UIView {

    func applyDashboardCard() {
        layer.cornerRadius = 16
        layer.masksToBounds = false
        layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        layer.borderWidth = 0.6
        backgroundColor = .white

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)
    }

    func applyRecordCard() {
        backgroundColor = .white
        layer.cornerRadius = 14
        layer.masksToBounds = false

        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1).cgColor

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}


// MARK: - Table View Helpers (NO OVERRIDES!)
extension UITableViewController {

    func applyDefaultTableBackground() {
        tableView.backgroundColor = .systemGray6
    }

    func applySectionSpacing() {
        // This DOES NOT override methods — it sets defaults
        tableView.sectionHeaderHeight = 6
        tableView.sectionFooterHeight = 2
    }
}

// MARK: - Segmented Control Style
extension UISegmentedControl {

    func applyPrimaryStyle() {
        self.backgroundColor = UIColor(red: 237/255, green: 237/255, blue: 242/255, alpha: 1)
        self.selectedSegmentTintColor = .white

        // Corner radius
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = true

        // Text styling
        let normalText: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]

        let selectedText: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 36/255, green: 104/255, blue: 244/255, alpha: 1),
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]

        self.setTitleTextAttributes(normalText, for: .normal)
        self.setTitleTextAttributes(selectedText, for: .selected)
    }
}


// MARK: - Date Formats
struct DateFormats {

    static let fullDate: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df
    }()

    static let withTime: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy, hh:mm a"
        return df
    }()
}
