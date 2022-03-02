//
//  ExtensionDelegate.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 10/22/21.
//

import WatchKit
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, WKExtendedRuntimeSessionDelegate {
  
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("runTimeSession")
        print(reason)
        if((error) != nil){
            print(error ?? "error runtime session")
        }
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("extended runtime session did start")
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("expired")
    }
    
    var runTimeSession: WKExtendedRuntimeSession!

    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
            print("here in application did become active in Extension Delegate")
    }

    /*func scheduleNextReload() {
        var targetDate:Date
        let currentDate = Date()
        targetDate = currentDate.addingTimeInterval(4)

        print("ExtensionDelegate: scheduling next update at %@", "\(targetDate)")

        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: targetDate,
            userInfo: nil,
            scheduledCompletion: { error in
                // contrary to what the docs say, this is called when the task is scheduled, i.e. immediately
                NSLog("ExtensionDelegate: background task %@",
                      error == nil ? "scheduled successfully" : "NOT scheduled: \(error!)")
            }
        )
    }
    */
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        print("here in application will resign active in Extension Delegate")
        //scheduleNextReload()
        runTimeSession = WKExtendedRuntimeSession()
        runTimeSession.delegate = self
        runTimeSession.start()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        print("herein handle", backgroundTasks)
        print("\n\n")
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
              
                        // once we're done updating the data, we ask the complication server to reload our active complications
                        //self.updateActiveComplications()

                        // we then schedule the next background refresh
                //self.scheduleNextReload()
                        // then we complete the current task, we pass `false` to indicate that no snapshot is needed.
                        // Each complication update results in a snapshot request, so we don't have to request one separately.
                        backgroundTask.setTaskCompletedWithSnapshot(false)
                    print("backgroundTask")
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                //self.scheduleNextReload()

                print("snapshotTask")

                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                print("connectivityTask")

                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                print("url session task")

                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                print("relevant shortcut task")

                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                print("intent did run task")

                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
                print("set task complete")

            }
        }
    }

}
