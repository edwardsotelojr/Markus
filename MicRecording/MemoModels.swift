//
//  MemoModels.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 11/2/21.
//


import UIKit

/// Base Memo. The base class for a memo.
@objc(VoiceMemo)
public class VoiceMemo: NSObject, NSCoding, NSCopying {
  
  public let date: Date
  public let filename: String
  public let url: URL
  
  public init(filename: String, date: Date) {
    self.filename = filename
    self.date = date
    
    let userDocuments = FileManager.default.userDocumentsDirectory
    self.url = userDocuments.appendingPathComponent(filename)
    
    super.init()
  }
  
  // MARK: NSCoding
  
  public required init?(coder aDecoder: NSCoder) {
    self.date = aDecoder.decodeObject(forKey: "date") as! Date
    self.filename = aDecoder.decodeObject(forKey: "filename") as! String
    let userDocuments = FileManager.default.userDocumentsDirectory
    self.url = userDocuments.appendingPathComponent(filename) as URL
    
    super.init()
  }
  
  public func encode(with aCoder: NSCoder) {
    aCoder.encode(self.date, forKey: "date")
    aCoder.encode(self.filename, forKey: "filename")
  }
  
  public func copy(with zone: NSZone? = nil) -> Any {
    let copy = VoiceMemo(filename: filename, date: date)
    return copy
  }
  
}

