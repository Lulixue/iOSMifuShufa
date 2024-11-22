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
  
  static func getLogTime(_ date: Date) -> String {
    return dataFormatter.string(from: date)
  }
  
  private static let ONE_DAY: TimeInterval = 24 * 60 * 60
  
  static func getNaturalTime(_ date: Date) -> String {
    let current = Date()
    let dayOffset = date.distance(to: current)
    let days = Int(dayOffset / ONE_DAY)
    let monthDaySdf = monthDayFormatter
    let hourMinSdf = hourFormatter
    if days >= 3 {
      if current.get(.year) != date.get(.year) {
        return shortFormatter.format(date)
      }
      return monthDayFormatter.format(date)
    }
    else if days == 0 {
      return hourMinSdf.format(date)
    }
    else if days == 1 {
      return "昨天 " + hourMinSdf.format(date)
    }
    else if days == 2 {
      return "前天 " + hourMinSdf.format(date)
    }
    else {
      return monthDaySdf.format(date)
    }
  }
  
  public static func getLess(_ f1: CGFloat, _ f2: CGFloat) -> CGFloat {
    return min(f1, f2)
  }
  public static func getLess(_ f1: Int, _ f2: Int) -> Int  {
    return min(f1, f2)
  }
  public static func getMore(_ f1: CGFloat, _ f2: CGFloat) -> CGFloat  {
    return max(f1, f2)
  }
  public static func getMore(_ f1: Int, _ f2: Int)  -> Int {
    return max(f1, f2)
  }
  
  static func gotoAppStore() {
    let urlString = "itms-apps://itunes.apple.com/app/" + APP_ID
    if let url = URL(string: urlString) {
        //根据iOS系统版本，分别处理
      if #available(iOS 10, *) {
        UIApplication.shared.open(url, options: [:],
                                  completionHandler: {
          (success) in
        })
      } else {
        UIApplication.shared.openURL(url)
      }
    }
  }
  
  public static let PHOTOVIEW_SCALE_MIN: CGFloat = 1.0
  public static let PHOTOVIEW_SCALE_MEDIUM: CGFloat = 1.75
  public static let PHOTOVIEW_SCALE_MAX: CGFloat = 3
  
  public static let DEFAULT_JIZI_CHAR_PER_COL = 3
  public static let DEFAULT_JIZI_SINGLE_GAP = 3
  public static let DEFAULT_JIZI_INSET_GAP = 10
  public static let DEFAULT_JIZI_BG_COLOR = 0 // black
  private static let MI_GRID_LINE_WIDTH: CGFloat = 1
}

extension Date {
  func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
    return calendar.dateComponents(Set(components), from: self)
  }
  
  func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
    return calendar.component(component, from: self)
  }
}
