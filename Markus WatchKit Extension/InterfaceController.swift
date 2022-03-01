//
//  InterfaceController.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 10/22/21.
//

import WatchKit
import Foundation
import Alamofire
import HealthKit
import CoreLocation
import CoreMotion
import AVFAudio
import AVFoundation
import UIKit
import UserNotifications

class InterfaceController: WKInterfaceController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var markusLogo: WKInterfaceImage!
    @IBOutlet weak var commandCode1: WKInterfaceImage!
    let locationManager = CLLocationManager()
    @IBOutlet weak var VerificationCodeLabel: WKInterfaceLabel!
    @IBOutlet weak var VerificationCode: WKInterfaceLabel!
    @IBOutlet weak var listening: WKInterfaceLabel!
    var currentLocation = CLLocation()
    var lat:Double = 0.0
    var long:Double = 0.0
    var pre:Double = 0.0
    var alt:Double = 0.0
    var hum:Double = 0.0
    var temp:Double = 0.0
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
    var record = false
    var audioRecorder: AVAudioRecorder?
    var audioPlayer:AVAudioPlayer?
    private let session = AVAudioSession.sharedInstance()
    var timer: Timer?
    var displayingRed = false
    private let healthStore = HKHealthStore()
    var relativeAltitude: NSNumber = 0
    var altitude = 0
    let altimeter = CMAltimeter()

    
       func update(d: CMAltitudeData?, e: Error?){
           print("altitude \(altitude)")
           print("CMAltimeter \(altimeter)")
           print("relative Altitude \(relativeAltitude))")
       }
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        if #available(watchOSApplicationExtension 8.0, *) {
            print(CMAltimeter.isAbsoluteAltitudeAvailable())
        } else {
            // Fallback on earlier versions
        }
        if CMAltimeter.isRelativeAltitudeAvailable() {
                   switch CMAltimeter.authorizationStatus() {
                    case .notDetermined: // Handle state before user prompt
                    print("bb")
                    //fatalError("Awaiting user prompt...")
                    case .restricted: // Handle system-wide restriction
                    fatalError("Authorization restricted!")
                    case .denied: // Handle user denied state
                    fatalError("Authorization denied!")
                    case .authorized: // Ready to go!
                    let _ = print("Authorized!")
                    @unknown default:
                    fatalError("Unknown Authorization Status")
                    }
                   self.altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) {(data,error) in DispatchQueue.main.async {
                       print("\(self.altitude)")
                       print("\(self.relativeAltitude)")
                   }
               }
           }
        else{
            print("false")
        }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                // Handle the error here.
            }
            
            // Enable or disable features based on the authorization.
        }
        
        self.VerificationCode.setText("") //UI Label
        self.check_recording_permission(); // audio recording permission
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let readTypes = Set([heartRateType])
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                   
                   if let error = error {
                       print(error)
                   }
               }
       // locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
                   locationManager.delegate = self
                   locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
                   locationManager.startUpdatingLocation()
               }
        self.requestCode()
     
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lat = location.coordinate.latitude
            self.long = location.coordinate.longitude
            print("lat: ", self.lat)
            print("long: ", self.long)
            }
        }
    
    func check_recording_permission()
    {
        print(type(of: AVAudioSession.sharedInstance().recordPermission))
        print(AVAudioSession.sharedInstance().recordPermission)
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                print("granted")
                self.isAudioRecordingGranted = true
                self.record = true
            } else{
                print("not granted")
                self.isAudioRecordingGranted = false

            }
        })
       /* switch AVAudioSession.sharedInstance().recordPermission {
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
        }*/
    }
    
    func requestCode() -> Void{
        let parameters = ["MarkusSerial": markusSerial]
        var code = ""
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/requestCode",
            method: HTTPMethod.post, parameters: parameters).response { response in
                /*if(response.data == nil){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    print("error on request Code")
                    self.requestCode()
                    return
                    }
                }*/
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
            self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.validateCodeRequest), userInfo: nil, repeats: true)
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
    
    
    
    @objc func record() // audio recorder prepared to record
    {
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
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder?.delegate = self
                self.audioRecorder?.record(forDuration: 1.5)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    let ddd = self.getDocumentsDirectory()
                    if(self.previousFilename.count > 0){
                        guard let data = try? Data(contentsOf: ddd.appendingPathComponent(self.previousFilename) ) else { return }
                        self.audioRecorder?.stop()
                        self.audioRecorder = nil
                        AF.upload(multipartFormData: { MultipartFormData in
                            MultipartFormData.append(data, withName: "soundFile" , fileName: self.previousFilename, mimeType: "audio/wav")
                        }, to: "http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/uploadSoundFile?id=4", method: .post)
                            .responseString { response in
                                if(response.data == nil){
                                    return
                                }
                                print("uploadSoundFile: ", response)
                                let str = String(decoding: response.data!, as: UTF8.self)
                                print("filename: ", self.previousFilename)
                                if((self.getCommandCode(response: str)) == 0){ // CHANGE BACK TO 1
                                    print("commandcode is 1")
                                    self.meltdown()
                                }
                                if(self.previousFilename == "myRecording4.wav"){
                                    self.meltdown()
                                }
                                self.record()
                                self.sendData()
                        }
                    }
                }
                self.previousFilename = self.filename
                self.filenameCount = self.filenameCount + 1
            }
            catch let error {
                print("error: ", error)
            }
        }
        else
        {
            print("Error:  Don't have access to use your microphone.")
        }
    }
    
    func triggerNotification() -> Void {
        let content = UNMutableNotificationContent()
        content.title = "Meltdown Alert"
        content.subtitle = "meltdown was detected"
        content.sound = .default
        content.categoryIdentifier = "myCategory"
        let category = UNNotificationCategory(identifier: "myCategory", actions: [], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4, repeats: false)
        let request = UNNotificationRequest(identifier: "myCategory", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
        if let error = error{
        print("error ", error.localizedDescription)
        }else{
        print("scheduled successfully")
        }
        }
    }

    func meltdown() -> Void {
        //let notification = UIUserNotificationAction(identifer: "done", title: "Done:", options: .foreground)
        self.triggerNotification()
        self.playSound()
        self.commandCode1.setHidden(false)
        self.listening.setHidden(true);
        self.markusLogo.setHidden(true)
        self.displayingRed = true
        if(!displayingRed){
            self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.toggleOffMeltdown), userInfo: nil, repeats: false)
        }
        else {
            self.timer?.invalidate()
            self.timer = nil
            self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.toggleOffMeltdown), userInfo: nil, repeats: false)
        }
    }
    
    @objc func toggleOffMeltdown() -> Void {
            self.commandCode1.setHidden(true)
            self.listening.setHidden(false);
            self.markusLogo.setHidden(false)
    }
    
    @objc func getHeartRate() -> Int
    {
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let heartRateQuantity = HKUnit(from: "count/min")
       
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        // 2
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else {
                       return
                   }
         /*   for sample in samples {
                if sample.quantityType == HKQuantityType {
                    print(sample.quantity.doubleValue(for: heartRateQuantity))
                   }
                   
                   //self.value = Int(lastHeartRate)
               }
           }*/
    }

        //let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"),
        //doubleValue: Double(arc4random_uniform(80) + 100))
        //let heartSample = HKQuantitySample(type: heartRateType,
          //  quantity: heartRateQuantity, start: NSDate() as Date, end: NSDate() as Date)
        return /*Int(heartRateType.doubleValue(for: heartRateQuantity))*/1

        //return Int(heartRateQuantity.doubleValue(for: HKUnit(from: "count/min")))
   }
    
    
    @IBAction func stopMarkus() {
        
    }
    
    @objc func validateCodeRequest()
    {
        print("\nparameters for /validateCode:  { validateCode:\(verificationCode), markusSerial: \(markusSerial!) }")
        let parameters = ["verification": verificationCode, "markusSerial": markusSerial]
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/validateCode",
                   method: HTTPMethod.post, parameters: parameters).response { response in
            if(response.data == nil){
                return
            }
            let str = String(decoding: response.data!, as: UTF8.self)
            print("\n", str, "\n")
            self.status = self.getStatus(response: str)
            if(self.status == 0){ //
                //self.timer?.invalidate()
                //self.timer = nil
                self.markusId = self.getMarkusId(response: str)
            }
            else if(self.status == -1){ // error
                
            }
            else if(self.status == 1){ // used code
                self.timer?.invalidate()
                self.timer = nil
                self.userValid(); // user is valid
                self.markusId = self.getMarkusId(response: str)
            }
        }
    }
    
    func playSound() -> Void {
        
            WKInterfaceDevice.current().play(.notification)
        /*let soundPath = Bundle.main.path(forResource: "Hotnigga 144p", ofType: "wav")
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundPath!))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1
            ) {

                self.audioPlayer?.play()
            }
        }
        catch{
            print("error: ", error)
        }*/
    }
    
    func userValid() -> Void
    {
        self.VerificationCode.setHidden(true);
        self.VerificationCodeLabel.setHidden(true);
        self.listening.setHidden(false);
        //self.timer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(setup_recorder), userInfo: nil, repeats: true)
        self.record();
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
    
    func sendData() {
        let heartRate = getHeartRate()
        print("heartRate: ", heartRate)
        let  pa: [String: Any] =  [
            "id": 1,
            "lat": String(describing: self.lat),
            "lon": String(describing: self.long),
            "heartRate": heartRate,
        ]
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/uploadMarkusData",
                   method: HTTPMethod.post, parameters: pa).response { response in
            if(response.data == nil){
                return
            }
            let str = String(decoding: response.data!, as: UTF8.self)
            print("reponse of uploadMarkusData: ", str)
        }
    }
}
