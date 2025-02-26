//
//  ResourceHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/2.
//

  //
  //  ResourceHelper.swift
  //  iOSChinesePoemDict
  //
  //  Created by 肖李根 on 26/7/21.
  //

import Foundation
import Alamofire
import Zip

class ResourceFiles {
}


class ManifestItem: Decodable {
  var file = ""
  var md5 = ""
}

extension URL {
  func exists()-> Bool {
    let fileMgr = FileManager.default
    return fileMgr.fileExists(atPath: self.path)
  }
}

 
extension FileManager {
  func removeItem(path: String) {
    if self.fileExists(atPath: path) {
      try? self.removeItem(atPath: path)
    }
  }
}

class ResourceHelper {
  
  static let fileManager = FileManager.default
  private static let DATA_DIR_NAME = "data"
  private static let DATA_MANIFEST_NAME = "manifest.json"
  private static let RESOURCE_DIR = "resources"
  static let dataDir: URL? = {
    guard let directory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL else {
      return nil
    }
    let dataDirUrl = directory.appendingPathComponent(DATA_DIR_NAME)
    if !fileManager.fileExists(atPath: (dataDirUrl!.path)) {
      do {
        try fileManager.createDirectory(at: dataDirUrl!, withIntermediateDirectories: true, attributes: nil)
      } catch {
      }
    }
    return dataDirUrl
  }()
    
  public static let resourceDir = dataDir?.appendingPathComponent(RESOURCE_DIR)
  
  private static let EXTRACT_OK = 1
  private static let EXTRACT_FAIL = -1
  private static var manifestItems = [ManifestItem]()
  
  @discardableResult
  private static func installFont(_ fontUrl: URL) -> Bool {
    let fontData = try! Data(contentsOf: fontUrl)
    if let provider = CGDataProvider.init(data: fontData as CFData) {
      var error: Unmanaged<CFError>?
      let font: CGFont = CGFont(provider)!
      if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
        print(error.debugDescription)
        return false
      } else {
        return true
      }
    }
    return false
  }
  
  
  public static func installCustomFonts() {
    for font in ["fonts/" + BeitieDbHelper.shared.FONT_FILE] {
      if let url = dataDir?.appendingPathComponent(font) {
        installFont(url)
      }
    }
  }
  
  private static var resourceMd5: String = {
    let url = Bundle.main.url(forResource: "resource_version", withExtension:"txt")
    return readFileContents(fileURL: url!).trimEnd()
  }()
  
  static func hasResourceUpdate()-> Bool {
    return Settings.resourceMd5 != resourceMd5
  }
   
  static func resourceValid() -> Bool {
    return validateManifestFiles(url: resourceDir)
  }
  static func getResourceFileUrl(fileName: String) -> URL? {
    return resourceDir?.appendingPathComponent(fileName)
  }
  static func getFileMd5(_ file: String) -> String {
    for item in manifestItems {
      if (item.file == file) {
        return item.md5
      }
    }
    return ""
  }
  static func readFileContents(file: String) -> String {
    if let url = resourceDir?.appendingPathComponent(file) {
      return readFileContents(fileURL: url)
    }
    return ""
  }
  
  static func readFileContents(fileURL: URL) -> String {
    do {
      return try String(contentsOf: fileURL, encoding: .utf8)
    } catch {
      return ""
    }
  }
  
  private static func validateManifestFiles(url: URL?) -> Bool {
    let manifestFile = url?.appendingPathComponent(DATA_MANIFEST_NAME)
    if (!manifestFile!.exists()) {
      println("manifest not exist \(url?.relativePath ?? ""))")
      return false
    }
    do {
      let itemArray = try JSONDecoder().decode([ManifestItem].self, from: Data(contentsOf: manifestFile!))
      manifestItems.removeAll()
      manifestItems.append(contentsOf: itemArray)
      for item in itemArray {
        if let fileUrl = url?.appendingPathComponent(item.file) {
          if !fileUrl.exists() {
            print("\(item.file) not exist")
            return false
          }
        } else {
          print("\(item.file) not exist")
          return false
        }
      }
      return true
    } catch {
      println("validateManifestFiles \(error)")
      return false
    }
  }
  
  private static let PASSWORD = "sc1234#@!%"
  
  static func extractDefaultResources() -> Bool {
    let result = {
      guard let destDir = dataDir else { return false }
      do {
        if fileManager.fileExists(atPath: destDir.path) {
          try? FileManager.default.removeItem(atPath: destDir.path)
        }
        try CalculateTime(title: "extractDefaultResources") {
          let zipFile = Bundle.main.url(forResource: "resource", withExtension:"zip")
            //          let _ = try Zip.quickUnzipFile(zipFile!) // Unzip
          
          try Zip.unzipFile(zipFile!, destination: destDir, overwrite: true, password: PASSWORD, progress:  {
            println("extractDefaultResources \($0)")
          })
        }
        return true
      } catch {
        println("error \(error)")
        return false
      }
    }()
    if (result) {
      Settings.resourceMd5 = resourceMd5
    }
    return result
  }
}

func CalculateTime(title: String, _ runnable: @escaping () throws -> Void) throws {
  let start = Date().timeIntervalSince1970
  try runnable()
  let end = Date().timeIntervalSince1970
  println("\(title) elaps \(end - start)")
}

