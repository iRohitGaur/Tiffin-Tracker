//
//  NotificationHandler.swift
//  Tiffin Tracker
//
//  Created by RG on 5/28/18.
//  Copyright © 2018 RG. All rights reserved.
//

import UIKit
import Foundation
import UserNotifications

class NotificationHandler: NSObject {
    static let si = NotificationHandler()
    let day: Double = 86400
    
    struct Notification {
        struct Category {
            static let tifCat = "tifCat"
        }
        struct Action {
            static let remindTomorrow = "remindTomorrow"
        }
    }
    
    // MARK: - Notification Methods
    func configureUserNotificationsCenter() {
        // Configure User Notification Center
        UNUserNotificationCenter.current().delegate = self
        
        // Define Actions
        let actionRemind = UNNotificationAction(identifier: Notification.Action.remindTomorrow, title: "Remind Me Tomorrow", options: [.destructive, .authenticationRequired])
        
        // Define Category
        let tifCategory = UNNotificationCategory(identifier: Notification.Category.tifCat, actions: [actionRemind], intentIdentifiers: [], options: [])
        
        // Register Category
        UNUserNotificationCenter.current().setNotificationCategories([tifCategory])
    }
    
    func requestNotificationAuth() {
        // Request Notification Settings
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization(completionHandler: { (success) in
                    guard success else { return }
                })
            case .authorized:
                print("Application is authorized to Display Notifications")
            case .denied:
                print("Application Not Allowed to Display Notifications")
            case .provisional:
                print("extra")
            }
        }
    }
    
    private func requestAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        // Request Authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            completionHandler(success)
        }
    }
    
    func scheduleNotification(title: String, seconds: Double) {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = title //<name> has low Balance.
        notificationContent.body = "3D Touch / Swipe Left > View to see options. Select Remind to remind again tomorrow."
        
        // Set Category Identifier
        notificationContent.categoryIdentifier = Notification.Category.tifCat
        
        // Add Trigger
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: "\(String.random())_tracker", content: notificationContent, trigger: notificationTrigger)
        
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

extension NotificationHandler: UNUserNotificationCenterDelegate {
    // MARK: - Notification Delegate Methods
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case Notification.Action.remindTomorrow:
            print("Remind Tomorrow")
            scheduleNotification(title: response.notification.request.content.title, seconds: Date().remindTomorrow())
        default:
            print("Other Action")
        }
        
        completionHandler()
    }
}
