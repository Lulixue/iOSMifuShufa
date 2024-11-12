//
//  BeitieViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/4.
//
import SwiftUI
import Foundation
import Collections


enum BeitieOrderType: String, CaseIterable {
  case Default
  case Font
  case `Type`
  case Az
  case TimeAsc
  case TimeDesc
  
  var chinese: String {
    switch self {
    case .Default: "默认排序".orCht("默認排序")
    case .Font: "书体排序".orCht("書體排序")
    case .Type: "碑帖类型排序".orCht("碑帖類型排序")
    case .Az: "拼音排序".orCht("拼音排序")
    case .TimeAsc: "创作时间升序".orCht("創作時間升序")
    case .TimeDesc: "创作时间降序".orCht("創作時間降序")
    }
  }
}

extension BeitieOrderType {
  private static let KEY = "beitieOrderType"
  private static let KEY_LIST_VIEW = "beitieListView"
  private static let KEY_ORGANIZE_STACK = "organizeStack"
  
  
  static var entries: List<BeitieOrderType> {
    allCases
  }
  
  static var orderType: BeitieOrderType {
    get {
      let defType = BeitieOrderType.Default
      return BeitieOrderType(rawValue: Settings.getString(KEY, defType.rawValue)) ?? defType
    }
    set {
      Settings.putString(Self.KEY_ORGANIZE_STACK, newValue.rawValue)
    }
  }
  
  static var organizeStack: Bool {
    get {
      return Settings.getBoolean(Self.KEY_ORGANIZE_STACK, true)
    }
    set {
      Settings.putBoolean(Self.KEY_ORGANIZE_STACK, newValue)
    }
  }
  
  static var listView: Bool {
    get {
      return Settings.getBoolean(Self.KEY_LIST_VIEW, false)
    }
    set {
      Settings.putBoolean(Self.KEY_LIST_VIEW, newValue)
    }
  }
}


class BeitieViewModel: AlertViewModel {
  let searchBarHeight: CGFloat = 40
  @Published var showVersionWorks = false
  @Published var searchText = ""
  @Published var showSearchBar = false
  @Published var listView = BeitieOrderType.listView {
    didSet {
      BeitieOrderType.listView = listView
    }
  }
  @Published var organizeStack = BeitieOrderType.organizeStack {
    didSet {
      BeitieOrderType.organizeStack = organizeStack
    }
  }
  
  @Published var orderType = BeitieOrderType.orderType {
    didSet {
      BeitieOrderType.orderType = orderType
    }
  }
  
  var SEARCH_RESULT: String { "匹配碑帖" }
  var BEITIE: String { "title_beitie".resString }
  var BEITIE_IMG: String { "beitie_img".resString }
  @Published var versionWorks = [BeitieWork]()
  @Published var showMap: BeitieDbHelper.BeitieDictionary = BeitieDbHelper.shared.getDefaultTypeWorks()
  
  func onSearch() {
    let text = searchText.trim()
    if (!verifySearchText(text: text)) {
      return
    }
    doSearch(text)
  }
  
  
  
  func doSearch(_ text: String) {
    Task {
      var result = BeitieDbHelper.BeitieDictionary()
      BeitieDbHelper.shared.getDefaultTypeWorks().forEach { (k, v) in
        var items = [[BeitieWork]]()
        v.forEach { works in
          let result = works.filter { $0.matchKeyword(keyword: text) }
          if result.isNotEmpty() {
            items.add(result)
          }
        }
        if (items.isNotEmpty()) {
          result[k] = items
        }
      }
      DispatchQueue.main.async {
        if !result.isEmpty {
          self.showMap = result
        } else {
          self.showAlertDlg("no_result".resString)
        }
      }
    }
  }
  
  func syncShowMap() {
    showMap = BeitieDbHelper.shared.getOrderTypeWorks(orderType, organizeStack)
  }
  
  func updateVersionWorks(works: List<BeitieWork>) {
    showVersionWorks = true
    versionWorks = Array(works)
  }
  
  func dismissSearchBar() {
    withAnimation {
      self.showSearchBar = false
    }
  }
   
  func hideVersionWorks() {
    showVersionWorks = false 
  }
  lazy var param = {
    let types = BeitieDbHelper.shared.SUPPORT_ORDER_TYPES
    return DropDownParam(items: types, texts: types.map({ $0.chinese }), colors: Colors.ICON_COLORS,
                         largeFont: nil,
                         padding: DropDownPadding(itemVertical: 9),
                         bgColor: .white)
  }()
  
  override init() {
    super.init()
//    updateVersionWorks(works: showMap.elements.first!.value.first())
  }
}
