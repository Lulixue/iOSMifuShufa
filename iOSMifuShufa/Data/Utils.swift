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
  
  
  public static func getLess(_ f1: CGFloat, _ f2: CGFloat) -> CGFloat {
    return f1 < f2 ? f1 : f2
  }
  public static func getLess(_ f1: Int, _ f2: Int) -> Int  {
    return f1 < f2 ? f1 : f2
  }
  public static func getMore(_ f1: CGFloat, _ f2: CGFloat) -> CGFloat  {
    return f1 > f2 ? f1 : f2
  }
  public static func getMore(_ f1: Int, _ f2: Int)  -> Int {
    return f1 > f2 ? f1 : f2
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
