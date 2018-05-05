//
//  ViewController.swift
//  Tiffin Tracker
//
//  Created by RG on 3/8/18.
//  Copyright © 2018 RG. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ViewController: UIViewController {
    
    @IBOutlet var noItemsView: UIView!
    @IBOutlet weak var tiffinTable: UITableView!
    var tiffinArray = Array<Tiffin>()
    var tiffinDaysArray = Array<String>()
    var count = 0
    var selectedIndex: Int = 0
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        getDataToUpdateTable()
        //Tap Gesture to dismiss Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        tapGesture.delegate = self as? UIGestureRecognizerDelegate
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
        /*
        //ADMOB
        var bannerView: GADBannerView!
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        //demo ID: ca-app-pub-3940256099942544/2934735716
        //Actual ID: ca-app-pub-4464278263822865/9612828739
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
 */
    }
    override func viewWillAppear(_ animated: Bool) {
        getDataToUpdateTable()
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ADD" {
            let tiffin = segue.destination as! AddTiffin
            tiffin.segueName = segue.identifier!
        }
        if segue.identifier == "tiffinDetails" {
            let cal = segue.destination as! CalenderViewController
            cal.tiffinObject = tiffinArray[selectedIndex]
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tiffinArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tiffinCell", for: indexPath) as! TiffinTableViewCell
        /*
        cell.tiffinNameLabel.text = "Test Name"
        cell.tiffinCostLabel.text = "65"
        cell.tiffinBalanceLabel.text = "5000"
        cell.tiffinDaysLabel.text = "Su  M  T  W  Th  F  S"
        */
        let arr = dataHandler.sharedInstance.sortWeekdays(weekdays: tiffinArray[indexPath.row].weekdays as! Set<String>)
        //print(arr)
        cell.tiffinNameLabel.text = tiffinArray[indexPath.row].name
        cell.tiffinCostLabel.text = String(tiffinArray[indexPath.row].cost)
        var deliveredDatesArray = Array<String>()
        if tiffinArray[indexPath.row].deliveredDates != nil {
            deliveredDatesArray = tiffinArray[indexPath.row].deliveredDates as! [String]
        }
        cell.tiffinBalanceLabel.text = String(tiffinArray[indexPath.row].balance - (tiffinArray[indexPath.row].cost * Int64(deliveredDatesArray.count)))
        cell.tiffinDaysLabel.text = arr.joined(separator: " ")
        //do set to array here
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        
        //Perform Segue
        self.performSegue(withIdentifier: "tiffinDetails", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Delete Entry
        dataHandler.sharedInstance.deleteObject(obj: tiffinArray[indexPath.row])
        tiffinArray.remove(at: indexPath.row)
        getDataToUpdateTable()
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action1 = UIContextualAction(style: .normal, title: nil) { (contextAction, sourceView, completionHandler) in
            self.alertToAddBalance(index: indexPath.row)
            completionHandler(true)
        }
        action1.image = UIImage(named: "addBalance")
        action1.backgroundColor =  dataHandler.sharedInstance.setColor(r: 122, g: 129, b: 255)
        
        let action2 = UIContextualAction(style: .normal, title: nil) { (contextAction, sourceView, completionHandler) in
            // CALL the number here
            self.tiffinArray[indexPath.row].phone?.call()
            completionHandler(true)
        }
        action2.image = UIImage(named: "call")
        action2.backgroundColor =  dataHandler.sharedInstance.setColor(r: 50, g: 200, b: 50)
        
        let swipeConfig = UISwipeActionsConfiguration(actions: [action2, action1])
        return swipeConfig
    }
}

extension ViewController {
    func getDataToUpdateTable() {
        //Count is used to remove redundant calling of getData() and reloadData() by ViewDidLoad() & ViewWillAppear()
        if count != 1 {
            //This avoids the second call by ViewWillAppear() at the initial launch
            tiffinArray = dataHandler.sharedInstance.getTiffinData()
            calculateTotalDays()
        }
        if count>1 {
            //This avoids the calls at 0 and 1 (as TableView will handle it in beginning by itself)
            tiffinTable.reloadData()
        }
        //Set a NoItemsView if no data for Table View
        if tiffinArray.count == 0 {
            tiffinTable.backgroundView = noItemsView
        } else {
            tiffinTable.backgroundView = nil
        }
        //Increase counter everytime this method is called
        count+=1
    }
    
    func calculateTotalDays() {
        //calc total days here
        for tiffins in tiffinArray {
            let tiffinDays = tiffins.weekdays as! Set<String>
            print(tiffinDays)
            var date = tiffins.startingDate! as Date
            print("Starting Date: \(date)")
            let endDate = Date().toLocalStart() // last date
            var deliveredDatesArray = Array<String>()
            if tiffins.deliveredDates != nil {
                deliveredDatesArray = tiffins.deliveredDates as! [String]
            }
            while date <= endDate {
                let day = Date().toLocalStart().dayOfTheWeek(date: date)
                if tiffinDays.contains(day!) {
                    let dateStr = date.dayMonthYear(date: date)
                    if !deliveredDatesArray.contains(dateStr) {
                        deliveredDatesArray.append(dateStr)
                        print(deliveredDatesArray)
                    }
                }
                date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            }
            //Setting the end date and starting date
            tiffins.totalDays = Int64(deliveredDatesArray.count)
            tiffins.startingDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)! as NSDate
            //Setting Delivered dates in Object Instance
            tiffins.deliveredDates = deliveredDatesArray as NSObject
            dataHandler.sharedInstance.saveTiffinContext()
        }
    }
    
    func alertToAddBalance(index: Int) {
        let alert = UIAlertController.init(title: "Add Balance", message: "Please enter the amount of balance you want to add to your Tiffin account.", preferredStyle: .alert)
        alert.view.backgroundColor = .blue
        alert.view.layer.cornerRadius = 20.0
        //Add Text Field
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Enter Amount"
            textField.keyboardType = .numberPad
        })
        //Save Action
        let saveAction = UIAlertAction(title: "Add", style: .default, handler: { alerts -> Void in
            let firstTextField = alert.textFields![0] as UITextField
            if firstTextField.text != "" {
                //Adding Balance
                self.tiffinArray[index].balance += Int64(firstTextField.text!)!
                //Saving context
                dataHandler.sharedInstance.saveTiffinContext()
                //Reloading Table with new Data
                self.tiffinTable.reloadData()
            }
        })
        //Dismiss Action
        let dismissAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        //Add actions to AlertController
        alert.addAction(saveAction)
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleTap (gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}

extension ViewController {
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



