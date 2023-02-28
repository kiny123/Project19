//
//  ActionViewController.swift
//  Exstension
//
//  Created by nikita on 28.02.2023.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers


class ActionViewController: UIViewController, LoaderDelegate {
    func loader(_ loader: LoadViewController, didSelect script: String) {
        scriptToLoad = script
    }
    
    @IBOutlet var script: UITextView!
    
    var pageTitle = ""
    var pageURL = ""
    
    var saveByURL = [String: String]()
    var saveByUrlKey = "SaveByUrl"
    
    var saveByName = [UserSaved]()
    var saveByNameKey = "SaveByName"
    
    var scriptToLoad: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(exampleBookmarks))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""

                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let scriptToload = scriptToLoad {
            script.text = scriptToload
        }
        scriptToLoad = nil
    }
    
    func updateUI() {
             title = "JS injection"

             if let url = URL(string: pageURL) {
                 if let host = url.host {
                     script.text = saveByURL[host]
                 }
             }
         }
    
    func loadData() {
        let userDefaults = UserDefaults.standard
        saveByURL = userDefaults.object(forKey: saveByUrlKey) as? [String: String] ?? [String: String]()
        
        if let saveByNameData = userDefaults.object(forKey: saveByNameKey) as? Data {
            let jsonDecoder = JSONDecoder()
            saveByName = (try? jsonDecoder.decode([UserSaved].self, from: saveByNameData)) ?? [UserSaved]()
             }
         }
    
    
    func saveScripts() {
        let url = URL(string: pageURL)
        if let host = url?.host {
            saveByURL[host] = script.text
            let userDefaults = UserDefaults.standard
            userDefaults.set(saveByURL, forKey: saveByUrlKey)
        }
    }

    @IBAction func done() {
        DispatchQueue.global().async() { [weak self] in
                self?.saveScripts()

            let item = NSExtensionItem()
            let argument: NSDictionary = ["customJavaScript": self?.script.text as Any]
            let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
            let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
            item.attachments = [customJavaScript]

            DispatchQueue.main.async {
                self?.extensionContext?.completeRequest(returningItems: [item])
            }
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        script.scrollIndicatorInsets = script.contentInset

        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
    
    @objc func exampleBookmarks() {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        ac.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        ac.addAction(UIAlertAction(title: "Examples", style: .default) { [weak self] _ in self?.example() })
        
        ac.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in self?.saveTapped() })
        
        ac.addAction(UIAlertAction(title: "Load", style: .default) { [weak self] _ in self?.loadTapped() })
        
        present(ac, animated: true)
        
    }
    
    @objc func example() {
        
        let ac = UIAlertController(title: "Exemples of scripts", message: nil, preferredStyle: .actionSheet)
        ac.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        
        for (title, example) in examples {
            ac.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in self?.script.text = example })
        }
        
        present(ac, animated: true)
    }
    
    func saveTapped() {
             let ac = UIAlertController(title: "Script name", message: nil, preferredStyle: .alert)
             ac.addTextField()
             ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
             ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
                 guard let name = ac?.textFields?[0].text else { return }
                 self?.saveByName.append(UserSaved(name: name, script: self?.script.text ?? ""))
                 self?.performSelector(inBackground: #selector(self?.saveScriptsName), with: nil)
             })

             present(ac, animated: false)
         }
    
    @objc func saveScriptsName() {
             let jsonEncoder = JSONEncoder()
             if let savedData = try? jsonEncoder.encode(saveByName) {
                 let userDefaults = UserDefaults.standard
                 userDefaults.set(savedData, forKey: saveByNameKey)
             }
         }
    
    func loadTapped() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "LoadViewController") as? LoadViewController {
            vc.saveByName = saveByName
            vc.saveByNameKey = saveByNameKey
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
             }
         }
  

}
