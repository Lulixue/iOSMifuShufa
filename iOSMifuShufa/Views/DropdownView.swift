//
//  DropdownCreationView.swift
//  iOSChinesePoemDict
//
//  Created by 肖李根 on 2023/11/2.
//

import SwiftUI
import UIKit
import Foundation

struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
    
    return path
  }
}
 
struct DropDownIcon {
  let name: String
  let isSystem: Bool
  let size: CGFloat
  let totalSize: CGFloat
}

struct DropDownPadding {
  var leading: CGFloat = 12
  var trailing: CGFloat = 8
  var itemVertical: CGFloat = 8
  var extraTop: CGFloat = 3
  var extraBottom: CGFloat = 3
  var iconPadding: CGFloat = 8
  var cornerRadius: CGFloat = 5
}

struct DropDownParam<T: Equatable> {
  let items: [T]
  let texts: [Any]
  let colors: [Color]
  let images: [DropDownIcon]?
  let textFonts: [Font]
  let maxWidth: CGFloat
  let height: CGFloat
  let radius: CGFloat
  let bgColor: Color
  let disabled: [Bool]?
  let padding: DropDownPadding
  let largeFont: Font?
  
  init(items: [T], texts: [String], colors: [Color] = Colors.ICON_COLORS, images: [DropDownIcon]? = nil, disabled: [Bool]? = nil, fonts: [UIFont] = [.preferredFont(forTextStyle: .body)],
       largeFont: UIFont? = nil, radius: CGFloat = 1, padding: DropDownPadding = DropDownPadding(), bgColor: Color = Colors.background.swiftColor) {
    self.items = items
    self.colors = colors
    self.largeFont = largeFont?.swiftFont
    var maxWidth: CGFloat = 0
    var resultTexts = [Any]()
    var totalHeight: CGFloat = 0
    var fontSelectHeight: CGFloat = 0
    for i in texts.indices {
      let t = texts[i]
      let font = fonts[i%fonts.size]
      if t.isHtml {
        let html = t.toHtmlString(font: font, textColor: colors[i%colors.size].hexString)!
        let size = html.calculateUITextViewSize()
        let width = size.width
        totalHeight += size.height
        maxWidth = max(width, maxWidth)
        resultTexts.append(html.swiftuiAttrString)
      } else {
        let size = t.calculateUITextViewFreeSize(font: font)
        if (largeFont != nil) && fontSelectHeight == 0 {
          let largeSize = t.calculateUITextViewFreeSize(font: largeFont!)
          fontSelectHeight = largeSize.height - size.height
          totalHeight += fontSelectHeight
        }
        maxWidth = max(size.width, maxWidth)
        totalHeight += size.height
        resultTexts.append(t)
      }
    }
    self.padding = padding
    if images != nil {
      maxWidth += images![0].totalSize + padding.iconPadding
    }
    self.images = images
    self.textFonts = fonts.map({ $0.swiftFont })
    self.texts = resultTexts
    self.maxWidth = maxWidth + 5 + padding.leading + padding.trailing
    self.height = min(totalHeight + padding.itemVertical * CGFloat(texts.size * 2) + padding.extraTop + padding.extraBottom, UIHelper.screenHeight * 0.5)
    self.radius = radius
    self.bgColor = bgColor
    self.disabled = disabled
  }
}

enum DropdownItemDecoration {
  case Bold
  case Underline
  case Large
}

struct TextModifier: ViewModifier {
  let decorations: [DropdownItemDecoration]
  let largeFont: Font?
  
  func body(content: Content) -> some View {
    if (decorations.isNotEmpty()) {
      content
        .if(decorations.contains(.Large)) {
          $0.font(largeFont)
        }
        .if(decorations.contains(.Bold)) {
          $0.fontWeight(.bold)
        }
        .if(decorations.contains(.Underline)) {
          $0.underline(true)
        }
    } else {
      content
    }
  }
}

struct DropDownOptionsView<T: Equatable>: View {
  let param: DropDownParam<T>
  var selected: T? = nil
  let onClickItem: (T) -> Void
  let selectedModifier: TextModifier
  
  init(param: DropDownParam<T>, selected: T? = nil, selectedDecoration: [DropdownItemDecoration] = [], onClickItem: @escaping (T) -> Void) {
    self.param = param
    self.selected = selected
    self.selectedModifier = TextModifier(decorations: selectedDecoration, largeFont: param.largeFont)
    self.onClickItem = onClickItem
  }
  
  @ViewBuilder func itemView(_ i: Int, _ item: T) -> some View {
    let color = (param.disabled?[i] == true) ? .gray : param.colors[i % param.colors.size]
    HStack(spacing: 0) {
      if let image = param.images?[i] {
        HStack {
          if image.isSystem {
            Image(systemName: image.name).square(size: image.size).foregroundColor(color)
          } else {
            Image(image.name).renderingMode(.template).square(size: image.size).foregroundColor(color)
          }
        }.frame(width: image.totalSize, height: image.totalSize).padding(.trailing, param.padding.iconPadding)
      }
      let text = param.texts[i]
      if text is String {
        Text(text as! String)
          .multilineTextAlignment(.leading)
          .if(selected == item) {
            $0.modifier(selectedModifier)
          }
          .font(param.textFonts[i%param.textFonts.size])
          .foregroundStyle(color)
      } else {
        HStack {
          Text(text as! AttributedString)
            .multilineTextAlignment(.leading)
            .frame(width: param.maxWidth - param.padding.leading - param.padding.trailing, alignment: .leading)
            .if(selected == item) {
              $0.modifier(selectedModifier)
            }
        }
      }
      Spacer()
    }.frame(width: param.maxWidth - param.padding.trailing)
  }
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        param.padding.extraTop.VSpacer()
        ForEach(0..<param.items.size, id: \.self) { i in
          let item = param.items[i]
          Button {
            self.onClickItem(item)
          } label: {
            itemView(i, item).padding(.vertical, param.padding.itemVertical).padding(.leading, param.padding.leading).padding(.trailing, param.padding.trailing)
              .frame(width: param.maxWidth+param.padding.leading, alignment: .leading).background(param.bgColor)
          }.buttonStyle(BgClickableButton(cornerRadius: param.padding.cornerRadius))
            .disabled(param.disabled?[i] == true)
          if i != param.items.lastIndex {
            Divider.overlayColor(.gray.opacity(0.35)).frame(width: param.maxWidth).padding(.leading,  param.padding.leading)
          }
        }
        param.padding.extraBottom.VSpacer()
      }
    }.frame(width: param.maxWidth+param.padding.leading, height: param.height).background(RoundedRectangle(cornerRadius: param.padding.cornerRadius).fill(param.bgColor)).cornerRadius(param.padding.cornerRadius).shadow(radius: param.radius)
  }
}

#Preview("options") {
  let items =  ["first", "second"]
  let param = DropDownParam(items: items, texts: items, colors: Colors.ICON_COLORS, largeFont: .preferredFont(forTextStyle: .title3))
  DropDownOptionsView<String>(param: param, selected: "first", selectedDecoration: [.Large, .Bold]) { _ in
    
  }
}
