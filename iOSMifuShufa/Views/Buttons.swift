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


struct CheckboxStyle: ToggleStyle {
  var iconSize: CGFloat = 20
  var leadingSpacing: CGFloat = 8
  var disabled: Bool = false
  var backgroundColor: Color = .white
  var iconColor: Color = Colors.searchHeader.swiftColor
  var paddingVer: CGFloat = 6
  
  func makeBody(configuration: Self.Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      HStack(spacing: 0) {
        HStack {
          Image(systemName: configuration.isOn ? "checkmark" : "square")
            .resizable()
            .scaledToFit()
            .font(Font.title.weight(configuration.isOn ? .bold : .regular))
            .foregroundColor(configuration.isOn ? .white : iconColor)
        }
        .padding(.all, configuration.isOn ? 4 : 0)
        .frame(width: iconSize, height: iconSize)
        .background(disabled ? .gray : (configuration.isOn ? iconColor : .clear))
        .cornerRadius(2)
        if leadingSpacing > 0 {
          Spacer.width(leadingSpacing)
        }
        configuration.label
      }.padding(.vertical, paddingVer).padding(.horizontal, 2).background(backgroundColor)
    }.cornerRadius(5).buttonStyle(BgClickableButton())
  }
}
