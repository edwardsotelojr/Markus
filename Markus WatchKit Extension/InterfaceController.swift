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
import AVFAudio

class InterfaceController: WKInterfaceController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var VerificationCodeLabel: WKInterfaceLabel!
    @IBOutlet weak var VerificationCode: WKInterfaceLabel!
    @IBOutlet weak var heartRate: WKInterfaceLabel!
    var memos: [VoiceMemo] = []
    var verificationCode = ""
    let markusSerial = WKInterfaceDevice.current().identifierForVendor?.uuidString
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
        filename = "myRecording" + String(filenameCount) + ".m4a"
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
        if isAudioRecordingGranted
        {
            do
            {
                try session.setCategory(AVAudioSession.Category.record)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                if(audioRecorder?.isRecording == true){
                    audioRecorder?.stop()
                    audioRecorder = nil
                }
                let headers: HTTPHeaders = [
                    /* "Authorization": "your_access_token",  in case you need authorization header */
                    "Content-type": "text/plain; charset=utf-8"
                ]
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder?.delegate = self
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.audioRecorder?.record(forDuration: 3.9)
                    let ddd = self.getDocumentsDirectory()
                    if(self.previousFilename.count > 0){
                        guard let data = try? Data(contentsOf: ddd.appendingPathComponent(self.previousFilename) ) else { return }
                        AF.upload(multipartFormData: { MultipartFormData in
                            MultipartFormData.append(data, withName: "soundFile" , fileName: self.previousFilename , mimeType: "audio/m4a")
                            // for(key,value) in uploadDict {
                            //   MultipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                            //}
                        }, to: "http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/uploadSoundFile?id=4", method: .post, headers: headers)
                            .responseString { response in
                                        print(response)
                                let str = String(decoding: response.data!, as: UTF8.self)

                                if((self.getCommandCode(response: str)) == 1){
                                    print("commandcode is 1")
                                }
                                else{
                                    print("commandcode is 0")
                                }
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
            print("Error:     Don't have access to use your microphone.")
        }
    }
    
    @objc func getHeartRate()
    {
     // 1. Create a heart rate BPM Sample
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"),
        doubleValue: Double(arc4random_uniform(80) + 100))
        let heartSample = HKQuantitySample(type: heartRateType,
            quantity: heartRateQuantity, start: NSDate() as Date, end: NSDate() as Date)
        print(heartRateQuantity)
        self.heartRate.setText(String(Int(heartRateQuantity.doubleValue(for: HKUnit(from: "count/min")))) + " BPM")
        let parameters = ["heartRate": Int(heartRateQuantity.doubleValue(for: HKUnit(from: "count/min")))]

        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/uploadMarkusData",
                   method: HTTPMethod.post, parameters: parameters).response { response in
            let str = String(decoding: response.data!, as: UTF8.self)
            print("reponse of uploadMarkusData: ", str)
        }
   }
    
    @objc func validateCodeRequest()
    {
        print("parameters for validateCode:\(verificationCode), markusSerial: \(markusSerial!)")
        let parameters = ["verification": verificationCode, "markusSerial": markusSerial]
        AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/validateCode",
                   method: HTTPMethod.post, parameters: parameters).response { response in
            let str = String(decoding: response.data!, as: UTF8.self)
            print("\n", str, "\n")
            print("status: ", self.getStatus(response: str))
            self.status = self.getStatus(response: str)
            if(self.status == 0){
                self.timer?.invalidate()
                self.timer = nil
                self.userValid(); // user is valid
            }
        }
    }
    
    func userValid() -> Void
    {
        self.VerificationCode.setHidden(true);
        self.VerificationCodeLabel.setHidden(true);
        self.heartRate.setHidden(false);
        self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(getHeartRate), userInfo: nil, repeats: true)
        self.timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(setup_recorder), userInfo: nil, repeats: true)
    }
    
    func getStatus(response: String) -> Int{
        var status:Int = -1;
        var statusString: String = ""
        var index: Int = 0
        
        if let range: Range<String.Index> = response.range(of: "Status:") {
             index = response.distance(from: response.startIndex, to: range.lowerBound)
            // range
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

    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        self.check_record_permission(); //
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(getHeartRate), userInfo: nil, repeats: true)
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
                    self.validateCodeRequest();
                self.timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.validateCodeRequest), userInfo: nil, repeats: true)
            }
    }
}

/*
 private func processRecordedAudio(at url: URL) {
     let voiceMemo = VoiceMemo(filename: url.lastPathComponent, date: Date())
     print("filename: \(url.lastPathComponent)")
   MemoStore.shared.add(memo: voiceMemo)
   MemoStore.shared.save()
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
 func memoStore(store: MemoStore, didUpdateMemos memos: [VoiceMemo]) {
   self.memos = memos
   //reloadInterface()
 }
 */
