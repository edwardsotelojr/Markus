//
//  FileManagerExtension.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 11/3/21.
//

import Foundation

extension FileManager {
  
  /// Moves a given file to user documents.
  /// Returns the destination URL on success or nil if it fails.
  /// This is a synchronous operation.
  func moveToUserDocuments(itemAt item: URL, renameTo rename: String?) -> URL? {
    
    let filename: String
    if let renameToName = rename {
      filename = renameToName
    } else {
      filename = item.lastPathComponent
    }
    
    let destination: URL = userDocumentsDirectory.appendingPathComponent(filename)
    let doesFileExist: Bool = fileExists(atPath: destination.relativePath)
    do {
      
      if doesFileExist {
        print("FileManager replacing \(filename) in documents directory...")
        _ = try replaceItemAt(destination, withItemAt: item)
      } else {
        print("FileManager moving \(filename) to documents directory...")
        try moveItem(at: item, to: destination)
      }
      return destination
      
    } catch let error {
      print("FileManager failed to move '\(filename)' to documents directory.\nError:\n\t\(error)")
      return nil
    }
  }
  
  /// Returns the user documents directory URL.
  var userDocumentsDirectory: URL {
    let manager = FileManager.default
    let url: URL = manager.urls(for: .documentDirectory, in: .userDomainMask).last!
    return url
  }
}
