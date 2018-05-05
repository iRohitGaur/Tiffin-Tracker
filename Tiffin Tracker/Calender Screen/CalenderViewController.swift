//
//  CalenderViewController.swift
//  Tiffin Tracker
//
//  Created by RG on 3/8/18.
//  Copyright © 2018 RG. All rights reserved.
//

import UIKit
import JTAppleCalendar
import GoogleMobileAds

class CalenderViewController: UIViewController {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var calenderView: JTAppleCalendarView!
    @IBOutlet weak var instructionsView: UIView!
    
    let preferences = UserDefaults.standard
    var flag = false
    let formatter = DateFormatter()
    var index: Int = 0
    var tiffinObject: Tiffin?
    var deliveredDatesArray = Array<String>()

    override func viewDidLoad() {
        super.viewDidLoad()
        if preferences.object(forKey: "instructionsViewHiddenInCalendar") != nil {
            instructionsView.isHidden = true
        }
        
        //Flag is used to ignore the first didSelect call
        flag = false
        
        //Setting in Array for Calender to show
        if tiffinObject!.deliveredDates != nil {
            deliveredDatesArray = tiffinObject!.deliveredDates as! Array<String>
            print(tiffinObject!.deliveredDates as! Array<String>)
        }
        
        
        //Set Tiffin Name on Navigation Title
        navigationItem.title = tiffinObject!.name
        
        //Fetch Selected Tiffin Object and Setup Selected Dates
        setupDates()
        
        //Setup Calender
        setupCalenderView()
        
        //ADMOB
        var bannerView: GADBannerView!
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        //demo ID: ca-app-pub-3940256099942544/2934735716
        //Actual ID: ca-app-pub-4464278263822865/2457227594
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //This checks if current VC is being removed from ParentVC
        //We need to call SaveContext only in this scenario as we save it in segue method while going in forward direction
        if self.isMovingFromParentViewController {
            saveToCoreData()
        }
    }
    
    @IBAction func dismissInstructionsView(_ sender: Any) {
        instructionsView.isHidden = true
        preferences.set(true, forKey: "instructionsViewHiddenInCalendar")
        preferences.synchronize()
    }
    
    func saveToCoreData() {
        //Setting Delivered Dates in the context array
        tiffinObject!.deliveredDates = deliveredDatesArray as NSObject
        //Save context in CoreData
        dataHandler.sharedInstance.saveTiffinContext()
    }
    
    func setupDates() {
        let tiffinDays = tiffinObject!.weekdays as! Set<String>
        var date = tiffinObject!.startingDate! as Date
        let endDate = Date().toLocalStart() // last date
        if tiffinObject!.deliveredDates != nil {
            deliveredDatesArray = tiffinObject!.deliveredDates as! [String]
        }
        while date <= endDate {
            let day = Date().toLocalStart().dayOfTheWeek(date: date)
            if tiffinDays.contains(day!) {
                let dateStr = date.dayMonthYear(date: date)
                if !deliveredDatesArray.contains(dateStr) {
                    deliveredDatesArray.append(dateStr)
                }
            }
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        //Setting the end date and starting date
        tiffinObject!.totalDays = Int64(deliveredDatesArray.count)
        tiffinObject!.startingDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)! as NSDate
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        saveToCoreData()
        let tiffin = segue.destination as! AddTiffin
        tiffin.segueName = segue.identifier!
        tiffin.tiffinObject = tiffinObject!
    }
    
    func setupCalenderView() {
        //Start calender with current date
        calenderView.scrollToDate( Date().toLocalStart(), animateScroll: false )
        calenderView.selectDates( [Date().toLocalStart()] )
        
        //Setup calender spacing
        calenderView.minimumLineSpacing = 0
        calenderView.minimumInteritemSpacing = 0
        
        //Setup Labels
        calenderView.visibleDates { visibleDates in
            self.setupViewsFromCalender(from: visibleDates)
        }
    }
    
    func setupViewsFromCalender(from visibleDates: DateSegmentInfo) {
        yearLabel.text = UTCToLocal(date: Date(), format: "yyyy")
        monthLabel.text = UTCToLocal(date: Date(), format: "MMM")
        dayLabel.text = UTCToLocal(date: Date(), format: "dd")
    }
    
    func handleCellTextColor (view: JTAppleCell?, cellState: CellState) {
        guard let validCell = view as? CalenderCell else { return }
        if cellState.dateBelongsTo == .thisMonth {
            validCell.dateLabel.textColor = .white
        } else {
            validCell.dateLabel.textColor = .lightGray
        }
        /*
        if cellState.isSelected {
            validCell.dateLabel.textColor = setColor(r: 84, g: 67, b: 160)
        } else {
            if cellState.dateBelongsTo == .thisMonth {
                validCell.dateLabel.textColor = .white
            } else {
                validCell.dateLabel.textColor = .lightGray
            }
        }
        */
    }
    
    func UTCToLocal(date:Date, format:String) -> String {
        formatter.dateFormat = "yyyy MM dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

extension CalenderViewController: JTAppleCalendarViewDataSource {
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.timeZone = TimeZone.current
        let currentYear: Int! = Calendar.current.dateComponents([.year], from: Date()).year
        let previousYear = currentYear - 1
        let currentYearString: String! = String(currentYear) + " 12 31"
        let previousYearString: String! = String(previousYear) + " 01 01"
        
        let startDate = formatter.date(from:previousYearString)?.toLocalStart()
        let endDate = formatter.date(from:currentYearString)?.toLocalStart()
        
        let parameters = ConfigurationParameters(startDate: startDate!, endDate: endDate!)
        return parameters
    }
}

extension CalenderViewController: JTAppleCalendarViewDelegate {
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        //
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        //set this for all the selected days
        //print(deliveredDatesArray)
        if deliveredDatesArray.contains (cellState.date.dayMonthYear(date: cellState.date)) {
            let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "selectedCell", for: indexPath) as! SelectedCell
            cell.dateLabel.text = cellState.text
            //handleCellTextColor(view: cell, cellState: cellState)
            return cell
        } else {
            let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "calendarCell", for: indexPath) as! CalenderCell
            cell.dateLabel.text = cellState.text
            handleCellTextColor(view: cell, cellState: cellState)
            return cell
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        let strDate = cellState.date.dayMonthYear(date: cellState.date)
        let todaysDate = Date().dayMonthYear(date: Date().toLocalStart())
        if strDate>todaysDate {
            let alert = UIAlertController(title: "How futuristic of you!", message: "As much as we love time travel, we wont be to able to select a future date as a delivered date of your Tiffin, for now.", preferredStyle: .alert)
            alert.view.backgroundColor = getRandomColor()
            alert.view.layer.cornerRadius = 20.0
            let dismissAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
            let future = UIAlertAction(title: "No, I can travel in time", style: .default) { (alertAction) in
                let jokeAlert = UIAlertController(title: "Kidding, aren't you!", message: "We hope you aren't serious. If you are, do consider sharing your secret with us.", preferredStyle: .alert)
                jokeAlert.view.backgroundColor = self.getRandomColor()
                jokeAlert.view.layer.cornerRadius = 20.0
                let jokeDismiss = UIAlertAction(title: "Okay, this never happened", style: .default, handler: nil)
                jokeAlert.addAction(jokeDismiss)
                self.present(jokeAlert, animated: true, completion: nil)
            }
            alert.addAction(dismissAction)
            alert.addAction(future)
            self.present(alert, animated: true, completion: nil)
        } else {
            if flag {
                if (cell?.isKind(of: CalenderCell.self))! {
                    //Add the cellstate date to dates entity
                    deliveredDatesArray.append(strDate)
                    print("Delivered dates are: \(deliveredDatesArray)")
                    /*
                     //Removed this functionality to give user flexibility of choosing days that are not in the tiffin delivery days
                     let day = cellState.date.toLocalStart().dayOfTheWeek(date: cellState.date)
                     if tiffinDaysArray.contains(day!) {
                     deliveredDatesArray.append(strDate)
                     } else {
                     //Show Alert that this day is not in the Tiffin Delivery Days
                     }
                     */
                } else {
                    //Remove the cellstate date from dates entity
                    deliveredDatesArray.remove(at: deliveredDatesArray.index(of: strDate)!)
                }
            }
            
            calenderView.reloadData()
            //Setting the flag true now will allow next didSelect calls to select current date as well. This was done as the 3rd party library makes an initial didSelect call on current date and our logic was adding it in Array
            if strDate == todaysDate {
                flag = true
            }
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.last!.date.toLocalStart()
        
        yearLabel.text = UTCToLocal(date: date, format: "yyyy")
        monthLabel.text = UTCToLocal(date: date, format: "MMM")
        
        if date.monthYear(date: date) == date.monthYear(date: Date().toLocalStart()) {
            UIView.transition(with: dayLabel, duration: 0.5, options: .transitionFlipFromLeft, animations: { self.dayLabel.isHidden = false })
        } else {
            UIView.transition(with: dayLabel, duration: 0.5, options: .transitionFlipFromLeft, animations: { self.dayLabel.isHidden = true })
        }
    }
}

extension Date {
    
    // Convert local time to UTC (or GMT)
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    //Returns Weekday on a particular Date
    func dayOfTheWeek(date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }
    //Returns Date in dd-MM-yyyy format
    func dayMonthYear(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        return dateFormatter.string(from:date)
    }
    
    func monthYear(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy"
        return dateFormatter.string(from:date)
    }
    
    // Convert UTC (or GMT) to local time with 00:00:00
    func toLocalStart() -> Date {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat="yyyy-MM-dd 00:00:00 Z"
        return formatter.date(from: formatter.string(from: Date().toLocalTime()))!
    }
    
    func dateFromDayBeginning(date: Date) -> Date {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat="yyyy-MM-dd 00:00:00 Z"
        return formatter.date(from: formatter.string(from: date))!
    }
}

extension CalenderViewController {
    func getRandomColor() -> UIColor{
        //Generate between 0 to 1
        let red:CGFloat = CGFloat(drand48())
        let green:CGFloat = CGFloat(drand48())
        let blue:CGFloat = CGFloat(drand48())
        
        return UIColor(red:red, green: green, blue: blue, alpha: 1.0)
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

