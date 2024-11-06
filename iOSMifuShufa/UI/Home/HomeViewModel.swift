//
//  HomeViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import Collections
import SwiftUI

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



class HomeViewModel : AlertViewModel {
  @Published var filterViewModel = FilterViewModel()
  @Published var searchCharType = SearchCharType.Char
  @Published var text = ""
  @Published var focused = false
  @Published var showHistoryBar = false
  @Published var showDeleteAlert: Bool = false
  private let page = SearchPage.Search
  @Published var searchResults = [Any]()
  
  @Published var preferredFont: CalligraphyFont? = nil
  @Published var resultFonts: [CalligraphyFont] = []
  @Published var singleResult = OrderedDictionary<AnyHashable, List<BeitieSingle>>()
  @Published var allCollapse = false
  @Published var fastResultKeys = -1
  @Published var fontResultKeys = OrderedDictionary<CalligraphyFont?, String>()
  @Published var originalResult = OrderedDictionary<AnyHashable, List<BeitieSingle>>()
  
  @Published var todaySingle: BeitieSingle!
  @Published var todayWork: BeitieWork!
  
  private let todaySingleKey = "todaySingle"
  private var lastTodaySingles: List<Int> {
    get { Settings.getString(todaySingleKey, "").toInts() }
    set {
      Settings.putString(todaySingleKey, newValue.toSettingString())
    }
  }
  
  func onSearch(_ searchText: String) {
    
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
  
  var logs: [SearchLog] {
    SearchViewModel.shared.getSearchLogs(page)
  }
}
