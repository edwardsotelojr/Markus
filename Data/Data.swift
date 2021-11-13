//
//  Data.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 11/4/21.
//

import Foundation
import CoreMotion
import HealthKit
class Data {
    func getData(){
        let healthKitTypes: Set = [
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
             // Requests permission to save and read the specified data types.
               // healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
        
    }
}
