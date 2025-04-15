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
  
  static let azMap = {
    var azMap = [Char : [Char]]()
    let contents = ResourceHelper.readFileContents(fileURL: Bundle.main.url(forResource: "az", withExtension:"json")!)
    do {
      let collections = try JSONDecoder().decode([String: [String]].self, from: contents.utf8Data)
      for key in collections.keys {
        let az = key.first()
        let items = collections[key].map { $0.map { item in
          item.first()
        } }
        azMap[az] = items
      }
    } catch {
      println("azMap \(error)")
    }
    return azMap
  }()
  
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
  let searchBarHeight: CGFloat = 43
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
  
  @Published var searchResult = OrderedDictionary<String, Any>()
  @Published var showSearchResult = false
  var orderParam: DropDownParam<String>!
  
  private func toOrderParam() -> DropDownParam<String> {
    let keys = showMap.entries.map { keyToString(key: $0.key) + "(\($0.value.size))" }
    return DropDownParam(items: keys, texts: keys, colors: Colors.ICON_COLORS)
  }
  
  var SEARCH_RESULT: String { "匹配碑帖" }
  var BEITIE: String { "title_beitie".resString }
  var BEITIE_IMG: String { "beitie_img".resString }
  @Published var versionWorks = [BeitieWork]()
  @Published var showMap: BeitieDbHelper.BeitieDictionary = BeitieDbHelper.shared.getDefaultTypeWorks() {
    didSet {
      orderParam = toOrderParam()
    }
  }
  
  func onSearch() {
    let text = searchText.trim()
    if (!verifySearchText(text: text)) {
      return
    }
    doSearch(text)
  }
  
  func doSearch(_ text: String) {
    Task {
      var allResult = OrderedDictionary<String, Any>()
      var items = List<List<BeitieWork>>()
      let map = BeitieDbHelper.shared.getDefaultTypeWorks(organizeStack)
      map.forEach { (k, v) in
        let r = v.map { works in works.filter { $0.matchKeyword(keyword: text) } }.filter { $0.isNotEmpty() }
        if r.isNotEmpty() {
          items.addAll(r)
        }
      }
      
      if (items.isNotEmpty()) {
        var matchResult = BeitieDbHelper.BeitieDictionary()
        matchResult[BEITIE] = items
        allResult[BEITIE] = matchResult
      }
      
      let images = BeitieDbHelper.shared.getMatchKeywordImages(text.sqlLike)
      if (images.isNotEmpty()) {
          let works = images.map { it in it.work }.distinct()
          var orderWorks = List<BeitieWork>()
          map.values.forEach { it in
            for w in it {
              for sw in w {
                if works.containsItem(sw) {
                  orderWorks.add(sw)
                }
              }
            }
          }
          allResult[BEITIE_IMG] = orderWorks.map { it in
            BeitieImageMatch(work: it, images: images.filter { img in img.workId == it.id }.sortedBy { img in img.index }, keyword: text)
          }
        }
      
      DispatchQueue.main.async {
        if !allResult.isEmpty {
          self.showSearchResult = true
          self.searchResult = allResult
        } else {
          self.showSearchResult = false
          self.showAlertDlg("no_results".resString)
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
    orderParam = toOrderParam()
  }
}


struct BeitieImageMatch {
  let work: BeitieWork
  let images: List<BeitieImage>
  let keyword: String
  let htmls: List<AttributedString>
  
  init(work: BeitieWork, images: List<BeitieImage>, keyword: String) {
    self.work = work
    self.images = images
    self.keyword = keyword
    self.htmls = images.map { BeitieImageMatch.imageShowText($0, keyword).toHtmlString(font: .preferredFont(forTextStyle: .body))!.swiftUIAttrString }
  }
  
  static func imageShowText(_ image: BeitieImage, _ keyword: String) -> String {
    for s in List.arrayOf(image.chineseText() ?? "", image.text, image.textCht).filter({ $0 != nil }) {
      if (s!.contains(keyword)) {
        return s!.trim().splitMatchedPart(keyword)
      }
    }
    return ""
  }
}


extension String {
  
  func substring(_ start: Int, _ end: Int) throws -> String {
    var result = ""
    for i in start..<end {
      result.append(this[i].toString())
    }
    return result
  }
  
  subscript(_ index: Int) -> Character {
    let subIndex = self.index(self.startIndex, offsetBy: index)
    return self[subIndex]
  }
  
  func ellipseEnd(_ maxLength: Int, _ count: Int = 100000) -> String {
    if (self.length < maxLength) {
      return this
    } else {
      var sb = ""
      sb = sb + (try! substring(0, maxLength))
      for i in maxLength..<this.length {
        let char = this[i]
        sb.append(char)
        if (sb.length > count) {
          break
        }
        if (SHICI_END_SEPARATORS.contains(char)) {
          break
        }
      }
      sb = sb + "..."
      return sb.toString()
    }
  }
  
  func splitMatchedPart(_ keyword: String) ->String {
    guard let matchIndex = self.index(of: keyword) else { return self }
    let index = self.distance(from: self.startIndex, to: matchIndex)
    var separatorCount = 0
    var start = 0
    for i in (0...index).reversed() {
      let char = self[i]
      if (!char.charIsChinesChar()) {
        separatorCount += 1
        if (separatorCount == 2 || END_SEPARATORS.contains(char)) {
          start = i+1
          break
        }
      }
    }
    for i in start..<index {
      if (self[i].charIsChinesChar()) {
        start = i
        break
      }
    }
    
    var end = index + keyword.length
    separatorCount = 0
    var previous: Character = "一"
    for i in (index+keyword.length)..<this.length {
      let char = this[i]
      if (char.isLineSeparator() && !previous.isLineSeparator()) {
        separatorCount += 1
        if (separatorCount == 2 || SHICI_END_SEPARATORS.contains(char)) {
          end = i
          break
        }
      }
      previous = char
    }
    do {
      var ret = try this.substring(start, end + 1)
      
      if !SHICI_END_SEPARATORS.contains(ret.last()) {
        ret = ret.dropLast(1) + "..."
      }
      return ret.addMatchIndicator(keyword)
    } catch {
      return ""
    }
  }
  
  func replace(_ oldChar: String, _ newChar: String) -> String {
    return self.replacingOccurrences(of: oldChar, with: newChar, options: .literal, range: nil)
  }
  
  func addMatchIndicator(_ keyword: String?) -> String {
    if let keyword = keyword {
      if (self.contains(keyword)) {
        return self.replace(keyword, "<font color='#FF0000'>\(keyword)</font>")
      }
    }
    return self
  }
  
  func substring(_ start: Int) throws -> String {
    var result = ""
    for i in start..<self.length {
      result.append(this[i].toString())
    }
    return result
  }
  
  func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
    range(of: string, options: options)?.lowerBound
  }
}

extension Char {
  
  private static let LINE_SEPARATORS = [DOUHAO, DOUHAO_BAN, FENHAO, FENHAO_BAN, JUHAO, JUHAO_BAN, WENHAO, WENHAO_BAN, TANHAO, TANHAO_BAN]
  func isLineSeparator() -> Boolean {
    return Self.LINE_SEPARATORS.contains(self)
  }
}
