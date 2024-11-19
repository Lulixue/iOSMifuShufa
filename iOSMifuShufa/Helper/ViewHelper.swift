//
//  ViewHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import UIKit
import SwiftUI



extension Image {
  @ViewBuilder func square(size: CGFloat) -> some View {
    self.resizable().scaledToFit().frame(width: size, height: size)
  }
  @ViewBuilder func square(size: CGFloat, padding: CGFloat) -> some View {
    self.resizable().scaledToFit().padding(.horizontal, padding).frame(width: size, height: size)
  }
}

extension UIScreen {
  static var currentWidth: CGFloat {
    UIHelper.screenWidth
  }
  
  static var currentHeight: CGFloat {
    UIHelper.screenHeight
  }
  
  static var statusBarHeight: CGFloat {
    var statusBarHeight: CGFloat = 0
    if #available(iOS 13.0, *) {
      let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
      statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    } else {
      statusBarHeight = UIApplication.shared.statusBarFrame.height
    }
    return statusBarHeight
  }
}

class UIHelper {
  static var windowFrame: CGRect? {
    UIApplication.shared.connectedScenes
      .compactMap({ scene -> UIWindow? in
        (scene as? UIWindowScene)?.keyWindow
      })
      .first?
      .frame
  }
  
  static private var lastFrame: CGRect? = nil
  
  static var screenWidth: CGFloat {
    if Thread.isMainThread {
      if let frame = windowFrame {
        self.lastFrame = frame
        return frame.width
      }
      return UIScreen.main.bounds.width
    }
    
    return lastFrame?.width ?? UIScreen.main.bounds.width
  }
  
  static var screenHeight: CGFloat {
    if Thread.isMainThread {
      if let frame = windowFrame {
        self.lastFrame = frame
        return frame.height
      }
      return UIScreen.main.bounds.width
    }
    
    return lastFrame?.height ?? UIScreen.main.bounds.height
  }
}

private let APPLY_FONT_NAMES = ["KaiTi", "LXGWWenKai-Regular"]

private func getHtmlString(htmlText: String, fontPoint: CGFloat,
                           font: UIFont? = nil, textColor: String? = nil, kern: CGFloat? = nil) -> NSMutableAttributedString? {
  var fontName = "'-apple-system', 'HelveticaNeue'"
  if let name = font?.fontName {
    if APPLY_FONT_NAMES.contains(name) {
      fontName = name
    }
  }
  
  let color = textColor != nil ? "color: \(textColor!);" : ""
  let modifiedFont = "<span style=\"font-family: \(fontName);font-size: \(fontPoint);\(color)\">\(htmlText)</span>"
  
  let string = try! NSMutableAttributedString(
    data: modifiedFont.data(using: .unicode, allowLossyConversion: false)!,
    options: [
      .documentType: NSAttributedString.DocumentType.html,
      .characterEncoding: String.Encoding.utf8.rawValue,
    ],
    documentAttributes: nil
  )
  if let kern = kern {
    string.addAttributes([.kern: kern], range: NSRange(location: 0, length: string.length))
  }
  
  return string
}

extension NSMutableAttributedString {
  func addTextColor(_ color: UIColor) -> NSMutableAttributedString {
    self.addAttribute(.foregroundColor, value: color as Any, range: NSRange(location: 0, length: self.length))
    return self
  }
}

extension String {
  var htmlString: NSAttributedString? {
    try? NSAttributedString(
      data: self.data(using: .unicode, allowLossyConversion: false)!,
      options: [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue
      ],
      documentAttributes: nil
    )
  }
  
  func toHtmlString(font: UIFont, textColor: String? = nil, kern: CGFloat? = nil) -> NSMutableAttributedString? {
    getHtmlString(htmlText: self, fontPoint: font.pointSize, font: font, textColor: textColor, kern: kern)
  }
}


extension NSAttributedString {
  var swiftUIAttrString: AttributedString {
    try! AttributedString(self, including: \.uiKit)
  }
}
