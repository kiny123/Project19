//
//  LoadViewControllerTableViewController.swift
//  Exstension
//
//  Created by nikita on 28.02.2023.
//

import UIKit

protocol LoaderDelegate {
     func loader(_ loader: LoadViewController, didSelect script: String)

 }

class LoadViewController: UITableViewController {
    
    var saveByName: [UserSaved]!
    var saveByNameKey: String!
    
    var delegate: LoaderDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard saveByName != nil && saveByNameKey != nil else {
            print("Parameters not set")
            navigationController?.popViewController(animated: true)
            return
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return saveByName.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Script", for: indexPath)
        cell.textLabel?.text = saveByName[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.loader(self, didSelect: saveByName[indexPath.row].script)
        navigationController?.popViewController(animated: true)
    }
}
