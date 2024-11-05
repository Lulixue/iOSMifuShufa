//
//  Buttons.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import SwiftUI

struct PrimaryButton: ButtonStyle {
  var enabled: Bool = true
  var bgColor: Color = Colors.searchHeader.swiftColor
  var disableContentColor: Color = .white
  var horPadding: CGFloat = 8
  var verPadding: CGFloat = 5
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.vertical, verPadding)
      .padding(.horizontal, horPadding)
      .background(enabled ? bgColor : .gray.opacity(0.45))
      .cornerRadius(5)
      .foregroundColor(configuration.isPressed ? UIColor.lightGray.swiftColor : (enabled ? Color.white : disableContentColor))
      .opacity(configuration.isPressed ? 0.7 : 1)
  }
}


struct BgClickableButton: ButtonStyle {
  var clickedColor: Color = .gray.opacity(0.55)
  var cornerRadius: CGFloat = 5
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.7 : 1)
      .background(RoundedRectangle(cornerRadius: cornerRadius)
        .fill(configuration.isPressed ? clickedColor : .clear))
  }
}
