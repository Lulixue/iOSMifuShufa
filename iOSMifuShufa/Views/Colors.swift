//
//  Colors.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import SwiftUI
import UIKit

extension Color {
  static var colorHexMap = [Color: String]()
  var hexString: String {
    if Self.colorHexMap.containsKey(self) {
      return Self.colorHexMap[self]!
    }
    let components = self.cgColor!.components
    let r: CGFloat = components?[0] ?? 0.0
    let g: CGFloat = components?[1] ?? 0.0
    let b: CGFloat = components?[2] ?? 0.0
    
    let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    Self.colorHexMap[self] = hexString
    return hexString
  }
}


extension UIColor {
  static private var colorMap = [UIColor: Color]()
  
  static var colorHexMap = [UIColor: String]()
  var hexString: String {
      //    if Self.colorHexMap.containsKey(self) {
      //      return Self.colorHexMap[self]!
      //    }
    let components = self.cgColor.components
    let r: CGFloat = components?[0] ?? 0.0
    let g: CGFloat = components?[1] ?? 0.0
    let b: CGFloat = components?[2] ?? 0.0
    
    let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
      //    let lock: DispatchQueue = DispatchQueue.init(label: "")
      //    lock.sync{ Self.colorHexMap[self] = hexString }
    return hexString
  }
  
  var swiftColor: Color {
    if !UIColor.colorMap.containsKey(self) {
      UIColor.colorMap[self] = Color(self)
    }
    return UIColor.colorMap[self]!
  }
  convenience init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha) / 255.0)
  }
  
  convenience init(rgb: Int) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF
    )
  }
  convenience init(argb: Int) {
    self.init(
      red: (argb >> 16) & 0xFF,
      green: (argb >> 8) & 0xFF,
      blue: argb & 0xFF,
      alpha: (argb >> 24) & 0xFF
    )
  }
}


class Colors {
  static let editor_header = UIColor.init(rgb: 0x909090)
  static let light_search_header = UIColor.init(rgb: 0x8DAC6E)
  static let popup_menu_bg = UIColor.init(rgb: 0x4A4A4A)
  static let slate_gray = UIColor.init(rgb: 0x708090)
  static let cardview_dark_background = UIColor.init(rgb: 0x424242)
  static let lightSlateGray = UIColor.init(rgb: 0x778899)
  static let purple = UIColor.init(rgb: 0x800080)
  static let dark_orange = UIColor.init(rgb: 0xFF8C00)
  static let colorGreen = UIColor.init(rgb: 0x008000)
  static let wx_background = UIColor.init(rgb: 0xEDEDED)
  static let second_background = UIColor.init(rgb: 0xE9E9E9)
  
  static let candidate_bg = UIColor.init(rgb: 0xE7E7E7)
  static let undetermined_bg = UIColor.init(rgb: 0xD7D7D7)
  static let undetermined_title = UIColor.init(rgb: 0xC7C7C7)
  
  static let white_smoke = UIColor.init(rgb: 0xF5F5F5)
  static let surfaceVariant = white_smoke
  static let surfaceContainer = wx_background
  
  static let ICON_COLORS = [ios_blue, dark_cyan, jiyunAccent, dark_slate_blue].map { $0.swiftColor }
  
  static func iconColor(_ index: Int) -> Color {
    ICON_COLORS[index % ICON_COLORS.size]
  }

  static let ios_blue = UIColor.init(argb: 0xFF3478F6)
  static let dark_cyan = darkCyan
  static let jiyunAccent = searchHeader
  static let dark_slate_blue = darkSlateBlue

  static let ci_yun_ze = UIColor.init(rgb: 0x9051A1)
  static let ci_yun_ze3 = UIColor.init(rgb: 0x9400D3)
  static let ci_yun_ze2 =  UIColor.init(rgb: 0x808000)
  static let ci_yun_zeng = colorPrimary
  static let ci_yun_ping2 = UIColor.init(rgb: 0x00BFFF)
  static let ci_yun_ping = UIColor.blue
  
  static let darkOrange = UIColor.init(named: "DarkOrange")!
  static let darkSlateBlue = UIColor.init(named: "DarkSlateBlue")!
  static let zdic = UIColor.init(named: "zdic")!
  static let iosBlue = UIColor.init(named: "SwiftBlue")!
  static let holoDarkRed = UIColor.init(named: "HoloDarkRed")!
  static let searchResultYun = UIColor.init(named: "SearchResultYun")!
  static let swiftUIColorBlue = UIColor.init(named: "SwiftUIColorBlue")!
  static let searchResultText = UIColor.init(named: "SearchResultText")!
  static let maroon = UIColor.init(named: "Maroon")!
  static let colorPrimary = UIColor.init(named: "ColorPrimary")!
  static let defaultText = UIColor.init(named: "DefaultTextColor")!
  static let bilibili = UIColor.init(named: "Bilibili")!
  static let colorAccent = searchHeader
  static let darkSlateGray = UIColor.init(named: "DarkSlateGray")!
  static let itemSelectedColor = UIColor.init(named: "DarkBlue")!
  static let itemSelectedBgColor: UIColor = .systemGray5
  static let defaultCommentColor: UIColor = .black
  static let defaultItemColor: UIColor = .blue
  static let defaultLinkColor: UIColor = .link
  static let operationBar = UIColor.init(named: "OperationBar")!
  static let searchHeader = UIColor.init(named: "SearchHeader")!
  static let yunHeader: UIColor = .darkText
  static let background = UIColor.init(named: "Background")!
  static let souyun = UIColor.init(named: "souyun")!
  static let pullerBackground = UIColor.init(named: "PullerBackground")!
  static let pullerBar = UIColor.init(named: "PullerBar")!
  static let pullerActive: UIColor = .darkGray
  static let darkBlue = UIColor.init(named: "DarkBlue")!
  static let darkOrchid = UIColor.init(named: "DarkOrchid")!
  static let darkCyan = UIColor.init(named: "DarkCyan")!
  static let floatingZi = UIColor.init(argb: 0xAA778A64)
  
  static let audioAvailable = souyun
  static let audioUnavailable = UIColor.lightGray
  
  static let ciLinggeColor = UIColor.init(named: "DarkBlue")!
}
