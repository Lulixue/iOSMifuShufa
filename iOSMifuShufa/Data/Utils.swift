//
//  Utils.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/4.
//
import Foundation
import UIKit
import SwiftUI

class Utils { 
  static let loginFormater = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return dateFormatterGet
  }()
  
  static let dataFileFormatter = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyyMMdd_HH_mm_ss"
    return dateFormatterGet
  }()
  
  static let dataFormatter = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy/MM/dd HH:mm:ss"
    return dateFormatterGet
  }()
  static let shortFormatter = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy年M月d日 HH:mm"
    return dateFormatterGet
  }()
  
  static let monthDayFormatter = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "M月d日 HH:mm"
    return dateFormatterGet
  }()
  
  static let hourFormatter = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "HH:mm"
    return dateFormatterGet
  }()
  
  static let dayFormatter = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy.MM.dd"
    return dateFormatterGet
  }()
  
  static var currentTimeUnderline: String {
    dataFileFormatter.string(from: Date())
  }
  
  static func currentTime() -> String {
    let time = dataFormatter.string(from: Date())
    return time
  }
  
  
}
