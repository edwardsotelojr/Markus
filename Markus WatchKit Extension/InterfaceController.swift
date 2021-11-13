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

enum InterfaceState {
  case instantiated
  case awake
  case initialized
}

class InterfaceController: WKInterfaceController/*, MemoStoreObserver*/ {
    var interfaceState = InterfaceState.instantiated

    @IBOutlet weak var VerificationCode: WKInterfaceLabel!
    var memos: [VoiceMemo] = []
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
   
    private func processRecordedAudio(at url: URL) {
      let voiceMemo = VoiceMemo(filename: url.lastPathComponent, date: Date())
        print("filename: \(url.lastPathComponent)")
      //MemoStore.shared.add(memo: voiceMemo)
      //MemoStore.shared.save()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        interfaceState = .awake
        if let uuid = WKInterfaceDevice.current().identifierForVendor?.uuidString {
            print("UUID is",uuid)
            let parameters = ["MarkusSerial": uuid]
               //create the url with URL
            let url = URL(string: "http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/requestCode")
            //AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/requestCode",
              //         method: .post,
                //       parameters: parameters).responseJSON { (response) in
                  //     print(response)
                    //   }
           
            let _headers : HTTPHeaders = ["Content-Type":"application/x-www-form-urlencoded"]
            //let params : Parameters = ["grant_type":"password","username":"mail","password":"pass"]

            var code = ""
            var codee = ""
            AF.request("http://ec2-3-140-217-222.us-east-2.compute.amazonaws.com:3000/requestCode",
                       method: HTTPMethod.post, parameters: parameters).response { response in
                        let str = String(decoding: response.data!, as: UTF8.self)
                        print(str)
                        let start = String.Index(utf16Offset: 13, in: str)
                        let end = String.Index(utf16Offset: str.count, in: str)
                        print(String(str[start..<end]))
                        code = String(str[start..<end])
                        codee = code
                        var len = code.count-1
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
                       }
            
        }
    }
    
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }

}
