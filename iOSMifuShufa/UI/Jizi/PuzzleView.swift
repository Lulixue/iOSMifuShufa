//
//  PuzzleView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/14.
//

import SwiftUI
import Foundation
import UIKit
import SDWebImage

enum PuzzleSettingsItem {
  case BgColor
  case CharPerColumnRow
  case InsetGap
  case JinMode
  case SingleGap
  
  var settingKey: String {
    "puzzle\(self)"
  }
  
  var defaultValue: Any {
    switch self {
    case .JinMode: false
    case .CharPerColumnRow: 3
    case .InsetGap: 30
    case .SingleGap: 3
    case .BgColor: JiziBgColor.White
    }
  }
  
  var vip: Bool {
    switch self {
    case .JinMode: true
    default: false
    }
  }
  
  var matchVip: Bool {
    !vip || CurrentUser.isVip
  }
  
  var tabTitle: String {
    switch self {
    case .SingleGap: "single_gap".localized
    case .InsetGap: "inset_gap".localized
    case .CharPerColumnRow: (PuzzleSettingsItem.JinMode.value as! Bool) ? "char_per_row".localized : "char_per_col".localized
    default:
      ""
    }
  }
  
  var intValue: Int {
    value as! Int
  }
  
  var boolValue: Bool {
    value as! Bool
  }
  
  var bgColorValue: JiziBgColor {
    value as! JiziBgColor
  }
  
  var value: Any {
    get {
      switch self {
      case .BgColor:
        JiziBgColor(rawValue: Settings.getString(settingKey, (defaultValue as! JiziBgColor).rawValue))!
      case .JinMode:
        Settings.getBoolean(settingKey, defaultValue as! Bool)
      default:
        Settings.getInt(settingKey, defaultValue as! Int)
      }
    }
    set {
      switch self {
      case .BgColor:
        Settings.putString(settingKey, (newValue as! JiziBgColor).rawValue)
      case .JinMode:
        Settings.putBoolean(settingKey, newValue as! Bool)
      default:
        Settings.putInt(settingKey, newValue as! Int)
      }
    }
  }
}


extension PuzzleSettingsItem {
  static let charPerValues = (2...13).map { $0 }
  static let singleGaps = {
    var this = ArrayList<Int>()
    for i in stride(from: 0, to: 30, by: 3) {
      this.add(i)
    }
    return this
  }()
  static let insetGaps = {
    var this = ArrayList<Int>()
    for i in stride(from: 0, to: 40, by: 5) {
      this.add(i)
    }
    return this
  }()
}

enum PuzzleType: String, CaseIterable {
  case SingleRow
  case SingleColumn
  case Multi
  case Duilian
  case Doufang
  
  var chinese: String {
    switch self {
    case .SingleRow: "单行".orCht("單行")
    case .SingleColumn: "单列".orCht("單列")
    case .Multi: "多列".orCht("多行")
    case .Duilian: "对联".orCht("對聯")
    case .Doufang: "斗方"
    }
  }
   
  var icon: String {
    switch self {
    case .SingleRow:
      "arrow.left.square"
    case .SingleColumn:
      "arrow.down.square"
    case .Multi:
      "rectangle.split.3x1"
    case .Duilian:
      "rectangle.split.2x1"
    case .Doufang:
      "rectangle.split.2x2"
    }
  }
  var jinIcon: String {
    switch self {
    case .SingleRow:
      "arrow.right.square"
    case .SingleColumn:
      "arrow.down.square"
    case .Multi:
      "rectangle.split.3x1"
    case .Duilian:
      "rectangle.split.1x2"
    case .Doufang:
      "rectangle.split.2x2"
    }
  }
}

extension Char {
  func charBitmap() -> UIImage {
    if let path = jiziCharUrl?.absoluteString {
      UIImage(contentsOfFile: path) ?? JiziItem.getCharImage(self)
    } else {
      JiziItem.getCharImage(self)
    }
  }
}

struct PuzzleSettingsView: View {
  @EnvironmentObject var viewModel: PuzzleViewModel
  @State var tabIndex = 0
  private let tabItems: [PuzzleSettingsItem] = [.CharPerColumnRow, .InsetGap, .SingleGap]
  
  var currentItem: PuzzleSettingsItem {
    tabItems[tabIndex]
  }
  
  var range: List<Int> {
    switch currentItem {
    case .CharPerColumnRow: PuzzleSettingsItem.charPerValues
    case .InsetGap: PuzzleSettingsItem.insetGaps
    default: PuzzleSettingsItem.singleGaps
    }
  }
  
  @State private var wheelIndex = 0
   
  var binding: Binding<Int> {
    switch currentItem {
    case .CharPerColumnRow:
      $viewModel.charPerColumnRow
    case .InsetGap:
      $viewModel.insetGap
    default:
      $viewModel.singleGap
    }
  }
 
  var body: some View {
    VStack {
      HStack(spacing: 0) {
        Text("排版").font(.callout)
          .foregroundStyle(Colors.iconColor(0))
        15.HSpacer()
        Picker("", selection: $viewModel.jinMode) {
          Text("古代排版").tag(false)
          Text("现代排版".orCht("現代排版")).tag(true)
        }.pickerStyle(.segmented)
      }
      Divider()
      
      HStack(spacing: 0) {
        Text("背景").font(.callout)
          .foregroundStyle(Colors.iconColor(1))
        15.HSpacer()
        Picker("", selection: $viewModel.bgColor) {
          Text("白色背景").tag(JiziBgColor.White)
          Text("黑色背景").tag(JiziBgColor.Black)
        }.pickerStyle(.segmented)
      }
      Divider()
      VStack(spacing: 0) {
        ScrollableTabView(activeIdx: $tabIndex, dataSet: tabItems, settings: ScrollableBarSettings(indicatorColor: .white)) { i, t in
          Text(t.tabTitle).font(.system(size: 14))
            .foregroundStyle(i == tabIndex ? .white : .white.opacity(0.75)).padding(.top, 5)
        }.frame(width: 240).background(Colors.colorAccent.swiftColor)
          .clipShape(RoundedRectangle(cornerRadius: 5))
        Picker("", selection: binding) {
          ForEach(range, id: \.self) { i in
            Text(i.toString()).tag(i)
              .foregroundStyle(Colors.iconColor(3))
          }
        }.pickerStyle(.wheel).frame(maxHeight: 150)
          .id(tabIndex)
      }
    }.padding().frame(width: 250)
      .background(Color.background)
      .clipShape(RoundedRectangle(cornerRadius: 5))
  }
}

class ImageSaver: NSObject {
  var onComplete: () -> Void = {}
  
  init(onComplete: @escaping () -> Void) {
    self.onComplete = onComplete
  }
  
  func writeToPhotoAlbum(image: UIImage) {
    UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
  }
  
  @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    DispatchQueue.main.async {
      self.onComplete()
    }
  }
}

class PuzzleViewModel: AlertViewModel {
  @Published var jinMode = PuzzleSettingsItem.JinMode.boolValue {
    didSet {
      var mode = PuzzleSettingsItem.JinMode
      mode.value = jinMode
    }
  }
  @Published var bgColor = PuzzleSettingsItem.BgColor.bgColorValue {
    didSet {
      var mode = PuzzleSettingsItem.BgColor
      mode.value = bgColor
    }
  }
  
  @Published var singleGap = PuzzleSettingsItem.SingleGap.intValue {
    didSet {
      var mode = PuzzleSettingsItem.SingleGap
      mode.value = singleGap
    }
  }
  
  @Published var insetGap = PuzzleSettingsItem.InsetGap.intValue {
    didSet {
      var mode = PuzzleSettingsItem.InsetGap
      mode.value = insetGap
    }
  }
  
  @Published var charPerColumnRow = PuzzleSettingsItem.CharPerColumnRow.intValue {
    didSet {
      var mode = PuzzleSettingsItem.CharPerColumnRow
      mode.value = charPerColumnRow
    }
  }
  
  @Published var puzzleImages = [PuzzleType: UIImage]()
  @Published var puzzleTypes: [PuzzleType] = [.SingleRow, .SingleColumn, .Multi]
  @Published var counter = 0
  
  let jiziItems: [JiziItem]
  private let imageViews: [UIImageView]
  @Published var images: [Int: UIImage] = [:]
  
  init(items: [JiziItem]) {
    jiziItems = items
    imageViews = items.map({ _ in
      UIImageView(frame: .zero)
    })
    super.init()
    if items.size > 4 && items.size % 2 == 0 {
      puzzleTypes.add(.Duilian)
    } else if items.size == 4 {
      puzzleTypes.add(.Doufang)
    }
    Task {
      initImages()
    }
  }
  
  func saveImage(_ type: PuzzleType) {
    guard let image = puzzleImages[type] else { return }
    imageSaver.writeToPhotoAlbum(image: image)
  }
   
  
  private func typeToImage(_ type: PuzzleType, imgs: [UIImage]) -> UIImage {
    
    let color = bgColor.color
    return switch type {
    case .SingleRow:
      PuzzleLayout.drawHorizontal(bitmaps: imgs, bgColor: color)
    case .SingleColumn:
      PuzzleLayout.drawVertical(bitmaps: imgs, bgColor: color)
    case .Multi:
      PuzzleLayout.drawMultiColumns(bitmaps: imgs, bgColor: color)
    case .Duilian:
      PuzzleLayout.drawDuilian(bitmaps: imgs, bgColor: color)
    case .Doufang:
      PuzzleLayout.drawDoufang(bitmaps: imgs, bgColor: color)
    }
  }
  
  func syncPuzzles() {
    Task {
      debugPrint("chars: \(self.charPerColumnRow), inset: \(self.insetGap), single: \(self.singleGap), bgClor: \(self.bgColor)")
      let imgs = (0..<images.size).map { images[$0]! }
      var puzzleImages = [PuzzleType: UIImage]()
      puzzleTypes.forEach { type in
        puzzleImages[type] = typeToImage(type, imgs: imgs)
      }
      DispatchQueue.main.async {
        self.puzzleImages = puzzleImages
        self.counter += 1
      }
    }
  }
  
  private func initImages() {
    for i in 0..<imageViews.size {
      let view = imageViews[i]
      let item = jiziItems[i]
      let char = item.char
      if let url = item.selected?.url.url {
        
        view.sd_setImage(with: url, placeholderImage: nil, options: [.highPriority],
                         progress: { (downloaded, total, url) in
          
        },  completed:  { (image, error, cacheType, url) in
          self.images[i] = image ?? char.charBitmap()
        })
      } else {
        self.images[i] = char.charBitmap()
      }
      
    }
  }
}


struct PuzzleView: View {
  @StateObject var viewModel: PuzzleViewModel
  @State private var selection: PuzzleType = .Multi
  @Environment(\.presentationMode) var presentationMode
  
  @State private var tabIndex: Int = 2
  @State private var imageParentSize: CGSize = .zero
  @State private var showSettings = false
  var count: Int {
    viewModel.jiziItems.size
  }
  
  @ViewBuilder func typeView(_ type: PuzzleType) -> some View {
    let color = viewModel.bgColor.opposite
    ZStack {
      color.swiftColor
      if let image = viewModel.puzzleImages[type] {
        ZoomImages(images: [image], parentSize: imageParentSize,
                   pageIndex: .constant(0), bgColor: color)
      }
    }.background(color.swiftColor)
      .background(SizeReaderView(binding: $imageParentSize))
  }
  
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        Text("puzzle".resString).foregroundStyle(Color.colorPrimary)
        Spacer()
        Button {
          showSettings.toggle()
        } label: {
          Image(systemName: "ellipsis.circle").square(size: CUSTOM_NAVI_ICON_SIZE-2).foregroundStyle(Color.colorPrimary)
        }
        Button {
          viewModel.saveImage(selection)
        } label: {
          Image("download").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE).foregroundStyle(Color.colorPrimary)
        }
      }.background(Colors.background.swiftColor)
      Divider()
      ZStack(alignment: .top) {
        TabView(selection: $selection) {
          ForEach(viewModel.puzzleTypes, id: \.self) { type in
            typeView(type)
              .tag(type)
              .tabItem {
                Text(type.chinese)
                Image(systemName: viewModel.jinMode ? type.jinIcon : type.icon)
                  .environment(\.symbolVariants, .none)
              }
              .toolbarBackground(.visible, for: .tabBar)
              .toolbarBackground(Color.background, for: .tabBar)
          }
        }.blur(radius: showSettings ? 2 : 0).padding(.top, showSettings ? 2 : 0)
          .id(viewModel.counter)
        if showSettings {
          ZStack(alignment: .top) {
            Color.black.opacity(0.75).onTapGesture {
              showSettings.toggle()
            }
            VStack {
              PuzzleSettingsView().environmentObject(viewModel)
                .padding(.top, 50)
              
              Button {
                showSettings.toggle()
              } label: {
                HStack {
                  Image(systemName: "xmark").square(size: 10)
                  Text("close_window".localized).font(.callout)
                }
              }.buttonStyle(PrimaryButton(bgColor: Colors.souyun.swiftColor, horPadding: 10, verPadding: 8))
                .padding(.top, 20)
            }
          }
        }
      }
    }.navigationBarHidden(true)
      .ignoresSafeArea(edges: showSettings ? [.bottom]: [])
      .onChange(of: viewModel.images) { newValue in
        if viewModel.images.size == viewModel.jiziItems.size {
          viewModel.syncPuzzles()
        }
      }.onChange(of: selection) { newValue in
        let index = viewModel.puzzleTypes.indexOf(newValue)
        if index != tabIndex {
          tabIndex = index
        }
      }
      .onChange(of: tabIndex) { newValue in
        let newType = viewModel.puzzleTypes[newValue]
        if newType != selection {
          selection = newType
        }
      }.onChange(of: viewModel.charPerColumnRow) { _ in
        viewModel.syncPuzzles()
      }
      .onChange(of: viewModel.insetGap) { _ in
        viewModel.syncPuzzles()
      }
      .onChange(of: viewModel.singleGap) { _ in
        viewModel.syncPuzzles()
      }
      .onChange(of: viewModel.bgColor) { _ in
        viewModel.syncPuzzles()
      }.onChange(of: viewModel.jinMode) { newValue in
        viewModel.syncPuzzles()
      }
      .modifier(AlertViewModifier(viewModel: viewModel))
  }
}

#Preview {
  let items = JiziViewModel.search(text: "寒雨连江夜入吴，平明送客楚山孤")
  PuzzleView(viewModel: PuzzleViewModel(items: items))
}


#Preview("settings", body: {
  
  let items = JiziViewModel.search(text: "寒雨连江夜入吴，平明送客楚山孤")
  PuzzleSettingsView().environmentObject(PuzzleViewModel(items: items))
})
