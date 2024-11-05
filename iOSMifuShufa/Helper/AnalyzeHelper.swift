//
//  AnalyzeHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//


enum SingleAnalyzeType: String {
  case Original, GridMiCircle, BorderPlus, ProfilePlus, Grid9GongGe, GridMi, Grid16GoneGe, Grid36GoneGe;
  
  func toString() -> String {
    rawValue
  }
}

class AnalyzeHelper {
  static let shared = AnalyzeHelper()
  
  
  private let CENTROID_MI = "singleCentroidMi"
  private let SINGLE_ANALYZE_KEY = "singleAnalyzeKey"
  private let HOME_ROTATE = "homeRotate"
  private let SINGLE_ROTATE = "singleRotate"
  private let SINGLE_ORIGINAL = "singleOriginal"
  private let IMAGE_SCALE = "imageScale"
  
  var singleAnalyzeType: SingleAnalyzeType {
    get { SingleAnalyzeType(rawValue: Settings.getString(SINGLE_ANALYZE_KEY, SingleAnalyzeType.Original.toString()))! }
    set {
      Settings.putString(SINGLE_ANALYZE_KEY, newValue.toString())
    }
  }
  
  var singleOriginal: Bool {
    get { Settings.getBoolean(SINGLE_ORIGINAL, false) }
    set {
      Settings.putBoolean(SINGLE_ANALYZE_KEY, newValue)
    }
  }
  
}
