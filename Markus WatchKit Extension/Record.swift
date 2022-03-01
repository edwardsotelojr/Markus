//
//  record.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 2/21/22.
//
/*
import Foundation
import AVFAudio
import AVFoundation
import Alamofire

class Record: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var filename = ""
    var previousFilename = ""
    var filenameCount = 0
    var isAudioRecordingGranted = true
    private let session = AVAudioSession.sharedInstance()
    var audioRecorder: AVAudioRecorder?

    func record() // audio recorder prepared to record
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
                                    return;
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
}
*/
