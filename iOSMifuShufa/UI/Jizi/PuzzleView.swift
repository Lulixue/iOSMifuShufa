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
    case .CharPerColumnRow, .InsetGap: 6
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
      "arrow.right.square"
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
}

extension Char {
  func charBitmap() -> UIImage {
    PuzzleLayout.charImage(c: self)
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
      let imgs = (0..<images.size).map { images[$0]! }
      var puzzleImages = [PuzzleType: UIImage]()
      puzzleTypes.forEach { type in
        puzzleImages[type] = typeToImage(type, imgs: imgs)
      }
      DispatchQueue.main.async {
        self.puzzleImages = puzzleImages
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
  
  var count: Int {
    viewModel.jiziItems.size
  }
  
  @ViewBuilder func typeView(_ type: PuzzleType) -> some View {
    ZStack {
      viewModel.bgColor.opposite.swiftColor
      if let image = viewModel.puzzleImages[type] {
//        let images = viewModel.puzzleTypes.map { viewModel.puzzleImages[$0]! }
        ZoomImages(images: [image], parentSize: imageParentSize,
                   pageIndex: .constant(0))
      }
    }.background(viewModel.bgColor.opposite.swiftColor)
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
          
        } label: {
          Image(systemName: "ellipsis.circle").square(size: CUSTOM_NAVI_ICON_SIZE-2).foregroundStyle(Color.colorPrimary)
        }
        Button {
          
        } label: {
          Image("download").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE).foregroundStyle(Color.colorPrimary)
        }
      }.background(Colors.background.swiftColor)
      Divider()
      TabView(selection: $selection) {
        ForEach(viewModel.puzzleTypes, id: \.self) { type in
          typeView(type)
            .tag(type)
            .tabItem {
              Text(type.chinese)
              Image(systemName: type.icon)
                .environment(\.symbolVariants, .none)
            }
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color.background, for: .tabBar)
        }
      }
    }.navigationBarHidden(true)
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
      }
  }
}

#Preview {
  let items = JiziViewModel.search(text: "寒雨连江夜入吴，平明送客楚山孤")
  PuzzleView(viewModel: PuzzleViewModel(items: items))
}
