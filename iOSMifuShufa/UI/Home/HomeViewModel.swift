//
//  HomeViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import Collections
import SwiftUI


enum BeitieType {
  case Work, Reference, Fake;
}

extension BeitieWork {
  var btType: BeitieType {
    if !isTrue() {
      BeitieType.Fake
    } else if author == BeitieDbHelper.shared.CALLIGRAPHER {
      BeitieType.Work
    } else {
      BeitieType.Reference
    }
  }
}

extension BeitieType {
  func nameColor(baseColor: Color) -> Color {
    switch self {
    case .Work:
      baseColor
    case .Reference:
      Color.searchHeader
    case .Fake:
      Color.red
    }
  }
}


extension Array where Element == Char {
  func toString() -> String {
    var sb = StringBuilder()
    forEach { c in
      sb.append(c)
    }
    return sb
  }
}

enum SearchCharType {
  case Char, Component
  
  var chinese: String {
    switch self {
    case .Char:
      "汉字".orCht("漢字")
    case .Component:
      "部件"
    }
  }
  
  var hint: String {
    switch self {
    case .Char:
      "dict_search_hint".resString
    case .Component:
      "dict_search_component_hint".resString
    }
  }
  
  var otherwise: SearchCharType {
    switch self {
    case .Char:
        .Component
    case .Component:
        .Char
    }
  }
}
extension String {
  var this: String {
    self
  }
  
  func toInt() -> Int {
    Int(self)!
  }
  
  func toInts() -> List<Int> {
    return this.split(separator: ",").map({ "\($0)" }).filter { it in it.isNotEmpty() }.map { it in it.toInt() }
  }

}
extension Array where Element : Any {
  func toSettingString() -> String {
    var sb = ""
    for elem in self {
      sb.append("\(elem)")
      sb.append(",")
    }
    if (sb.isNotEmpty()) {
      sb.removeLast()
    }
    return sb
  }
}

enum SearchResultOrder: String, CaseIterable {
  case Default
  case Char
  case Author
  case Beitie
  case Tile
  
  var chinese: String {
    switch self {
    case .Default: "默认".orCht("默認")
    case .Char: "汉字".orCht("漢字")
    case .Author: "书法家".orCht("書法家")
    case .Beitie: "碑帖"
    case .Tile: "平铺".orCht("平鋪")
    }
  }
  
  func getOrderKey(_ single: BeitieSingle, short: Bool = false) -> String {
    switch self {
    case .Default:
      (single.matched ?? single.chars.first()).toString()
    case .Char:
      single.chars.first().toString()
    case .Author:
      single.work.chineseAuthor()
    case .Beitie:
      short ? single.work.shortName : single.work.chineseFolder()
    case .Tile:
      ""
    }
  }
  
  
  func getSingleTitle(_ single: BeitieSingle) -> String {
    switch self {
    case .Default: single.work.chineseName()
    case .Char: single.work.chineseName()
    case .Author: single.showChars
    case .Beitie: single.showChars
    case .Tile: single.showChars
    }
  }
  
  
  func getSingleSubtitle(_ single: BeitieSingle) -> String? {
    switch self {
    case .Default: nil
    case .Char: nil
    case .Author: single.work.chineseName()
    case .Beitie: nil
    case .Tile: single.work.chineseName()
    }
  }
  
  func mapToOrderResult(_ charResults: LinkedHashMap<AnyHashable, List<BeitieSingle>>, fromRawResearch: Boolean) -> LinkedHashMap<AnyHashable, List<BeitieSingle>> {
    let resultOrder = self
    if (fromRawResearch && resultOrder == .Default) {
      return charResults
    }
    var result = LinkedHashMap<AnyHashable, List<BeitieSingle>>()
    if (resultOrder == .Tile) {
      var all = List<BeitieSingle>()
      charResults.values.forEach { it in
        all.addAll(it)
      }
      result[""] = all
      return result
    }
    charResults.values.forEach { list in
      list.forEach { it in
        let key = resultOrder.getOrderKey(it)
        var singles = result[key] ?? []
        singles.add(it)
        result[key] = singles
      }
    }
    if (resultOrder == .Char) {
      var equalCharsResult = LinkedHashMap<AnyHashable, List<BeitieSingle>>()
      result.forEach { (_, u) in
        var chars = u.first().chars
        u.forEach { it in
          it.chars.forEach { c in
            if (!chars.containsItem(c)) {
              chars.append(c)
            }
          }
        }
        equalCharsResult[chars.separatedChars] = u
      }
      return equalCharsResult
    }
    return result
  }
}


class HomeViewModel : AlertViewModel {
  @Published var orderWidth: CGFloat = 0.0
  @Published var fastRedirectWidth: CGFloat = 0.0
  @Published var fontWidth: CGFloat = 0.0
  @Published var showOrder = false
  @Published var showFastRedirect = false
  @Published var showFont = false
  @Published var filterViewModel = FilterViewModel()
  @Published var searchCharType = SearchCharType.Char
  @Published var text = ""
  @Published var focused = false
  @Published var showHistoryBar = false
  @Published var showDeleteAlert: Bool = false
  private let page = SearchPage.Search
  
  @Published var showPreview = false
  @Published var preferredFont: CalligraphyFont? = nil
  @Published var resultFonts: [CalligraphyFont] = []
  @Published var singleResult = OrderedDictionary<AnyHashable, List<BeitieSingle>>()
  @Published var resultKeys = [String]()
  @Published var allCollapse = false
  @Published var fastResultIndex = -1
  @Published var fastResultKeys = -1
  @Published var fontResultKeys = OrderedDictionary<CalligraphyFont?, String>()
  @Published var originalResult = OrderedDictionary<AnyHashable, List<BeitieSingle>>()
  
  @Published var todaySingle: BeitieSingle!
  @Published var todayWork: BeitieWork!
  
  @Published var selectedSingleItem: BeitieSingle! = nil
  @Published var selectedSingleIndex = 0
  @Published var selectedSingleCollection = [BeitieSingle]()
  @Published var orderTypeParam: DropDownParam<SearchResultOrder>!
  @Published var fastDirectParam: DropDownParam<Int>!
  @Published var fontParam: DropDownParam<CalligraphyFont?>!
  
  var resultId: String {
    "\(order)\(String(describing: preferredFont))"
  }
  
  private lazy var orderKeys = {
    var map = Map<SearchResultOrder, ArrayList<String>>()
    SearchResultOrder.allCases.forEach { it in
      map[it] = ArrayList()
    }
    return map
  }()
  
  private func resetOrderKeys() {
    SearchResultOrder.allCases.forEach { it in
      orderKeys[it] = ArrayList()
    }
  }
  
  private let todaySingleKey = "todaySingle"
  private var lastTodaySingles: List<Int> {
    get { Settings.getString(todaySingleKey, "").toInts() }
    set {
      Settings.putString(todaySingleKey, newValue.toSettingString())
    }
  }
  
  var filters: FilterViewModel {
    filterViewModel
  }
  
  @Published var searching: Bool = false
  @discardableResult
  func onSearch(_ searchText: String) -> Bool {
    var searchTextDo = searchText
    let hasFilter = filterViewModel.hasFilter
    if !hasFilter && searchText.isEmpty {
#if DEBUG
      searchTextDo = BeitieDbHelper.shared.CALLIGRAPHER
#endif
    }
    showFont = false
    showOrder = false
    showFastRedirect = false
    let validSearchText = searchTextDo.containsChineseChar
    if (!validSearchText) {
      if (!hasFilter) {
        return verifySearchText(text: searchTextDo)
      }
    }
//    if (validSearchText && searchTextDo.chineseCount > ConstraintItem.SearchZiCount.topMostConstraint) {
//      appDialogData.showConstraintVip(context, ConstraintItem.SearchZiCount.topMostConstraintMessage)
//      return false
//    }
//      let logText =  (validSearchText) ? searchTextDo : filterViewModel.getFiltersInfo()
//      HistoryDbHelper.appendLog(page, logText, validSearchText.toString())
    doSearch(searchTextDo)
    return true
  }
  
  private func doSearch(_ text: String) {
    searching = true
    Task {
      var fonts = Set<CalligraphyFont>()
      let chars = text.filter { it in it.charIsChinesChar() }.toCharList.distinctBy { $0 }
      var result = LinkedHashMap<AnyHashable, List<BeitieSingle>>()
      if (chars.isEmpty()) {
        if (filters.hasFilter) {
          let found = BeitieDbHelper.shared.searchByFilter(filters).matchSearch()
          if (found.isNotEmpty()) {
            for s in found {
              s.font = s.work.font
              fonts.add(s.font!)
              let key = s.writtenChar
              var existed = result[key] ?? ArrayList()
              existed.add(s)
              if (!result.containsKey(key)) {
                result[key] = existed
              }
            }
          }
        }
      } else {
        chars.forEach { it in
          let foundAll = ((searchCharType == SearchCharType.Char) ? BeitieDbHelper.shared.search(it) : BeitieDbHelper.shared.searchComponent(it)).matchSearch()
          if (foundAll.isNotEmpty()) {
            for s in foundAll {
              s.matched = it
              s.font = s.work.font
              fonts.add(s.font!)
            }
            result[it] = foundAll
          }
        }
      }
      DispatchQueue.main.async {
        self.originalResult.removeAll()
        result.forEach { (k, v) in
          self.originalResult[k] = v
        }
        self.resultFonts = fonts.toList()
        if let prefer = self.preferredFont {
          if (!fonts.containsItem(prefer)) {
            self.preferredFont = nil
          }
        }
        self.updateOrderResult(result)
        if (self.singleResult.isEmpty) {
          self.showAppDialog("no_results".resString)
        }
        self.searching = false
      }
    }
  }
  
  @Published var order = SearchResultOrder.Default
  @Published var collapseStates = HashMap<AnyHashable, Bool>()
  
  func updatePreferredFont(_ new: CalligraphyFont?) {
    if new == preferredFont {
      return
    }
    preferredFont = new
    updateOrderResult(originalResult)
  }
  func updateOrder(_ new: SearchResultOrder) {
    if new == order {
      return
    }
    order = new
    updateOrderResult(originalResult)
  }
  
  private func updateOrderResult(_ result: LinkedHashMap<AnyHashable, List<BeitieSingle>>,
                                 fromRawResearch: Boolean = true) {
    let font = preferredFont
    resetOrderKeys()
    let orderType = order
    var orderWorks = HashMap<Int, Int>()
    
    BeitieDbHelper.shared.getOrderTypeWorks(BeitieOrderType.orderType, false).elements.forEach { it in
      for work in it.value.map({ w in w.first() }) {
        orderWorks[work.id] = orderWorks.size
      }
    }
    var orderResult = LinkedHashMap<AnyHashable, List<BeitieSingle>>()
    let map = orderType.mapToOrderResult(result, fromRawResearch: fromRawResearch)
    map.elements.forEach { it in
      let singles = (font == nil) ? it.value : it.value.filter { s in s.font == font }
      if (singles.isNotEmpty()) {
        orderResult[it.key] = singles.sorted(by: { f, s in
          orderWorks[f.workId]! > orderWorks[s.workId]!
        })
        SearchResultOrder.allCases.forEach { o in
          singles.forEach { single in
            let key = o.getOrderKey(single)
            orderKeys[o]!.addDistinct(key)
          }
        }
      }
    }
    
    syncOrderIndex(orderResult)
    singleResult = {
      var map = LinkedHashMap<AnyHashable, List<BeitieSingle>>()
      orderResult.elements.forEach { it in
        map[it.key] = it.value
      }
      return map
    }()
    
    let orders = SearchResultOrder.allCases.filter({ $0 != .Author })
    orderTypeParam = DropDownParam(items: orders, texts: orders.map({ $0.chinese + "(\(orderKeys[$0]!.count))" }), colors: Colors.ICON_COLORS)
    let range = 0..<resultKeys.size
    fastDirectParam = DropDownParam(items: range.toList(), texts: resultKeys)
    let keys = Array(fontResultKeys.keys)
    fontParam = DropDownParam(items: keys, texts: keys.map({ key in
      fontResultKeys[key]!
    }))
    allCollapse = false
  }
  
  func toggleCollapseAll() {
    allCollapse.toggle()
    let keys = Array(collapseStates.keys)
    for key in keys {
      collapseStates[key] = allCollapse
    }
  }
  
  func collapseBinding(_ key: AnyHashable) -> Binding<Bool> {
    Binding {
      self.collapseStates[key] ?? false
    } set: {
      self.collapseStates[key] = $0
    }
  }
  
  
  func currentFontResultKey() -> String { fontResultKeys[preferredFont] ?? "" }

  
  private func syncOrderIndex(_ orderResult: LinkedHashMap<AnyHashable, List<BeitieSingle>>) {
    
    resultKeys = {
      var result = [String]()
      var total = 0
      orderResult.elements.forEach({ (_, v) in
        total += v.size
      })
      result.add("全部(\(total))")
      if (order != SearchResultOrder.Tile) {
        result.addAll(orderResult.entries.map { it in it.key.toString().countString(it.value.size) })
      }
      return result
    }()
    fontResultKeys =  {
      var this = LinkedHashMap<CalligraphyFont?, String>()
      this[nil] = "字体".orCht("字體")
      if resultFonts.isNotEmpty() {
        CalligraphyFont.allCases.filter { it in resultFonts.contains(it) }.forEach { it in
          this[it] = it.longChinese.countString(originalResult.values.sumOf { v in
            v.filter { s in s.font == it }.size })
        }
      }
      return this
    }()
    
    fastResultIndex = -1
    orderResult.forEach { (t, _) in
      collapseStates[t] = false
    }
  }
  
  func onClickSinglePreview(_ index: Int, collection: Array<BeitieSingle>) {
    selectedSingleIndex = index
    selectedSingleCollection = collection
    showPreview = true
  }
  
  private func initToday() {
    Task {
      var history = ArrayList(lastTodaySingles)
      let availableWorks = BeitieDbHelper.shared.works.filter { it in it.hasSingle() && it.isTrue() && it.author == BeitieDbHelper.shared.CALLIGRAPHER }
      let index = Int.random(in: 0..<availableWorks.size)
      let tWork = availableWorks[index]
      let singles = BeitieDbHelper.shared.getTodaySingles(tWork.id)
      var tSingle: BeitieSingle!
      if (history.size > 30) {
        history.clear()
      }
      while (true) {
        let next = Int.random(in: 0..<singles.size)
        let nextId = singles[next]
        if !history.containsItem(nextId) || singles.size < 40 {
          history.add(nextId)
          tSingle = BeitieDbHelper.shared.getSingleById(nextId)
          break
        }
      }
      DispatchQueue.main.async {
        self.todayWork = tWork
        self.todaySingle = tSingle
        self.lastTodaySingles = history
      }
    }
  }
  
  override init() {
    super.init()
    initToday()
  }
  
  var historyBinding: Binding<[SearchLog]> {
    Binding {
      self.logs
    } set: { _ in
      
    }
  }
  
  func updateHistoryBarVisible() {
    showHistoryBar = focused && logs.isNotEmpty()
  }
  
  func hideDropdown() {
    showOrder = false
    showFont = false
    showFastRedirect = false
  }
  
  func hasDropdown() -> Bool {
    showOrder || showFont || showFastRedirect
  }
  
  var logs: [SearchLog] {
    SearchViewModel.shared.getSearchLogs(page)
  }
}

extension Array where Element == BeitieSingle {
  
  func matchSearch() -> List<BeitieSingle> {
    let ok = filter { it in it.brokenLevel < 4 }
    let filtered = ok.filter { it in BeitieDbHelper.shared.searchWorks.contains(it.workId) }
    return if (!CurrentUser.userIsVip && (filtered.isEmpty() || Settings.showVipSingles)) {
      ok
    } else {
      filtered
    }
  }
  
  func matchJizi() -> List<BeitieSingle> {
    let filtered = filter { it in it.brokenLevel < 3 }
    return if (!CurrentUser.userIsVip && (filtered.isEmpty() || Settings.showVipSingles)) {
      filtered
    } else {
      filtered.filter { it in BeitieDbHelper.shared.jiziWorks.contains(it.workId) }
    }
  }
}

private extension String {
  func countString(_ size: Int) -> String {
    "\(self)(\(size))"
  }
}


extension OrderedDictionary {
  var entries: Elements {
    self.elements
  }
  
  func isEmpty() -> Bool {
    entries.isEmpty
  }
  
  func isNotEmpty() -> Bool {
    !isEmpty()
  }
  
  var size: Int {
    entries.count
  }
}

extension AnyHashable {
  func toString() -> String {
    "\(self)"
  }
}

extension Collection {
  func sumOf(mapper: @escaping (Element) -> Int) -> Int {
    var total = 0
    forEach { it in
      total += mapper(it)
    }
    return total
  }
}

extension Range where Element == Int {
  func toList() -> Array<Int> {
    var array = [Int]()
    for i in self {
      array.add(i)
    }
    return array
  }
}
