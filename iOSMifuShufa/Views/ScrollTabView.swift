//
//  ScrollTabView.swift
//  iOSChinesePoemDict
//
//  Created by 肖李根 on 2023/7/8.
//

import SwiftUI

extension HorizontalAlignment {
  private enum UnderlineLeading: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat {
      return d[.leading]
    }
  }
  
  static let underlineLeading = HorizontalAlignment(UnderlineLeading.self)
}

struct HeightPreferenceKey: PreferenceKey {
  static var defaultValue = CGFloat(0)
  
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
  
  typealias Value = CGFloat
}
struct WidthPreferenceKey: PreferenceKey {
  static var defaultValue = CGFloat(0)
  
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
  
  typealias Value = CGFloat
}

struct ScrollableBarSettings {
  var textColors: [Color] = [Color(UIColor.systemGray4), Color.white]
  var textFonts: [Font] = [Font.system(size: 18, weight: .medium),
                           .system(size: 18, weight: .bold)]
  var indicatorHeight: CGFloat = 2.5
  var indicatorRadius: CGFloat = 3
  var indicatorColor: Color = .white
  var indicatorPadding: CGFloat = 5
  var indicatorTextSpacing: CGFloat = 5
  var tabSpacing: CGFloat = 10
  var alignment: HorizontalAlignment = .center
  var leadingSpace: CGFloat = 0
  var backgroundColor: Color = .clear
  var selectAnimation: Bool = true
  var extraTabSize: Int = 0
  var buttonStyle: Bool = false
  var indicatorWidth: CGFloat? = nil
  var selectedFont: Font {
    textFonts[1]
  }
  var normalFont: Font {
    textFonts[0]
  }
  var noramlColor: Color {
    textColors[0]
  }
  var selectedColor: Color {
    textColors[1]
  }
}

struct ScrollBarGuideModifier: ViewModifier {
  let width: CGFloat
  func body(content: Content) -> some View {
    content
    .alignmentGuide(.underlineLeading) { d in
      d[.leading] + width / 2
    }
  }
}

struct ScrollableTabView<Data, ItemView: View> : View {
  
  @Binding var activeIdx: Int
  @State private var w: [CGFloat]
  private let dataSet: [Data]
  private let settings: ScrollableBarSettings
  private let onClickTab: (Int) -> Void
  @ViewBuilder var mapper: (Int, Data) -> ItemView
  init(activeIdx: Binding<Int>, dataSet: [Data], settings: ScrollableBarSettings, onClickTab: @escaping (Int) -> Void = { _ in }, @ViewBuilder  mapper: @escaping (Int, Data) -> ItemView) {
    self._activeIdx = activeIdx
    self.dataSet = dataSet
    self.settings = settings
    _w = State.init(initialValue: [CGFloat](repeating: 0, count: dataSet.count + settings.extraTabSize))
    self.onClickTab = onClickTab
    self.mapper = mapper
  }
  
  var width: CGFloat {
    if activeIdx < w.size {
      w[activeIdx]
    } else {
      10
    }
  }
  
  var body: some View {
    VStack(alignment: .underlineLeading, spacing: 0) {
      HStack {
        if settings.alignment == .leading {
          Spacer.width(settings.leadingSpace)
        }
        ForEach(0..<dataSet.count, id:\.self) { i in
          Spacer().frame(width: settings.tabSpacing)
          HStack(spacing: 0) {
            if settings.buttonStyle {
              Button {
                onClickTab(i)
                activeIdx = i
              } label: {
                mapper(i, dataSet[i])
                  .background(TextGeometry())
                  .modifier(ScrollableTabViewModifier(activeIdx: $activeIdx, idx: i, onClickTab: onClickTab, animation: settings.selectAnimation))
                  .onPreferenceChange(WidthPreferenceKey.self, perform: { self.w[i] = $0 })
                  .id(i)
              }.buttonStyle(BgClickableButton())
            } else {
              mapper(i, dataSet[i])
                .modifier(ScrollableTabViewModifier(activeIdx: $activeIdx, idx: i, onClickTab: onClickTab, animation: settings.selectAnimation))
                .background(TextGeometry())
                .onPreferenceChange(WidthPreferenceKey.self, perform: {
                  if self.w.size > i {
                    self.w[i] = $0
                  }
                })
                .id(i)
            }
          }
          Spacer().frame(width: settings.tabSpacing)
        }
        if settings.alignment == .leading {
          Spacer()
        }
      }
      Spacer().frame(height: settings.indicatorTextSpacing)
      if let width = settings.indicatorWidth {
        HStack(alignment: .center) {
          Rectangle()
            .fill(settings.indicatorColor)
            .cornerRadius(settings.indicatorRadius)
            .frame(width: width, height: settings.indicatorHeight)
            .modifier(IndicatorModifier(animation: settings.selectAnimation))
        }
        .frame(width: width)
        .alignmentGuide(.underlineLeading) { d in d[.leading]}
      } else {
        Rectangle()
          .fill(settings.indicatorColor)
          .alignmentGuide(.underlineLeading) { d in d[.leading]}
          .cornerRadius(settings.indicatorRadius)
          .frame(width: width,  height: settings.indicatorHeight)
          .modifier(IndicatorModifier(animation: settings.selectAnimation))
      }
      if settings.indicatorPadding > 0 {
        Spacer().frame(height: settings.indicatorPadding)
      }
    }
  }
}

struct IndicatorModifier: ViewModifier {
  let animation: Bool
  func body(content: Content) -> some View {
    if animation {
      content.animation(.linear.speed(5))
    } else {
      content
    }
  }
}
struct TextGeometry: View {
  var body: some View {
    GeometryReader { geometry in
      return Rectangle().fill(Color.clear).preference(key: WidthPreferenceKey.self, value: geometry.size.width)
    }
  }
}

struct ScrollableTabViewModifier: ViewModifier {
  @Binding var activeIdx: Int
  let idx: Int
  let onClickTab: (Int) -> Void
  let animation: Bool
  
  
  func selectTab() {
    onClickTab(self.idx)
    self.activeIdx = self.idx
  }
  
  func body(content: Content) -> some View {
    Group {
      if activeIdx == idx {
        content.alignmentGuide(.underlineLeading) { d in
          return d[.leading]
        }.onTapGesture {
          if animation {
            withAnimation{
              selectTab()
            }
          } else {
            selectTab()
          }
        }
        
      } else {
        content.onTapGesture {
          if animation {
            withAnimation{
              selectTab()
            }
          } else {
            selectTab()
          }
        }
      }
    }
  }
}

struct TabScrollBar : View {
  @Binding var dataModel: [String]
  @Binding var selection: Int
  let settings: ScrollableBarSettings
  let fixedWidth: CGFloat
  
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false, content: {
      ScrollViewReader { scrollReader in
        ScrollableTabView(activeIdx: $selection,dataSet: dataModel, settings: settings) { i, title in
          let font = i == selection ? settings.selectedFont : settings.normalFont
          let color = i == selection ? settings.selectedColor : settings.noramlColor
          Text(title)
            .font(font)
            .foregroundColor(color)
        }
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0)).onChange(of: selection, perform: { value in
          withAnimation {
            scrollReader.scrollTo(value, anchor: .center)
          }
        })
      }.frame(minWidth: fixedWidth)
    })
  }
}
