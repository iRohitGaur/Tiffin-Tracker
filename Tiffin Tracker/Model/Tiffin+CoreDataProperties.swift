//
//  Tiffin+CoreDataProperties.swift
//  Tiffin Tracker
//
//  Created by RG on 3/19/18.
//  Copyright © 2018 RG. All rights reserved.
//
//

import Foundation
import CoreData


extension Tiffin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tiffin> {
        return NSFetchRequest<Tiffin>(entityName: "Tiffin")
    }

    @NSManaged public var balance: Int64
    @NSManaged public var cost: Int64
    @NSManaged public var deliveredDates: NSObject?
    @NSManaged public var name: String?
    @NSManaged public var startingDate: NSDate?
    @NSManaged public var totalDays: Int64
    @NSManaged public var weekdays: NSObject?

}
