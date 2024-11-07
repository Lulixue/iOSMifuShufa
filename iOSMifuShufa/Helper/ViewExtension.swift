//
//  ViewExtension.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import Foundation
import SwiftUI
import UIKit

private let DEFAULT_DIVIDER_COLOR = UIColor.lightGray.swiftColor

extension String {
  var isHtml: Bool {
    contains("</") || contains("/>")
  }
  
  var url: URL? {
    URL(string: self)
  }
  
  func calculateUITextViewFreeSize(font: UIFont) -> CGSize {
    let size = self.boundingRect(
      with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
      options: .usesLineFragmentOrigin,
      attributes: [ .font: font ],
      context: nil
    ).size
    return CGSizeMake(size.width, size.height.rounded(.up))
  }
  
  func calculateUITextViewSize(fixedWidth: CGFloat, font: UIFont) -> CGSize {
    let size = self.boundingRect(
      with: CGSize(width: fixedWidth, height: .infinity),
      options: .usesLineFragmentOrigin,
      attributes: [ .font: font ],
      context: nil
    ).size
    return CGSizeMake(size.width, size.height.rounded(.up))
  }
}


extension UIFont.TextStyle {
  var pointSize: CGFloat {
    UIFont.preferredFont(forTextStyle: self).pointSize
  }
}

extension UIFont {
  private static var fontMap = [UIFont: Font]()
  var swiftFont: Font {
    let font = Self.fontMap[self] ?? Font(self)
    if !UIFont.fontMap.containsKey(self) {
      UIFont.fontMap[self] = Font(self)
    }
    return font
  }
}

extension View {
  @ViewBuilder
  func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
    if conditional {
      content(self)
    } else {
      self
    }
  }
}


extension Divider {
  @ViewBuilder static func overlayColor(_ color: Color) -> some View {
    Divider().overlay(.white).overlay(color)
  }
}

extension Int {
  func toDouble() -> Double {
    Double(self)
  }
  
  @ViewBuilder func VSpacer() -> some View {
    self.toDouble().VSpacer()
  }
  
  @ViewBuilder func HSpacer() -> some View {
    self.toDouble().HSpacer()
  }
  
  @ViewBuilder func VDivideer(color: Color = DEFAULT_DIVIDER_COLOR) -> some View {
    self.toDouble().VDivideer(color: color)
  }
  @ViewBuilder func HDivder(color: Color = DEFAULT_DIVIDER_COLOR) -> some View {
    self.toDouble().HDivder(color: color)
  }
}

extension CGFloat {
  
  func toDouble() -> Double {
    Double(self)
  }
  
  @ViewBuilder func VSpacer() -> some View {
    self.toDouble().VSpacer()
  }
  
  @ViewBuilder func HSpacer() -> some View {
    self.toDouble().HSpacer()
  }
  
  @ViewBuilder func VDivideer(color: Color = DEFAULT_DIVIDER_COLOR) -> some View {
    self.toDouble().VDivideer(color: color)
  }
  @ViewBuilder func HDivder(color: Color = DEFAULT_DIVIDER_COLOR) -> some View {
    self.toDouble().HDivder(color: color)
  }
}

extension Double {
  
  @ViewBuilder func VSpacer() -> some View {
    Spacer().frame(height: self)
  }
  
  @ViewBuilder func HSpacer() -> some View {
    Spacer().frame(width: self)
  }
  
  @ViewBuilder func VDivideer(color: Color = DEFAULT_DIVIDER_COLOR) -> some View {
    color.frame(width: self)
  }
  @ViewBuilder func HDivder(color: Color = DEFAULT_DIVIDER_COLOR) -> some View {
    color.frame(height: self)
  }
}


#Preview(body: {
  VStack {
    0.5.HDivder()
    0.5.VDivideer()
  }
})

extension Spacer {
  @ViewBuilder static func width(_ value: CGFloat) -> some View {
    Spacer().frame(width: value)
  }
  @ViewBuilder static func height(_ value: CGFloat) -> some View {
    Spacer().frame(height: value)
  }
}


extension NSMutableAttributedString {
  var swiftuiAttrString: AttributedString {
    try! AttributedString(self, including: \.uiKit)
  }
}

extension NSAttributedString {
  private static let CALCULATE_OPTIONS = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
  func calculateUITextViewSize(fixedWidth: CGFloat, fixedHeight: CGFloat = .infinity, maxLines: CGFloat? = nil, font: UIFont? = nil) -> CGSize {
    let size = self.boundingRect(
      with: CGSize(width: fixedWidth, height: fixedHeight),
      options: Self.CALCULATE_OPTIONS,
      context: nil
    ).size
    if let maxLines = maxLines, let font = font {
      let lines = size.height / font.lineHeight
      if lines >= maxLines {
        return CGSizeMake(size.width, maxLines * font.lineHeight)
      }
    }
    return CGSizeMake(size.width, size.height.rounded(.up))
  }
  func calculateUITextViewSize() -> CGSize {
    let size = self.boundingRect(
      with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
      options: Self.CALCULATE_OPTIONS,
      context: nil
    ).size
    return CGSizeMake(size.width, size.height.rounded(.up))
  }
}


extension String {
  func smallSuffix(_ suffix: String, normal: Font = .callout, small: Font = .footnote) -> AttributedString {
    var first = AttributedString(self)
    first.font = normal
    var second = AttributedString(suffix)
    second.font = small
    
    return first + second
  }
}
