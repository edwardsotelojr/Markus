//
//  MemoFileNameHelper.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 11/2/21.
//

import Foundation

class MemoFileNameHelper {
  
  /// A date formatter to format Date to a string suitable to be used as a file name.
  static let dateFormatterForFileName: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMddHHmmssZZZ"
    return formatter
  }()
  
  /// Returns a new unique output URL based on user's document directory for to-be-saved voice memo.
  static func newOutputURL() -> URL {
    let dateFormatter = MemoFileNameHelper.dateFormatterForFileName
    let date = Date()
    let filename = dateFormatter.string(from: date)
    let output = FileManager.default.userDocumentsDirectory.appendingPathComponent("\(filename).wav")
    return output
  }
}
