//
//  HKUnit+BeatsPerMinute.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 3/1/22.
//

import HealthKit

extension HKUnit {

    static func beatsPerMinute() -> HKUnit {
        return HKUnit.count().unitDivided(by: HKUnit.minute())
    }
    
}
