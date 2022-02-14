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
import CoreLocation
import AVFAudio
import UIKit

class trash: WKInterfaceController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @IBOutlet weak var VerificationCodeLabel: WKInterfaceLabel!
    @IBOutlet weak var VerificationCode: WKInterfaceLabel!
    @IBOutlet weak var heartRate: WKInterfaceLabel!
    var currentLocation = CLLocation()
    var lat:Double = 0.0
    var long:Double = 0.0
    var verificationCode = ""
    let markusSerial = WKInterfaceDevice.current().identifierForVendor?.uuidString
    var markusId = -1
    var status: Int = -1
    var meterTimer:Timer!
    var isAudioRecordingGranted: Bool!
    var isRecording = false
    var filename = ""
    var previousFilename = ""
    var filenameCount = 0
    var audioRecorder: AVAudioRecorder?
    var audioPlayer:AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()
    var timer: Timer?
    
    func check_record_permission() //
    {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            print("granted record permission")
            isAudioRecordingGranted = true
            break
        case AVAudioSession.RecordPermission.denied:
            print("denied record permission")
            isAudioRecordingGranted = false
            break
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (allowed) in
                    if allowed {
                        print("allowed")
                        self.isAudioRecordingGranted = true
                    } else {
                        print("not allowed")
                        self.isAudioRecordingGranted = false
                    }
            })
            break
        default:
            break
        }
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func getFileUrl() -> URL
    {
        filename = "myRecording" + String(filenameCount) + ".wav"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func getCommandCode(response: String) -> Int{
        var status:Int = 0;
        var statusString: String = ""
        var index: Int = 0
        if let range: Range<String.Index> = response.range(of: "CommandCode:") {
            index = response.distance(from: response.startIndex, to: range.lowerBound)
            let start = response.index(response.startIndex, offsetBy: index+12)
            let end = response.index(response.endIndex, offsetBy: -(response.count-index-13))
            let range = start..<end
            statusString = String(response[range])
            if(statusString == "0"){
                status = 0
            }else if(statusString == "1"){
                status = 1
            }
        }
        return status
    }
    
    @objc func setup_recorder() // audio recorder prepared to record
    {
        print("here is setup_recorder")
        if isAudioRecordingGranted
        {
            do
            {
                try session.setCategory(AVAudioSession.Category.record)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVSampleRateKey: 11025,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                audioRecorder?.delegate = self
                let fileURL = getFileUrl()
                audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
                self.audioRecorder?.record(forDuration: 4.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                    if(self.audioRecorder?.isRecording == true){
                        print("still recording")
                    }else{
                        print("done recording")
                    }
                    let ddd = self.getDocumentsDirectory()
                    if(self.previousFilename.count > 0){
                        guard let data = try? Data(contentsOf: ddd.appendingPathComponent(self.previousFilename) ) else { print("returning"); return }
                        //self.audioRecorder?.stop()
                       // self.audioRecorder.
                        self.audioRecorder = nil
                        
                        AF.upload(multipartFormData: { MultipartFormData in
                            MultipartFormData.append(data, withName: "soundFile" , fileName: self.previousFilename, mimeType: "audio/wav")
                            // for(key,value) in uploadDict {
                            //   MultipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                            //}
                        }, to: "http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/uploadSoundFile?id=4", method: .post)
                            .responseString { response in
                                print("Success: \(response.result)")
                                           print("Response String: \(response.result)")

                                print("uploadSoundFile: ", response)
                                print("filenameCount: ", self.filenameCount)
                                let str = String(decoding: response.data!, as: UTF8.self)

                                if((self.getCommandCode(response: str)) == 1){
                                    print("commandcode is 1\n")
                                    self.previousFilename = self.filename
                                    self.filenameCount = self.filenameCount + 1
                                    self.setup_recorder()
                                }
                                else{
                                    print("commandcode is 0\n")
                                }
                        }
                    }
                }
            }
            catch let error {
                print("error: ", error)
            }
        }
        else
        {
            print("Error:     Don't have access to use your microphone.")
        }
    }

    @objc func getHeartRate()
    {
     // 1. Create a heart rate BPM Sample
        //let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"),
        doubleValue: Double(arc4random_uniform(80) + 100))
        //let heartSample = HKQuantitySample(type: heartRateType,
        //    quantity: heartRateQuantity, start: NSDate() as Date, end: NSDate() as Date)
        self.heartRate.setText(String(Int(heartRateQuantity.doubleValue(for: HKUnit(from: "count/min")))) + " BPM")
        let  parameters: [String: Any] =  [ "id": 1,
                                    "lat": String(describing: self.lat),
                                    "lon": String(describing: self.long),
            "heartRate": Int(heartRateQuantity.doubleValue(for: HKUnit(from: "count/min")))
        ]
        
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/uploadMarkusData",
                   method: HTTPMethod.post, parameters: parameters).response { response in
            let str = String(decoding: response.data!, as: UTF8.self)
            print("reponse of uploadMarkusData: ", str)
        }
   }
    
    @objc func validateCodeRequest()
    {
        print("\nparameters for /validateCode:  { validateCode:\(verificationCode), markusSerial: \(markusSerial!) }")
        let parameters = ["verification": verificationCode, "markusSerial": markusSerial]
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/validateCode",
                   method: HTTPMethod.post, parameters: parameters).response { response in
            let str = String(decoding: response.data!, as: UTF8.self)
            print("\n", str, "\n")
            self.status = self.getStatus(response: str)
            if(self.status == 0){ //
                self.markusId = self.getMarkusId(response: str)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.validateCodeRequest()
                    
                }
            }
            else if(self.status == -1){ // error
                
            }
            else if(self.status == 1){ // used code
                print("status = 1")
                self.timer?.invalidate()
                self.timer = nil
                self.userValid(); // user is valid
                self.markusId = self.getMarkusId(response: str)
            }
        }
    }
    
    func userValid() -> Void
    {
        self.VerificationCode.setHidden(true);
        self.VerificationCodeLabel.setHidden(true);
        self.heartRate.setHidden(false);
        self.timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(getHeartRate), userInfo: nil, repeats: true)
        //self.timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(setup_recorder), userInfo: nil, repeats: true)
        self.setup_recorder();
    }
    
    func getStatus(response: String) -> Int{
        var status:Int = -1;
        var statusString: String = ""
        var index: Int = 0
        
        if let range: Range<String.Index> = response.range(of: "Status:") {
             index = response.distance(from: response.startIndex, to: range.lowerBound)
            let start = response.index(response.startIndex, offsetBy: index+7)
            let end = response.index(response.endIndex, offsetBy: -(response.count-index-8))
            let range = start..<end
            statusString = String(response[range])
            if(statusString == "-"){
                status = -1
            }else if(statusString == "0"){
                status = 0
            }else{
                status = 1
            }
        }
        return status
    }
    
    func getMarkusId(response: String) -> Int {
        var markusId = -1
        var markusIdString = ""
        var index = 0;
        
        if let range: Range<String.Index> = response.range(of: "MarkusId:") {
             index = response.distance(from: response.startIndex, to: range.lowerBound)
            let start = response.index(response.startIndex, offsetBy: index+9)
            let end = response.endIndex
            let range = start..<end
            markusIdString = String(response[range].trimmingCharacters(in: .whitespacesAndNewlines))
            if(markusIdString == "-1"){
                markusId = -1 // user never validated
            }
            else{
                markusId = Int(markusIdString)!
            }
        }
        return markusId
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lat = location.coordinate.latitude
            self.long = location.coordinate.longitude
            print("lat: ", self.lat)
            print("long: ", self.long)
            }
        }
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
       /* locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
                   locationManager.delegate = self
                   locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
                   locationManager.startUpdatingLocation()
               }
        */
        self.check_record_permission(); // audio recording permission
        let parameters = ["MarkusSerial": markusSerial]
        var code = ""
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/requestCode",
            method: HTTPMethod.post, parameters: parameters).response { response in
            print(response)
                let str = String(decoding: response.data!, as: UTF8.self)
                print("\n", str)
                let start = String.Index(utf16Offset: 13, in: str)
                let end = String.Index(utf16Offset: str.count, in: str)
                code = String(str[start..<end])
                self.verificationCode = code
                let len = code.count-1
                var index = 1
                var iteration = 1
                let character = " " as Character
                while(iteration <= len){ // space out verification code for UI Label
                    code.insert(character, at: str.index(str.startIndex, offsetBy: index))
                    index = index + 2
                    iteration = iteration+1
                }
            self.VerificationCode.setText(code) //UI Label
            //self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.validateCodeRequest), userInfo: nil, repeats: true)
            self.validateCodeRequest()
        }
    }
}
