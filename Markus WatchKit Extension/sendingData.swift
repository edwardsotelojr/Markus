//
//  sendingData.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 11/23/21.
//

import WatchKit
import Foundation
import Alamofire
import SwiftyJSON
import HealthKit
import AVFAudio

class sendingData: WKInterfaceController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        print("sending data")
    }
}
