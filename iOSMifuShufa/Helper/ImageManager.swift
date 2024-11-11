//
//  ImageManager.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/9.
//

import Foundation
import SDWebImage
import SwiftUI

typealias Long = Int64
typealias File = URL
struct ImageInfo {
  let size: Long
  let contentMd5: String?
}

extension BeitieImage {
  func fileSuffix(_ type: ImageLoadType) -> String {
    "\(self.workFolder)/\(self.fileName(type))"
  }
}

enum ImageLoadStatus: String {
  case Loading, Downloaded, Loaded, Failed;
}

class ImageManager: BaseObservableObject {
  
  @Published var imageStatus = [BeitieImage: ImageLoadStatus]()
  @Published var imageDownloaded = [BeitieImage: CGPoint]()
  @Published var imagePath = [BeitieImage: String]()
  private var imageUIViews = [BeitieImage: UIImageView]()
  var type: ImageLoadType = .JpgCompressed
  
  
  func getImageStatus(_ image: BeitieImage) -> ImageLoadStatus {
    if !self.imageStatus.containsKey(image) {
      self.loadBeitieImage(image)
    }
    return self.imageStatus[image] ?? .Loading
  }
  
  private static let BEITIE_DIR: URL? = {
    let fileManager = FileManager.default
    guard let directory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL else {
      return nil
    }
    let dataDirUrl = directory.appendingPathComponent("beitie_image")
    if !fileManager.fileExists(atPath: (dataDirUrl!.path)) {
      do {
        try fileManager.createDirectory(at: dataDirUrl!, withIntermediateDirectories: true, attributes: nil)
      } catch {
      }
    }
    return dataDirUrl
  }()
  
  private static let URL_NOTIFY_PER_SIZE_DOWNLOADED = 70 * 1024
  private static let DOWNLOAD_BUFFER_SIZE = 64 * 1024
  private static let ALWAYS_NOTIFY_SIZE_DOWNLOADED = 1024 * 1024
  
  func loadBeitieImage(_ image: BeitieImage) {
    let file = image.fileSuffix(type)
    let path = Self.BEITIE_DIR!.path() + file
    printlnDbg("loadBeiteiImage(\(image.index)): \(image.fileName)")
    let folder = Self.BEITIE_DIR!.appendingPathComponent(image.workFolder)
    let manager = FileManager.default
    DispatchQueue.main.async {
      self.imageStatus[image] = .Loading
    }
    if !manager.fileExists(atPath: folder.path()) {
      try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
    } else if manager.fileExists(atPath: path) {
      DispatchQueue.main.async {
        self.imagePath[image] = path
        self.imageStatus[image] = .Loaded
      }
      return
    }
    
    let singleImage = UIImageView()
    let url = image.url(type).url!
    imageUIViews[image] = singleImage
    
    singleImage.sd_setImage(with: url, placeholderImage: nil, options: [.highPriority],
                            progress: { (downloaded, total, url) in
      if downloaded > 0 {
        DispatchQueue.main.async {
          if (downloaded != total) {
            let percent = downloaded.toDouble() * 1.0 / total.toDouble()
            self.imageDownloaded[image] = CGPoint(x: downloaded, y: total)
            printlnDbg("loadBeiteiImage(\(image.index)): \(image.fileName) \(percent)")
            self.imageStatus[image] = .Loading
          } else {
            printlnDbg("loadBeiteiImage(\(image.index)): \(image.fileName) 1.0")
            self.imageStatus[image] = .Downloaded
          }
        }
      }
    },  completed:  { (uiimage, error, cacheType, url) in
      Task {
        guard let data = uiimage?.jpegData(compressionQuality: 0) else {
          DispatchQueue.main.async {
            self.imageStatus[image] = .Failed
          }
          return
        }
        manager.createFile(atPath: path, contents: data)
        DispatchQueue.main.async {
          self.imageStatus[image] = .Loaded
          self.imagePath[image] = path
        }
      }
    })
    
  }
   
}
