//
//  AddTiffin.swift
//  Tiffin Tracker
//
//  Created by RG on 3/8/18.
//  Copyright © 2018 RG. All rights reserved.
//

import UIKit
import GoogleMobileAds

class AddTiffin: UIViewController {
    var weekdays = Set<String>()
    var deliveredDatesArray = Array<NSString>()
    var segueName = ""
    var index: Int = 0
    var tiffinObject: Tiffin?
    let preferences = UserDefaults.standard
    
    @IBOutlet weak var instructionsView: UIView!
    @IBOutlet weak var tiffinName: UITextField!
    @IBOutlet weak var tiffinCost: UITextField!
    @IBOutlet weak var tiffinBalance: UITextField!
    @IBOutlet weak var sunButtonOutlet: UIButton!
    @IBOutlet weak var monButtonOutlet: UIButton!
    @IBOutlet weak var tueButtonOutlet: UIButton!
    @IBOutlet weak var wedButtonOutlet: UIButton!
    @IBOutlet weak var thuButtonOutlet: UIButton!
    @IBOutlet weak var friButtonOutlet: UIButton!
    @IBOutlet weak var satButtonOutlet: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        if preferences.object(forKey: "instructionsViewHiddenInAddTiffin") != nil {
            instructionsView.isHidden = true
        }
        if segueName == "UPDATE" {
            self.navigationItem.title = "Update Tiffin"
            tiffinName.text = tiffinObject!.name
            tiffinCost.text = String(tiffinObject!.cost)
            deliveredDatesArray = tiffinObject!.deliveredDates as! Array<NSString>
            tiffinBalance.text = String(tiffinObject!.balance - (tiffinObject!.cost * Int64(deliveredDatesArray.count)))
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
        var bannerView: GADBannerView!
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        //demo ID: ca-app-pub-3940256099942544/2934735716
        //Actual ID: ca-app-pub-4464278263822865/4037778868
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
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
                dataHandler.sharedInstance.saveTiffinData(name: tiffinName.text!, weekdays: weekdays, cost: Int(tiffinCost.text!)!, balance: Int(tiffinBalance.text!)!, totalDays: 0, startingDate: Date().toLocalTime())
                //*/
                /* This code is to test by setting starting date as 2 days ago
                let calendar = Calendar.current
                let daysAgo = calendar.date(byAdding: .day, value: -2, to: Date())
                dataHandler.sharedInstance.saveTiffinData(name: tiffinName.text!, weekdays: weekdays, cost: Int(tiffinCost.text!)!, balance: Int(tiffinBalance.text!)!, totalDays: 0, startingDate: daysAgo!)
                */
            } else {
                //Update Data
                tiffinObject!.name = tiffinName.text
                tiffinObject!.cost = Int64(tiffinCost.text!)!
                let bal = Int64(tiffinBalance.text!)! + (tiffinObject!.cost * Int64(deliveredDatesArray.count))
                tiffinObject!.balance = bal
                tiffinObject!.weekdays = weekdays as NSObject
            }
            self.navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Error", message: "Please fill all details, including the tiffin days", preferredStyle: .alert)
            alert.view.backgroundColor = .blue
            alert.view.layer.cornerRadius = 20.0
            let dismiss = UIAlertAction(title: "Okay", style: .default, handler: nil)
            alert.addAction(dismiss)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func checkValidations() -> Bool {
        if tiffinName.text == "" || tiffinCost.text == "" || tiffinBalance.text == "" || weekdays.count == 0 {
            return false
        } else {
            return true
        }
    }
    
    @objc func handleTap (gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}

extension AddTiffin {
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

