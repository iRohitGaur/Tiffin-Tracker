//
//  AddTiffin.swift
//  Tiffin Tracker
//
//  Created by RG on 3/8/18.
//  Copyright © 2018 RG. All rights reserved.
//

import UIKit
import Contacts
import GoogleMobileAds

class AddTiffin: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    var weekdays = Set<String>()
    var deliveredDatesArray = Array<NSString>()
    var segueName = ""
    var index: Int = 0
    var tiffinObject: Tiffin?
    let preferences = UserDefaults.standard
    var contacts:[contactModel] = []
    var filteredContacts:[contactModel] = []
    var isSearching = false
    
    @IBOutlet weak var instructionsView: UIView!
    @IBOutlet weak var tiffinName: UITextField!
    @IBOutlet weak var tiffinCost: UITextField!
    @IBOutlet weak var tiffinBalance: UITextField!
    @IBOutlet weak var tiffinPhone: UITextField!
    @IBOutlet weak var sunButtonOutlet: UIButton!
    @IBOutlet weak var monButtonOutlet: UIButton!
    @IBOutlet weak var tueButtonOutlet: UIButton!
    @IBOutlet weak var wedButtonOutlet: UIButton!
    @IBOutlet weak var thuButtonOutlet: UIButton!
    @IBOutlet weak var friButtonOutlet: UIButton!
    @IBOutlet weak var satButtonOutlet: UIButton!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var contactsView: UIView!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //Hide Contacts View at first
        DispatchQueue.main.async {
            self.showHideContactsView(hidden: true)
        }
        
        //Instructions View Logic
        if preferences.object(forKey: "instructionsViewHiddenInAddTiffin") != nil {
            instructionsView.isHidden = true
        }
        if segueName == "UPDATE" {
            self.navigationItem.title = "Update Tiffin"
            tiffinName.text = tiffinObject!.name
            tiffinCost.text = String(tiffinObject!.cost)
            deliveredDatesArray = tiffinObject!.deliveredDates as! Array<NSString>
            tiffinBalance.text = String(tiffinObject!.balance - (tiffinObject!.cost * Int64(deliveredDatesArray.count)))
            tiffinPhone.text = tiffinObject!.phone
            weekdays = tiffinObject!.weekdays as! Set<String>
            updateButtonOutlets(set: weekdays)
        } else {
            self.navigationItem.title = "Add Tiffin"
        }
        
        //Tap Gesture to dismiss Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        //ADMOB
        //callAdmob()
    }
    
    func callAdmob() {
        var bannerView: GADBannerView!
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        //demo ID: ca-app-pub-3940256099942544/2934735716
        //Actual ID: ca-app-pub-4464278263822865/4037778868
        bannerView.adUnitID = "ca-app-pub-4464278263822865/4037778868"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
    // MARK: - IBAction Methods
    @IBAction func dismissContactsView(_ sender: Any) {
        showHideContactsView(hidden: true)
    }

    @IBAction func dismissInstructionsView(_ sender: Any) {
        instructionsView.isHidden = true
        preferences.set(true, forKey: "instructionsViewHiddenInAddTiffin")
        preferences.synchronize()
    }
    
    @IBAction func daySelection(_ sender: Any) {
        let button = sender as! UIButton
        //print(button.tag)
        //Su=101, M=102, T=103, W=104, Th=105, F=106, S=107
        if button.titleColor(for: .normal) == .red {
            button.setTitleColor(.green, for: .normal)
            weekdays.insert(button.titleLabel!.text!)
        } else {
            button.setTitleColor(.red, for: .normal)
            weekdays.remove(button.titleLabel!.text!)
        }
    }
    
    @IBAction func addUpdateData(_ sender: Any) {
        if checkValidations() {
            if segueName == "ADD" {
                //Add New Data
                ///*
                dataHandler.sharedInstance.saveTiffinData(name: tiffinName.text!, phone: tiffinPhone.text!, weekdays: weekdays, cost: Int(tiffinCost.text!)!, balance: Int(tiffinBalance.text!)!, totalDays: 0, startingDate: Date().toLocalStart())
                //*/
                /* This code is to test by setting starting date as 2 days ago
                let calendar = Calendar.current
                let daysAgo = calendar.date(byAdding: .day, value: -2, to: Date())
                dataHandler.sharedInstance.saveTiffinData(name: tiffinName.text!, weekdays: weekdays, cost: Int(tiffinCost.text!)!, balance: Int(tiffinBalance.text!)!, totalDays: 0, startingDate: daysAgo!)
                */
            } else {
                //Update Data
                tiffinObject!.name = tiffinName.text
                tiffinObject!.phone = tiffinPhone.text
                tiffinObject!.cost = Int64(tiffinCost.text!)!
                let bal = Int64(tiffinBalance.text!)! + (tiffinObject!.cost * Int64(deliveredDatesArray.count))
                tiffinObject!.balance = bal
                tiffinObject!.weekdays = weekdays as NSObject
            }
            self.navigationController?.popViewController(animated: true)
        } else {
            if (tiffinPhone.text?.isValid(regex: .phone))! {
                sendAlert(title: "Error", message: "Please fill all details, including the tiffin days")
            }
        }
    }
    
    // MARK: - Contacts
    @IBAction func selectFromContactBook(_ sender: Any) {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            let contactStore = CNContactStore.init()
            contactStore.requestAccess(for: .contacts, completionHandler: { (status, error) in
                if status  {
                    self.loadContacts()
                }else {
                    // Tell user it is denied
                    self.sendAlert(title: "Access Denied", message: "The app does not have access to your contacts, please allow access (from Settings > Tiffin Tracker) to use this functionality")
                }
            })
        case .authorized: self.loadContacts(); break
        case .denied,
             .restricted:
            // Tell user it is denied
            sendAlert(title: "Access Denied", message: "The app does not have access to your contacts, please allow access (from Settings > Tiffin Tracker) to use this functionality")
            break
        }
    }
    
    func loadContacts() {
        contacts.removeAll()
        filteredContacts.removeAll()
        let contactStore = CNContactStore.init()
        let keys = [CNContactPhoneNumbersKey, CNContactGivenNameKey]
        let request = CNContactFetchRequest.init(keysToFetch: keys as [CNKeyDescriptor])
        
        try! contactStore.enumerateContacts(with: request) { (contact, stop) in
            for object:CNLabeledValue in contact.phoneNumbers {
                let mobileObject  = object.value
                let mobile = mobileObject.value(forKey: "digits") as? String
                var givenName = contact.givenName
                if givenName.isEmpty == true {
                    givenName = "Unknown"
                }
                let cmodel = contactModel.init(name: givenName, phone: mobile!)
                self.contacts.append(cmodel)
            }
        }
        DispatchQueue.main.async {
            self.myTableView.reloadData()
            self.showHideContactsView(hidden: false)
        }
    }
    
    // MARK: - Alert Controller
    func sendAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.layer.cornerRadius = 20.0
        let dismiss = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alert.addAction(dismiss)
        self.present(alert, animated: true, completion: nil)
    }
}

extension AddTiffin {
    func updateButtonOutlets(set: Set<String>) {
        if set.contains("Sun") {
            sunButtonOutlet.setTitleColor(.green, for: .normal)
        }
        if set.contains("Mon") {
            monButtonOutlet.setTitleColor(.green, for: .normal)
        }
        if set.contains("Tue") {
            tueButtonOutlet.setTitleColor(.green, for: .normal)
        }
        if set.contains("Wed") {
            wedButtonOutlet.setTitleColor(.green, for: .normal)
        }
        if set.contains("Thu") {
            thuButtonOutlet.setTitleColor(.green, for: .normal)
        }
        if set.contains("Fri") {
            friButtonOutlet.setTitleColor(.green, for: .normal)
        }
        if set.contains("Sat") {
            satButtonOutlet.setTitleColor(.green, for: .normal)
        }
    }
    
    func checkValidations() -> Bool {
        if tiffinName.text == "" || tiffinCost.text == "" || tiffinBalance.text == "" || tiffinPhone.text == "" || weekdays.count == 0 {
            return false
        } else {
            if !(tiffinPhone.text?.isValid(regex: .phone))! {
                sendAlert(title: "Error", message: "Phone number is not in a proper format.")
                return false
            } else { return true }
        }
    }
    
    @objc func handleTap (gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func showHideContactsView(hidden: Bool) {
        contactsView.isHidden = hidden
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            // In iOS 11, we need to constrain the view to the safe area.
            positionBannerViewFullWidthAtBottomOfSafeArea(bannerView)
        }
        else {
            // In lower iOS versions, safe area is not available so we use
            // bottom layout guide and view edges.
            positionBannerViewFullWidthAtBottomOfView(bannerView)
        }
    }
    
    
    // MARK: - Table View
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearching { tiffinPhone.text = filteredContacts[indexPath.row].phone }
        else { tiffinPhone.text = contacts[indexPath.row].phone }
        DispatchQueue.main.async {
            self.showHideContactsView(hidden: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching { return filteredContacts.count }
        else { return contacts.count }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MyCell")
        if isSearching {
            cell.textLabel!.text = "\(filteredContacts[indexPath.row].name ?? "")"
            cell.detailTextLabel!.text = "\(filteredContacts[indexPath.row].phone ?? "")"
        } else {
            cell.textLabel!.text = "\(contacts[indexPath.row].name ?? "")"
            cell.detailTextLabel!.text = "\(contacts[indexPath.row].phone ?? "")"
        }
        return cell
    }
    
    // MARK: - Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == "" {
            isSearching = false
            //view.endEditing(true)
        } else {
            filteredContacts = contacts.filter({($0.name?.containsIgnoringCase(find: searchBar.text!))!})
            isSearching = true
        }
        myTableView.reloadData()
    }
    
    // MARK: - view positioning
    @available (iOS 11, *)
    func positionBannerViewFullWidthAtBottomOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Make it constrained to the edges of the safe area.
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            guide.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
            guide.rightAnchor.constraint(equalTo: bannerView.rightAnchor),
            guide.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor)
            ])
    }
    
    func positionBannerViewFullWidthAtBottomOfView(_ bannerView: UIView) {
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: view.safeAreaLayoutGuide,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0))
    }
}

class contactModel:NSObject {
    var name:String?
    var phone:String?
    var selected:Bool?
    
    init(name:String,phone:String) {
        self.name = name
        self.phone = phone
        self.selected = false
    }
}

