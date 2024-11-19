//
//  FiltersView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/6.
//

import SwiftUI
import Collections

extension CGFloat {
  func rowCount(total: CGFloat, itemSize: CGFloat) -> Int {
    let value = self
    return ((total - value) / (value + itemSize)).toInt()
  }
}

extension UIApplication {
  var appKeyWindow: UIWindow? {
    connectedScenes
      .compactMap {
        $0 as? UIWindowScene
      }
      .flatMap {
        $0.windows
      }
      .first {
        $0.isKeyWindow
      }
  }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
  static var defaultValue: EdgeInsets {
    UIApplication.shared.appKeyWindow?.safeAreaInsets.swiftUiInsets ?? EdgeInsets()
  }
}

private extension UIEdgeInsets {
  var swiftUiInsets: EdgeInsets {
    EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
  }
}

extension EnvironmentValues {
  var safeAreaInsets: EdgeInsets {
    self[SafeAreaInsetsKey.self]
  }
}


struct PaddingValue {
  let top: CGFloat
  let bottom: CGFloat
  let leading: CGFloat
  let trailing: CGFloat
  
  init(top: CGFloat = 0, bottom: CGFloat = 0,
       leading: CGFloat = 0, trailing: CGFloat = 0) {
    self.top = top
    self.bottom = bottom
    self.leading = leading
    self.trailing = trailing
  }
  
  init(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
    self.init(top: vertical, bottom: vertical, leading: horizontal, trailing: horizontal)
  }
}

@ViewBuilder func autoColumnGrid<T>(_ items: List<T>, space: CGFloat,
                                    parentWidth: CGFloat, maxItemWidth: CGFloat,
                                    rowSpace: CGFloat, minSize: Int = 3, keepLastItems: Bool = false,
                                    paddingValues: PaddingValue = PaddingValue(),
                                    @ViewBuilder itemView: @escaping (CGFloat, Int, T) -> some View) -> some View {
  
  let destWidth = parentWidth - paddingValues.leading - paddingValues.trailing
  let rowItemSize = max(space.rowCount(total: destWidth, itemSize: maxItemWidth), minSize)
  let itemWidth = (destWidth - (rowItemSize.toCGFloat() + 1) * space) / rowItemSize.toCGFloat()
  let rowCount = items.size / rowItemSize + ((items.size % rowItemSize > 0) ? 1 : 0)
  VStack(spacing: 0) {
    ForEach(0..<rowCount, id: \.self) { row in
      HStack(spacing: 0) {
        let start = rowItemSize * row
        let end = min(rowItemSize * (row + 1), items.size)
        ForEach(start..<end, id: \.self) { i in
          let item = items[i]
          space.HSpacer()
          HStack(spacing: 0) {
            itemView(itemWidth, i, item)
          }.frame(minWidth: itemWidth)
        }
        if end - start < rowItemSize {
          Spacer()
        } else {
          space.HSpacer()
        }
      }
      if row != rowCount - 1 {
        rowSpace.VSpacer()
      }
    }
  }.padding(.leading, paddingValues.leading)
    .padding(.trailing, paddingValues.trailing)
    .padding(.top, paddingValues.top)
    .padding(.bottom, paddingValues.bottom)
    .onAppear {
      printlnDbg("rowItemSize: \(rowItemSize)")
      printlnDbg("rowCount: \(rowCount)")
      printlnDbg("itemWidth: \(itemWidth)")
    }
}

struct RadicalView: View {
  @EnvironmentObject var viewModel: FilterViewModel
  static let ITEM_WITH: CGFloat = 40
  var contentView: some View {
    LazyVStack(spacing: 0) {
      let keys = Array(RADICAL_DICT.keys)
      ForEach(keys, id: \.self) { k in
        Section {
          let radicals = RADICAL_DICT[k]!
          autoColumnGrid(radicals, space: 15, parentWidth: viewModel.viewWidth, maxItemWidth: Self.ITEM_WITH, rowSpace: 10, paddingValues: PaddingValue(horizontal: 0, vertical: 12)) { size, index, item in
            let selected = viewModel.radicals.containsItem(item)
            Button {
              viewModel.toggleFilter(filter: item, type: .Radical)
            } label: {
              ZStack(alignment: .topTrailing) {
                Text(item)
                  .bold()
                  .lineLimit(1)
                  .foregroundStyle(Color.colorPrimary)
                  .frame(height: size, alignment: .center)
                  .frame(minWidth: size)
                if selected {
                  VStack {
                    Image(systemName: "checkmark")
                      .square(size: 6).foregroundStyle(.white)
                  }
                  .frame(width: 10, height: 10)
                  .background {
                    Circle().fill(Color.colorPrimary)
                  }
                  .padding(.top, 1)
                  .padding(.trailing, 1)
                }
              }
              .padding(.horizontal, item.length > 1 ? 10 : 0)
              .frame(minWidth: size)
              .frame(height: size)
              .background {
                RoundedRectangle(cornerRadius: 5).fill(selected ? Colors.searchHeader.swiftColor.opacity(0.35) : Colors.surfaceContainer.swiftColor)
              }
              .overlay {
                RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
              }
            }.buttonStyle(BgClickableButton())
          }
        } header: {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(k.radicalCountName).frame(alignment: .leading)
              .foregroundColor(Colors.searchHeader.swiftColor)
              .font(.system(size: 15))
            Spacer()
          }.padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.vertical, 8).background(Colors.surfaceVariant.swiftColor)
        }
        
      }
    }
  }
  
  var body: some View {
    ScrollView {
      if viewModel.viewWidth > 0 {
        contentView
      }
    }
  }
}

#Preview("radical") {
  let vm = FilterViewModel()
  return RadicalView().environmentObject(vm)
    .onAppear {
      vm.viewWidth = UIScreen.currentWidth
    }
}

struct StructureList: View {
  @EnvironmentObject var viewModel: FilterViewModel
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        let count = STRUCTURE_DICT.count
        ForEach(0..<count, id: \.self) { i in
          let elem = STRUCTURE_DICT.elements[i]
          let st = (Settings.langChs || elem.value.size == 1) ? elem.value[0] : elem.value[1]
          let binding = Binding {
            viewModel.structures.containsItem(st)
          } set: { newValue in
            viewModel.toggleFilter(filter: st, type: .Structure)
          }
          if i == 0 {
            5.VSpacer()
          }
          Toggle(isOn: binding) {
            HStack {
              Text(st).font(.callout).foregroundColor(Colors.darkSlateGray.swiftColor)
              Spacer()
              Text(elem.key).font(.callout).foregroundColor(.gray)
            }.padding(.trailing, 10).padding(.vertical, 2)
          }.toggleStyle(CheckboxStyle(iconSize: 18))
            .padding(.leading, 10)
          if i != count - 1 {
            Divider().padding(.leading, 10)
          }
        }
      }
    }
  }
}

#Preview("structure") {
  StructureList().environmentObject(FilterViewModel())
}

struct StrokeList: View {
  @EnvironmentObject var viewModel: FilterViewModel
  @State private var selectedIndex = 0
  let tabs = {
    var tabs = [(String, String)]()
    ALL_STROKES.forEach { dic in
      let first = dic.elements.first!
      let value = first.value.first()
      let show = Settings.langChs ? value : value.toChtStroke()
      tabs.add((show, first.key.toString()))
    }
    return tabs
  }()
  
  @ViewBuilder func strokeList(items: OrderedDictionary<Char, List<String>>) -> some View {
    LazyVStack(spacing: 0) {
      let count = items.count
      ForEach(0..<count, id: \.self) { i in
        let elem = items.elements[i]
        let value = elem.value
        let stroke = value[0]
        let binding = Binding {
          viewModel.strokes.containsItem(stroke)
        } set: { newValue in
          viewModel.toggleFilter(filter: stroke, type: .Stroke)
        }
        if i == 0 {
          5.VSpacer()
        }
        Toggle(isOn: binding) {
          HStack {
            let text = Settings.langChs ? value[0] : value[0].toChtStroke()
            Text(text).font(.callout).foregroundColor(Colors.darkSlateGray.swiftColor)
            Spacer()
            Text("例字：\(value[3])").font(.footnote).foregroundColor(.gray)
          }.padding(.trailing, 10).padding(.vertical, 2)
        }.toggleStyle(CheckboxStyle(iconSize: 18))
          .padding(.leading, 10)
        if i != count - 1 {
          Divider().padding(.leading, 10)
        }
      }
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      ScrollableTabView(activeIdx: $selectedIndex, dataSet: tabs, settings: ScrollableBarSettings(indicatorColor: .blue, alignment: .center)) { i, item in
        let selected = i == selectedIndex
        VStack(spacing: 2) {
          Text(item.0.last().toString()).foregroundStyle(selected ? .blue: Color.defaultText)
            .font(.system(size: 14))
//          Text("(\(item.1))").foregroundStyle(selected ? .blue: Colors.defaultText.swiftColor)
//            .font(.system(size: 10))
        }.padding(.horizontal, 5)
      }.padding(.top, 5).frame(maxWidth: .infinity).background(Colors.surfaceContainer.swiftColor)
      ScrollView {
        strokeList(items: ALL_STROKES[selectedIndex])
      }
    }
  }
}

#Preview("stroke") {
  StrokeList().environmentObject(FilterViewModel())
}


struct FilterView: View {
  @EnvironmentObject var viewModel: FilterViewModel
  @State private var type = SearchFilterType.Structure
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("filter".localized).font(.title3)
        Image("filter").renderingMode(.template).square(size: 16)
          .padding(.leading, 3)
        Spacer()
      }.foregroundStyle(Color.colorPrimary).padding(.horizontal, 10)
      12.VSpacer()
      HStack {
        Picker(selection: $type) {
          ForEach(SearchFilterType.allCases, id: \.self) { t in
            let count = viewModel.getItemCount(t)
            let attr = {
              var attr = AttributedString(t.chinese)
              if count > 0 {
                attr.foregroundColor = .red
                var count = AttributedString(count.toString())
                count.font = .system(size: 5)
                count.baselineOffset = 100
                return attr + count
              } else {
                return attr
              }
            }()
            Text(attr).tag(t)
          }
        } label: {
          
        }.pickerStyle(.segmented)
          .frame(maxWidth: 250)
        20.HSpacer()
        Button {
          viewModel.resetAll()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "trash").square(size: 12)
            Text("reset".resString).font(.system(size: 14))
          }.foregroundStyle(Color.red)
        }.buttonStyle(BgClickableButton())
      }.padding(.horizontal, 20)
      12.VSpacer()
      Divider()
      switch type {
      case .Structure:
        StructureList()
      case .Radical:
        RadicalView()
      case .Stroke:
        StrokeList()
      }
    }.background(.white)
  }
}

struct PositionPreferenceKey: PreferenceKey {
  
  static var defaultValue = CGSize.zero
  
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    value = nextValue()
  }
  
  typealias Value = CGSize
}

struct SizePreferenceKey: PreferenceKey {
  
  static var defaultValue = CGSize.zero
  
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    value = nextValue()
  }
  
  typealias Value = CGSize
}

struct SizeReaderView: View {
  @Binding var binding: CGSize
  var body: some View {
    GeometryReader { geo in
      Color.clear
        .preference(key: SizePreferenceKey.self, value: geo.frame(in: .local).size)
    }
    .onPreferenceChange(SizePreferenceKey.self) { h in
      let size = binding
      if (h.width != size.width || h.height != size.height) {
        binding = h
      }
    }
  }
}

struct WidthReaderView: View {
  @Binding var binding: CGFloat
  var body: some View {
    GeometryReader { geo in
      Color.clear
        .preference(key: WidthPreferenceKey.self, value: max(geo.frame(in: .local).size.width, 0))
    }
    .onPreferenceChange(WidthPreferenceKey.self) { h in
      if binding == 0 {
        binding = h
      }
    }
  }
}

struct PositionReaderView: View {
  @Binding var binding: CGSize
  var body: some View {
    GeometryReader { geo in
      Color.clear
        .preference(key: PositionPreferenceKey.self, value: {
          let frame = geo.frame(in: .global)
          return CGSize(width: frame.minX, height: frame.maxY)
        }())
    }
    .onPreferenceChange(PositionPreferenceKey.self) { h in
      let size = binding
      if (h.width != size.width || h.height != size.height) {
        binding = h
      }
    }
  }
}

#Preview("filter") {
  FilterView().environmentObject(FilterViewModel())
}
