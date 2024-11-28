//
//  AnalyzeHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//
import Foundation
import UIKit
import SwiftUI

struct FilterRange {
  let min: Int
  let def: Int
  let max: Int
  var offset: Int = 0
}


class OpenCvBridge {
  protocol FilterImage {
    func addFilter(org: Bitmap, param: Int?) -> Bitmap
  }

  protocol FilterImagePlus {
    /**
     * 用作分析滤镜后保存的图像
     * @param result: 上一次操作得到的结果bitmap
     * @param draw: 把result操作得到的结果绘制的目标bitmap
     */
    func addFilterPlus(result: Bitmap, draw: Bitmap, params: Int?, obj: Any?) -> Bitmap
  }
}

enum ImageFilter : String, CaseIterable, OpenCvBridge.FilterImage, FilterProperty {
  case Original, Binary, Invert, HorizontalMirror, VerticalMirror, Sharpen, Canny, Mi, CentroidMi, Border, Profile;
  
  var range: FilterRange? {
    switch self {
    case .Binary:
      OpenCvImage.binaryRange
    case .Canny:
      OpenCvImage.cannyRange
    case .Sharpen:
      OpenCvImage.sharpenRange
    default:
      nil
    }
  }
  
  func addFilter(org: Bitmap, param: Int?) -> Bitmap {
    switch self {
    case .Binary: do {
      return if let param {
        OpenCvImage.thresholdImage(org, param + OpenCvImage.binaryRange.offset, .THRESH_BINARY)
      } else {
        OpenCvImage.thresholdImage(org, OpenCvImage.binaryRange.def + OpenCvImage.binaryRange.offset, .THRESH_BINARY)
      }
    }
    case .Invert:
      return OpenCvImage.invertBitmap(org)
    case .HorizontalMirror:
      return OpenCvImage.flipImage(org, 1)
    case .VerticalMirror:
      return OpenCvImage.flipImage(org, 0)
    case .Sharpen:
      return OpenCvImage.sharpenImage(org, param ?? OpenCvImage.sharpenRange.def)
    case .Canny:
      if let param {
        return OpenCvImage.cannyImage(org, param)
      } else {
        return OpenCvImage.cannyImage(org, OpenCvImage.cannyRange.def)
      }
    case .Mi:
      if let param {
        return ImageProcessor.addMiGrid(bitmap: org, color: UIColor.init(rgb: param))
      } else {
        return ImageProcessor.addMiGrid(bitmap: org, color: OpenCvImage.getOppositeMeanColor(org))
      }
    case .CentroidMi:
      do {
        let (centroid, radius) = OpenCvImage.getBitmapCentroidRadius(org)
        if let param {
          return ImageProcessor.addMiGrid(bitmap: org, color: UIColor.init(rgb: param), centroid: centroid, centerRadius: radius)
        }
        return ImageProcessor.addMiGrid(bitmap: org, color: OpenCvImage.getOppositeMeanColor(org), centroid: centroid, centerRadius: radius)
      }
    case .Border:
      return OpenCvImage.convexHullBitmap(org, draw: org, type: OpenCvImage.CONVEX_BORDER)
    case .Profile:
      return OpenCvImage.convexHullBitmap(org, draw: org, type: OpenCvImage.CONVEX_PROFILE)
    default:
      return org
    }
  }
  
  func hasParam() -> Boolean {
    range != nil
  }
  
  func getDefaultValue() -> Int {
    range?.def ?? 0
  }
  
  func isVipProperty() -> Bool {
    switch self {
    case .CentroidMi, .Profile: true
    default: false
    }
  }
  
  var chinese: String {
    switch self {
    case .Original:
      "原图".orCht("原圖")
    case .Binary:
      "黑白"
    case .Invert:
      "反色"
    case .HorizontalMirror:
      "水平镜像".orCht("水平鏡像")
    case .VerticalMirror:
      "垂直镜像".orCht("垂直鏡像")
    case .Sharpen:
      "锐化".orCht("鋭化")
    case .Canny:
      "边缘".orCht("邊緣")
    case .Mi:
      "米字格"
    case .CentroidMi:
      "重心米字格"
    case .Border:
      "矩形轮廓".orCht("矩形輪廓")
    case .Profile:
      "重心轮廓".orCht("重心輪廓")
    }
  }
  
  
}

enum ImageAnalyze: String, CaseIterable, OpenCvBridge.FilterImagePlus, FilterProperty {
  
  case OriginalPlus, MiGridPlus, BorderPlus, CentroidMiGridPlus, ProfilePlus
  
  func addFilterPlus(result: Bitmap, draw: Bitmap, params: Int?, obj: Any?) -> Bitmap {
    switch self {
    case .MiGridPlus:
      return ImageProcessor.addMiGrid(bitmap: draw, color: OpenCvImage.getOppositeMeanColor(result))
    case .BorderPlus:
      return OpenCvImage.convexHullBitmap(result, draw: draw, type: OpenCvImage.CONVEX_BORDER)
    case .CentroidMiGridPlus:
      do {
        let (centroid, radius) = OpenCvImage.getBitmapCentroidRadius(result)
        let color = AnalyzeHelper.getMiGridColor(bitmap: draw, folder: (obj as? String) ?? "")
        return ImageProcessor.addMiGrid(bitmap: result, color: color, centroid: centroid, centerRadius: radius)
      }
    case .ProfilePlus:
      return OpenCvImage.convexHullBitmap(result, draw: draw, type: OpenCvImage.CONVEX_PROFILE)
    default:
      return result
    }
  }
  
  func hasParam() -> Boolean {
    false
  }
  
  func getDefaultValue() -> Int {
    0
  }
  
  func doAnalysis(org: Bitmap, folder: String = "") -> Bitmap {
    self.addFilterPlus(result: org, draw: org, params: nil, obj: folder)
  }
  
  func isVipProperty() -> Bool {
    switch self {
    case .CentroidMiGridPlus, .ProfilePlus:
      true
    default:
      false
    }
  }
  
  var chinese: String {
    switch self {
    case .OriginalPlus:
      "原图".orCht("原圖")
    case .MiGridPlus:
      "米字格"
    case .BorderPlus:
      "边框轮廓".orCht("邊框輪廓")
    case .CentroidMiGridPlus:
      "重心米字格"
    case .ProfilePlus:
      "重心轮廓".orCht("重心輪廓")
    }
  }
  
  
}

enum SingleAnalyzeType: String, CaseIterable, FilterProperty {
  func hasParam() -> Boolean {
    false
  }
  
  func getDefaultValue() -> Int {
    0
  }
  
  func isVipProperty() -> Bool {
    switch self {
    case .ProfilePlus: true
    default: false
    }
  }
  
  var chinese: String {
    switch self {
    case .Original: ImageFilter.Original.chinese
    case .GridMiCircle: "圆圈米字格".orCht("圓圈米字格")
    case .BorderPlus: ImageAnalyze.BorderPlus.chinese
    case .ProfilePlus: ImageAnalyze.ProfilePlus.chinese
    case .Grid9GongGe: "九宫格米字格"
    case .GridMi: ImageFilter.Mi.chinese
    case .Grid16GoneGe: "十六宫格米字格"
    case .Grid36GoneGe: "三十六宫格米字格"
    }
  }
  
  case Original, GridMiCircle, BorderPlus, ProfilePlus, Grid9GongGe, GridMi, Grid16GoneGe, Grid36GoneGe;
  
  func toString() -> String {
    rawValue
  }
  
  func demoBitmap(_ bitmap: Bitmap) -> Bitmap {
    switch self {
    case .Original:
      return bitmap
    case .BorderPlus, .ProfilePlus:
      return ImageAnalyze(rawValue: self.toString())!.doAnalysis(org: bitmap, folder: "方圆庵记")
    default:
      do {
        let type = MiGridType(rawValue: self.toString())!
        return ImageProcessor.addMiGridSolid(bitmap, type: type)
      }
    }
  }
  
  func applyAnalyze(_ bitmap: Bitmap, _ single: BeitieSingle) -> Bitmap {
    switch self {
    case .Original: return bitmap
    case .GridMiCircle, .GridMi, .Grid16GoneGe, .Grid36GoneGe, .Grid9GongGe:
      do {
        let miGridType = MiGridType(rawValue: self.toString())!
        return ImageProcessor.addSingleMiGrid(single: single, bitmap: bitmap, miGrid: miGridType)
      }
    default:
      do {
        let analyze = ImageAnalyze(rawValue: toString())!
        return analyze.doAnalysis(org: bitmap, folder: single.work.folder)
      }
    }
  }
}

class MiGridViewModel: AlertViewModel {
  static let shared = MiGridViewModel()
  @Published var singleType = SingleAnalyzeType.Original {
    didSet {
      if singleType.isVipProperty() && !centroidMi {
        ConstraintItem.CentroidMiCount.increaseUsage()
      }
    }
  }
  @Published var centroidMi = AnalyzeHelper.singleCentroidMi {
    didSet {
      AnalyzeHelper.singleCentroidMi = centroidMi
    }
  }
  var viewId: String {
    singleType.rawValue + centroidMi.description
  }
  
  var isVipFeature: Bool {
    singleType.isVipProperty() || centroidMi
  }
  
  var centroidBinding: Binding<Bool> {
    Binding {
      self.centroidMi
    } set: { newValue in
      if newValue && ConstraintItem.CentroidMiCount.readUsageMaxCount() {
        self.centroidMi = false
        self.showConstraintVip(ConstraintItem.CentroidMiCount.topMostConstraintMessage)
        return
      }
      ConstraintItem.CentroidMiCount.increaseUsage()
      self.centroidMi = newValue
    }
  }
  
  lazy var demoImages = {
    var this = [SingleAnalyzeType: UIImage]()
    let zi = UIImage(named: "zi")!
    SingleAnalyzeType.allCases.forEach { type in
      this[type] = type.demoBitmap(zi)
    }
    return this
  }()
  
  func reset() {
    if (centroidMi && !CurrentUser.isVip) {
      centroidMi = false
      singleType = .Original
    }
  }
}

class AnalyzeHelper {
  
  private static let CENTROID_MI = "singleCentroidMi"
  private static let SINGLE_ANALYZE_KEY = "singleAnalyzeKey"
  private static let HOME_ROTATE = "homeRotate"
  private static let SINGLE_ROTATE = "singleRotate"
  private static let SINGLE_ORIGINAL = "singleOriginal"
  private static let IMAGE_SCALE = "imageScale"
  
  static var singleCentroidMi = Settings.getBoolean(CENTROID_MI, false) {
    didSet {
      Settings.putBoolean(CENTROID_MI, singleCentroidMi)
    }
  }
  static var singleAnalyzeType: SingleAnalyzeType = SingleAnalyzeType(rawValue: Settings.getString(SINGLE_ANALYZE_KEY, SingleAnalyzeType.Original.toString()))! {
    didSet {
      Settings.putString(SINGLE_ANALYZE_KEY, singleAnalyzeType.toString())
    }
  }
  static var singleRotate: Boolean = Settings.getBoolean(SINGLE_ROTATE, true) {
    didSet {
      Settings.putBoolean(SINGLE_ROTATE, singleRotate)
    }
  }
  
  static var homeRotate: Boolean = Settings.getBoolean(HOME_ROTATE, true) {
    didSet {
      Settings.putBoolean(HOME_ROTATE, homeRotate)
    }
  }
  static var singleOriginal: Bool = Settings.getBoolean(SINGLE_ORIGINAL, false) {
    didSet {
      Settings.putBoolean(SINGLE_ANALYZE_KEY, singleOriginal)
    }
  }
  
  static func getMiGridColor(bitmap: Bitmap, folder: String) -> UIColor {
    return BeitieDbHelper.getWorkByFolder(folder)?.miGridColor() ?? UIColor.black
  }
  
  static func getCentroidMiGrid(org: Bitmap, folder: String) -> (CGPoint?, CGFloat) {
    return OpenCvImage.getBitmapCentroidRadius(org)
  }
}


protocol FilterProperty {
  func hasParam() -> Boolean
  func getDefaultValue() -> Int
  func isVipProperty() -> Bool
  var chinese: String {
    get
  }
}
 
