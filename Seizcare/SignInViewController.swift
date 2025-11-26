//
//  SignInViewController.swift
//  Seizcare
//
//  Created by Student on 25/11/25.
//

import UIKit

var enteredEmailOrPhone: String?
var enteredPassword: String?
let sampleUsers = [
    ("ghanshyam@example.com", "password123"),
    ("diya@example.com", "password123"),
    ("admin", "admin123")
]



class SignInViewController: UIViewController {

    
    @IBOutlet weak var EmailOrPhNo: UITextField!
    
    @IBOutlet weak var PasswordTextField: UITextField!
    
    @IBAction func SignInAction(_ sender: Any) {
        let emailOrPhone = EmailOrPhNo.text ?? ""
            let password = PasswordTextField.text ?? ""

            debugLog("User entered → Email/Phone: \(emailOrPhone), Password: \(password)")

            // 1. Empty field validation
            if emailOrPhone.isEmpty || password.isEmpty {
                debugLog("Validation Failed → Empty fields found")
                showAlert(message: "Please enter both email/phone and password.")
                return
            }

           
            debugLog("Checking credentials against sample user list…")

            // 2. Check sample user list
            let isValid = sampleUsers.contains { user in
                debugLog("Comparing input with sample → \(user.0), \(user.1)")
                return user.0 == emailOrPhone && user.1 == password
            }

           
            if isValid {
                debugLog("Login SUCCESS → Navigating to next screen")

                performSegue(withIdentifier: "goToNextScreen", sender: self)

            } else {
                debugLog("Login FAILED → Invalid credentials")
                showAlert(message: "Invalid email/phone or password.")
            }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNextScreen" {
            if let nextVC = segue.destination as? DisclaimerViewController {

                nextVC.receivedEmail = EmailOrPhNo.text ?? ""
                nextVC.receivedPassword = PasswordTextField.text ?? ""
            }
        }
    }
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    func debugLog(_ message: String) {
        print("[DEBUG] \(message)")
    }




    // MARK: - Table view data source

   

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
