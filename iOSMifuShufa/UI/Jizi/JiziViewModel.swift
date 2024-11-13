//
//  JiziViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/13.
//

import SwiftUI
import Foundation
import Collections


enum JiziPreferType: String, CaseIterable {
  case Prioritize, Filter
  
  var chinese: String {
    switch self {
    case .Prioritize: "优先".orCht("優先")
    case .Filter: "过滤".orCht("過濾")
    }
  }
}

enum JiziOptionType: String, CaseIterable {
  case Font, Author, Work;
  
  var chinese: String {
    switch self {
    case .Font: "字体".orCht("字體")
    case .Author: "书法家".orCht("書法家")
    case .Work: "碑帖"
    }
  }
  
  var icon: String {
    switch self {
    case .Font: "font"
    case .Author: "people"
    case .Work: "work"
    }
  }
  
  var value: JiziPreferType {
    get {
      JiziPreferType(rawValue: Settings.getString(settingKey, JiziPreferType.Prioritize.rawValue))!
    }
    set {
      Settings.putString(settingKey, newValue.rawValue)
    }
  }
}


extension JiziOptionType {
  
  private var settingKey: String {
    "jizi\(rawValue)"
  }

  var settingValue: JiziPreferType {
    get {
      JiziPreferType(rawValue: Settings.getString(settingKey, JiziPreferType.Prioritize.rawValue)) ?? .Prioritize
    }
    set {
      Settings.putString(settingKey, newValue.rawValue)
    }
  }
}

enum JiziBgColor: String, CaseIterable {
  case Black, White;
  
}

struct PuzzleItem: Codable {
  var char: String = " "
  var id: Int = 0
  var thumbnailUrl: String = ""
  var url: String = ""
  
  enum CodingKeys: CodingKey {
    case char
    case id
    case thumbnailUrl
    case url
  }
  
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.char = try container.decode(String.self, forKey: .char)
    self.id = try container.decode(Int.self, forKey: .id)
    self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
    self.url = try container.decode(String.self, forKey: .url)
  }

}


class JiziItem: BaseObservableObject {
  let char: Char
  var imageLoaded: Bool = false
  var componentCandidates: OrderedDictionary<AnyHashable, List<BeitieSingle>>? = nil
  let allResult: [BeitieSingle]
  var presetSelected: BeitieSingle? = nil
  @Published var works: List<AnyHashable>? = nil
  @Published var results: List<BeitieSingle>? = nil
  @Published var resultWorkIndex = [Int: Int]()
  @Published var selected: BeitieSingle? = nil
  @Published var candidates: OrderedDictionary<AnyHashable, List<BeitieSingle>>? = nil
  
  func getWorkStartIndex(_ workIndex: Int) -> Int {
    for (k, v) in resultWorkIndex {
      if v == workIndex {
        return k
      }
    }
    return 0
  }
  
  func getWorkIndex(_ singleIndex: Int) -> Int {
    resultWorkIndex[singleIndex] ?? 0
  }
  
  func getSelectedIndex() -> Int {
    if let selected = selected {
      return max(results?.indexOf(selected) ?? 0, 0)
    } else {
      return 0
    }
  }
  
  
  init(char: Char, ziResult: List<BeitieSingle>,
       componentCandidates: OrderedDictionary<AnyHashable, List<BeitieSingle>>? = nil) {
    self.char = char
    self.componentCandidates = componentCandidates
    var all = [BeitieSingle]()
    if ziResult.isEmpty {
      componentCandidates?.values.forEach {
        all.addAll($0)
      }
    } else {
      all.addAll(ziResult)
    }
    allResult = all
    super.init()
  }
  
  var jiziUseComponents: Bool {
    componentCandidates != nil
  }
  
  func setJiziComponentCandidates() {
    candidates = componentCandidates!
    selected = componentCandidates!.values.first!.first()
    var orderedResult = ArrayList<BeitieSingle>()
    componentCandidates!.values.forEach { list in
      orderedResult.addAll(list)
    }
    results = orderedResult
  }
  
  func syncWithPreferences(_ font: CalligraphyFont?,
                          _ author: Calligrapher?, work: BeitieWork?) {
    if (jiziUseComponents) {
      setJiziComponentCandidates()
      return
    }
    results = applyPreferred(font, author, work)
    if (results?.isNotEmpty() == true) {
      let ordered = results!.order()
      var orderedResult = Array<BeitieSingle>()
      ordered.values.forEach { list in
        orderedResult.addAll(list)
      }
      let defaultSelected = ordered.entries.first?.value.first()
      if let ps = presetSelected {
        if (ordered.entries.map { it in it.value }.hasAny { it in it.hasAny { $0.id == ps.id }} ) {
          selected = ps
        } else {
          selected = defaultSelected
        }
        presetSelected = nil
      } else {
        selected = defaultSelected
      }
      results = orderedResult
      candidates = ordered
      resultWorkIndex.clear()
      let elements = ordered.elements
      for i in 0..<elements.count {
        let items = elements[i].value
        for j in 0..<items.size {
          resultWorkIndex[resultWorkIndex.size] = i
        }
      }
    } else {
      if (componentCandidates?.isNotEmpty() == true) {
        setJiziComponentCandidates()
      } else {
        candidates = nil
        selected = nil
      }
    }
  }
  
  private func applyPreferred(_ font: CalligraphyFont?,
                             _ author: Calligrapher?, _ work: BeitieWork?) -> List<BeitieSingle>? {
    allResult.let { list in
      if (font != nil) {
        if (JiziOptionType.Font.value == JiziPreferType.Filter) {
          return list.filter { it in it.work.font == font }
        } else {
          return list.sortedByDescending { it in it.work.font == font }
        }
      } else {
        return list
      }
    }.let { list in
      if let author = author {
        return if (JiziOptionType.Author.value == JiziPreferType.Filter) {
          list.filter { it in it.work.from(author) }
        } else {
          list.sortedByDescending { it in it.work.from(author) }
        }
      } else {
        return list
      }
    }.let { list in
      if let work = work {
        if (JiziOptionType.Work.value == JiziPreferType.Filter) {
          list.filter { it in it.work.id == work.id }
        } else {
          list.sortedByDescending { it in it.work.id == work.id }
        }
      } else {
        list
      }
    }.sortedByDescending { it in it.work.matchVip }.ifEmpty {
      return nil
    }
  }
}



extension BeitieWork {
  func from(_ author: Calligrapher) -> Bool {
    self.author == author.name
  }
}

extension Array where Element : Equatable {
  func distinct() -> Array {
    var distinct = [Element]()
    for e in self {
      if !distinct.containsItem(e) {
        distinct.add(e)
      }
    }
    return distinct
  }
}

extension Array where Element == BeitieSingle {
  func order() -> OrderedDictionary<AnyHashable, List<BeitieSingle>> {
    var map = LinkedHashMap<AnyHashable, List<BeitieSingle>>()
    let works = self.map { it in it.work }.distinct()
    works.forEach { w in
      let key = w.folder
      let value = self.filter { it in it.workId == w.id }
      map[key] = value
    }
    return map
  }
}


class JiziViewModel: AlertViewModel {
  let text: String
  @Published var selectedWork: BeitieWork? = nil
  @Published var selectedFont: CalligraphyFont? = nil
  @Published var jiziItems: [JiziItem] = []
  @Published var buttonEnabled = true
  @Published var selectedIndex = 0
  @Published var workIndex = 0
  @Published var singleIndex = 0
  @Published var singleStartIndex = 0
  
  init(text: String) {
    self.text = text
  }
  
  var currentItem: JiziItem {
    jiziItems[selectedIndex]
  }
  
  func selectChar(_ index: Int) {
    selectedIndex = index
    singleIndex = currentItem.getSelectedIndex()
    workIndex = currentItem.getWorkIndex(singleIndex)
  }
  
  
  func selectWork(_ index: Int) {
    workIndex = index
    singleStartIndex = currentItem.getWorkStartIndex(index)
  }
  
  func selectSingle(_ index: Int, _ single: BeitieSingle) {
    currentItem.selected = single
    singleIndex = index
    workIndex = currentItem.getWorkIndex(index)
  }
  
  private func doSearch(_ text: String, after: @escaping () -> Void) {
    
    Task {
      let chars = text.filter { it in it.charIsChinesChar() }.toCharList
      var newItems = [JiziItem]()
      
      var orderWorks = HashMap<Int, Int>()
      BeitieDbHelper.shared.getOrderTypeWorks(BeitieOrderType.orderType, false).elements.forEach { it in
        for work in it.value.map({ w in w.first() }) {
          orderWorks[work.id] = orderWorks.size
        }
      }
      chars.forEach { it in
        let result = BeitieDbHelper.shared.search(it).matchJizi()
          .sortedBy { s in orderWorks[s.workId]! }
        
        let jiziItem = {
          if (result.isNotEmpty() || !SettingsItem.jiziCandidateEnable) {
            return JiziItem(char: it, ziResult: result)
          } else {
            return JiziItem(char: it, ziResult: result, componentCandidates: nil)
          }
        }()
        jiziItem.syncWithPreferences(selectedFont, nil, work: selectedWork)
        newItems.add(jiziItem)
      }
      DispatchQueue.main.async {
        self.jiziItems = newItems
        after()
      }
    }
  }
  
  func onSearch(after: @escaping () -> Void) {
    doSearch(text, after: after)
  }
}
