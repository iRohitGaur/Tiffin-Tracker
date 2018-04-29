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
    
    func saveTiffinData(name: String, weekdays: Set<String>, cost: Int, balance: Int, totalDays: Int, startingDate: Date) {
        let tiffin = Tiffin(context: managedObjectContext!)
        tiffin.name = name
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
