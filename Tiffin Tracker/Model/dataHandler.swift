//
//  dataHandler.swift
//  Tiffin Tracker
//
//  Created by RG on 3/14/18.
//  Copyright © 2018 RG. All rights reserved.
//

import UIKit
import Foundation
import CoreData

struct dataHandler {
    
    static let sharedInstance = dataHandler()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var managedObjectContext: NSManagedObjectContext?
    
    init() {
        managedObjectContext = appDelegate.persistentContainer.viewContext
    }
    
    func saveTiffinData(name: String, phone: String, weekdays: Set<String>, cost: Int, balance: Int, totalDays: Int, startingDate: Date) {
        let tiffin = Tiffin(context: managedObjectContext!)
        tiffin.name = name
        tiffin.phone = phone
        tiffin.weekdays = weekdays as NSObject
        tiffin.cost = Int64(cost)
        tiffin.balance = Int64(balance)
        tiffin.totalDays = Int64(totalDays)
        tiffin.startingDate = startingDate as NSDate
        appDelegate.saveContext()
    }
    
    func saveTiffinContext() {
        appDelegate.saveContext()
    }
    
    func getTiffinData () -> Array<Tiffin> {
        let fetchRequest: NSFetchRequest<Tiffin> = Tiffin.fetchRequest()
        do {
            let tiffin = try managedObjectContext?.fetch(fetchRequest)
            return tiffin!
        } catch {
            // Returning an empty Array - Error Handling
            let tiffin = [Tiffin]()
            return tiffin
        }
    }
    
    func deleteObject (obj: NSManagedObject) {
        managedObjectContext!.delete(obj)
        saveTiffinContext()
    }
    
    func deleteAllTiffinData () {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tiffin")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try managedObjectContext?.execute(deleteRequest)
        } catch {
            // Error Handling
        }
    }
    
    func sortWeekdays (weekdays: Set<String>) -> Array<String> {
        var array = Array<String>()
        if weekdays.contains("Sun") {
            array.append("Sun")
        }
        if weekdays.contains("Mon") {
            array.append("Mon")
        }
        if weekdays.contains("Tue") {
            array.append("Tue")
        }
        if weekdays.contains("Wed") {
            array.append("Wed")
        }
        if weekdays.contains("Thu") {
            array.append("Thu")
        }
        if weekdays.contains("Fri") {
            array.append("Fri")
        }
        if weekdays.contains("Sat") {
            array.append("Sat")
        }
        return array
    }
    
    func setColor (r:CGFloat, g:CGFloat, b:CGFloat) -> UIColor {
        return UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}

extension String {
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    enum RegularExpressions: String {
        case phone = "^\\s*(?:\\+?(\\d{1,3}))?([-. (]*(\\d{3})[-. )]*)?((\\d{3})[-. ]*(\\d{2,4})(?:[-.x ]*(\\d+))?)\\s*$"
    }
    
    func isValid(regex: RegularExpressions) -> Bool {
        return isValid(regex: regex.rawValue)
    }
    
    func isValid(regex: String) -> Bool {
        let matches = range(of: regex, options: .regularExpression)
        return matches != nil
    }
    
    func onlyDigits() -> String {
        let filtredUnicodeScalars = unicodeScalars.filter{CharacterSet.decimalDigits.contains($0)}
        return String(String.UnicodeScalarView(filtredUnicodeScalars))
    }
    
    func call() {
        if isValid(regex: .phone) {
            if let url = URL(string: "tel://\(self.onlyDigits())"), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 11, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    static func random(length: Int = 10) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
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
    //Convert UTC (or GMT) to local time with 00:00:00
    func toLocalStart() -> Date {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat="yyyy-MM-dd 00:00:00 Z"
        return formatter.date(from: formatter.string(from: Date().toLocalTime()))!
    }
    //Convert UTC (or GMT) to local time with 10:00:00
    func toLocalTen() -> Date {
        return Calendar.current.date(byAdding: .hour, value: 10, to: Date().toLocalStart())!
    }
    
    func remindTomorrow() -> Double {
        var component = Calendar.current.dateComponents([.second], from: Date())
        var seconds: Double = 0
        if Date().toLocalTime() > Date().toLocalTen() {
            component = Calendar.current.dateComponents([.second], from: Date().toLocalTen(), to: Date().toLocalTime())
            seconds = Double(86400 - component.second!) // 1 day = 86400 seconds
        } else {
            component = Calendar.current.dateComponents([.second], from: Date().toLocalTime(), to: Date().toLocalTen())
            seconds = Double(86400 + component.second!)
        }
        return seconds
    }
}

