//
//  InterfaceController.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 10/22/21.
//

import WatchKit
import Foundation
import Alamofire
import SwiftyJSON
import HealthKit

enum InterfaceState {
  case instantiated
  case awake
  case initialized
}

class InterfaceController: WKInterfaceController/*, MemoStoreObserver*/ {
    var interfaceState = InterfaceState.instantiated
    var timer: Timer?
    @IBOutlet weak var VerificationCode: WKInterfaceLabel!
    var memos: [VoiceMemo] = []
    var verificationCode = ""
    let markusSerial = WKInterfaceDevice.current().identifierForVendor?.uuidString
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(heartRate), userInfo: nil, repeats: true)
        interfaceState = .awake
            let parameters = ["MarkusSerial": markusSerial]
            var code = ""
            AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/requestCode",
                method: HTTPMethod.post, parameters: parameters).response { response in
                    let str = String(decoding: response.data!, as: UTF8.self)
                    print(str)
                    let start = String.Index(utf16Offset: 13, in: str)
                    let end = String.Index(utf16Offset: str.count, in: str)
                    print(String(str[start..<end]))
                    code = String(str[start..<end])
                    self.verificationCode = code
                    let len = code.count-1
                    var index = 1
                    var iteration = 1
                    let character = " " as Character
                    while(iteration <= len){
                        code.insert(character, at: str.index(str.startIndex, offsetBy: index))
                        index = index + 2
                        iteration = iteration+1
                    }
                    print(code)
                    self.VerificationCode.setText(code)
                    print(self.markusSerial!)
            }
    }
    
    private func processRecordedAudio(at url: URL) {
        let voiceMemo = VoiceMemo(filename: url.lastPathComponent, date: Date())
        print("filename: \(url.lastPathComponent)")
      //MemoStore.shared.add(memo: voiceMemo)
      //MemoStore.shared.save()
    }
    
    @objc func heartRate() {
     // 1. Create a heart rate BPM Sample
       let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
       let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"),
       doubleValue: Double(arc4random_uniform(80) + 100))
        let heartSample = HKQuantitySample(type: heartRateType,
            quantity: heartRateQuantity, start: NSDate() as Date, end: NSDate() as Date)
       print(heartRateQuantity)
   }
    
    @objc func runTimedCode(){
        print("parameters for validateCode:\(verificationCode), markusSerial: \(markusSerial!)")
        let parameters = ["verification": verificationCode, "markusSerial": markusSerial]
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/validateCode",
                   method: HTTPMethod.post, parameters: parameters).response { response in
            let str = String(decoding: response.data!, as: UTF8.self)
            if(true){
                print(str)
            }else{
                print(str)
            }
        }
    }
    
/*
    func memoStore(store: MemoStore, didUpdateMemos memos: [VoiceMemo]) {
      self.memos = memos
      //reloadInterface()
    }
*/
    
    @IBAction func startRecording() {
        let outputURL = MemoFileNameHelper.newOutputURL()
        let preset = WKAudioRecorderPreset.narrowBandSpeech // 8 kHz sampling rate.
        let options: [String : Any] = [WKAudioRecorderControllerOptionsMaximumDurationKey: 30]
        presentAudioRecorderController(
          withOutputURL: outputURL,
          preset: preset,
          options: options) { [weak self] (didSave: Bool, error: Error?) in
            print("outputURL: \(outputURL)")
            print("Did save? \(didSave) - Error: \(String(describing: error))")
            guard didSave else { return }
            self?.processRecordedAudio(at: outputURL)
        }
    }
    
    func fetchHealthData() -> Void {
        let healthStore = HKHealthStore()
        if HKHealthStore.isHealthDataAvailable() {
                //rest of the code will be here
                let readData = Set([
                    HKObjectType.quantityType(forIdentifier: .heartRate)!
                ])
                healthStore.requestAuthorization(toShare: [], read: readData) { (success, error) in
                    if success {
                    //do the actual data calling here
                        print(readData)
                    } else {
                        print("Authorization failed")
                    }
                }
        }
    }
}
