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
  
  var color: UIColor {
    switch self {
    case .Black:
        .black
    case .White:
        .white
    }
  }
  
  var opposite: UIColor {
    switch self {
    case .Black:
        .gray
    case .White:
        .black
    }
  }
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
  init(char: String, id: Int, thumbnailUrl: String, url: String) {
    self.char = char
    self.id = id
    self.thumbnailUrl = thumbnailUrl
    self.url = url
  }
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.char, forKey: .char)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.thumbnailUrl, forKey: .thumbnailUrl)
    try container.encode(self.url, forKey: .url)
  }
  
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.char = try container.decode(String.self, forKey: .char)
    self.id = try container.decode(Int.self, forKey: .id)
    self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
    self.url = try container.decode(String.self, forKey: .url)
  }

}

extension Char {
  var jiziCharUrl: URL? {
    JiziItem.getCharUrl(self)
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
  
  var charUrl: URL? {
    selected?.url.url ?? char.jiziCharUrl
  }
  
  static private let charDir: URL? = {
    let fileManager = FileManager.default
    guard let directory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL else {
      return nil
    }
    let dataDirUrl = directory.appendingPathComponent("chars")
    if !fileManager.fileExists(atPath: (dataDirUrl!.path)) {
      do {
        try fileManager.createDirectory(at: dataDirUrl!, withIntermediateDirectories: true, attributes: nil)
      } catch {
      }
    }
    return dataDirUrl
  }()
  
  static func getCharUrl(_ char: Char) -> URL? {
    if let url = charDir?.appendingPathComponent("\(char).png"), url.exists() {
      return url
    } else {
      return nil
    }
  }
  
  static func getCharImage(_ char: Char) -> UIImage {
    
    let size = CGSize(width: 80, height: 80)
    let renderer = UIGraphicsImageRenderer(size: size)
    let newImage = renderer.image { ctx in
      let context = UIGraphicsGetCurrentContext()!
      context.setFillColor(UIColor.black.cgColor)
      context.fill(CGRect(origin: .zero, size: size))
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      
      let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 50),
                   NSAttributedString.Key.paragraphStyle: paragraphStyle,
                   NSAttributedString.Key.foregroundColor: UIColor.white]
      
      let string = char.toString()
      let bound = string.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
      string.draw(with: CGRect(x: (size.width - bound.width)/2, y: (size.height - bound.height)/2, width: bound.width, height: bound.height), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
    }
    return newImage
  }
  
  static func generateCharBitmap(_ char: Char) {
    let url = charDir!.appendingPathComponent("\(char).png")
    if url.exists() {
      return
    }
    let newImage = getCharImage(char)
    
    try? newImage.pngData()?.write(to: url)
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
    if all.isEmpty {
      Self.generateCharBitmap(char)
    }
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
  
  func syncWithPuzzleItem(_ puzzle: PuzzleItem) {
    presetSelected = allResult.first(where: { $0.id == puzzle.id })
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
        for _ in 0..<items.size {
          resultWorkIndex[resultWorkIndex.size] = i
        }
      }
    } else {
      if (componentCandidates?.isNotEmpty() == true) {
        setJiziComponentCandidates()
      } else {
        candidates = nil
        selected = nil
        Self.generateCharBitmap(char)
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
  @Published var selectedWork: BeitieWork? = Settings.Jizi.lastPreferedWork {
    didSet {
      Settings.Jizi.lastPreferedWork = selectedWork
    }
  }
  @Published var selectedFont: CalligraphyFont? = Settings.Jizi.lastPreferredFont {
    didSet {
      Settings.Jizi.lastPreferredFont = selectedFont
    }
  }
  @Published var jiziItems: [JiziItem] = []
  @Published var jiziImageLoaded = [Int: Bool]()
  @Published var buttonEnabled = true
  @Published var selectedIndex = 0
  @Published var workIndex = 0
  @Published var singleIndex = 0
  @Published var singleStartIndex = 0
  var allFonts = OrderedDictionary<CalligraphyFont, Int>()
  var allWorks = OrderedDictionary<BeitieWork?, Int>()
  @Published var fontFilterType = JiziOptionType.Font.value {
    didSet {
      var font = JiziOptionType.Font
      font.value = fontFilterType
    }
  }
  
  @Published var workFilterType = JiziOptionType.Work.value {
    didSet {
      var font = JiziOptionType.Work
      font.value = workFilterType
    }
  }
  
  func selectFont(_ font: CalligraphyFont?) {
    selectedFont = font
    sync()
  }
  
  func selectWork(_ work: BeitieWork?) {
    selectedWork = work
    sync()
  }
  
  lazy var fontParam: DropDownParam<CalligraphyFont?> = {
    let total = allFonts.entries.sumOf { $0.value }
    var all = [CalligraphyFont?]()
    all.add(nil)
    all.addAll(Array(allFonts.keys))
    return DropDownParam(items: all, texts: all.map({ it in
      return if let it {
        "\(it.chinese)(\(allFonts[it] ?? 0))"
      } else {
        "全部(\(total))"
      }
    }))
  }()
  lazy var workParam: DropDownParam<BeitieWork?> = {
    let total = allWorks.entries.sumOf { $0.value }
    var all = [BeitieWork?]()
    all.add(nil)
    all.addAll(Array(allWorks.keys))
    return DropDownParam(items: all, texts: all.map({ it in
      return if let it {
        "\(it.chineseFolder())(\(allWorks[it] ?? 0))"
      } else {
        "全部(\(total))"
      }
    }))
  }()
  
  init(text: String, items: [JiziItem]) {
    self.text = text
    self.jiziItems = items
    var count = [CalligraphyFont: Int]()
    var workCount = [BeitieWork: Int]()
    items.forEach { item in
      item.allResult.forEach { single in
        workCount[single.work] = (workCount[single.work] ?? 0) + 1
        count[single.work.font] = (count[single.work.font] ?? 0) + 1
      }
    }
    super.init()
    for font in CalligraphyFont.allCases {
      guard let fontCount = count[font] else { continue }
      allFonts[font] = fontCount
    }
    
    for (_, v) in BeitieDbHelper.shared.getDefaultTypeWorks() {
      for works in v {
        for w in works {
          if workCount.containsKey(w) {
            allWorks[w] = workCount[w]!
          }
        }
      }
    }
    self.sync()
  }
  
  func sync() {
    self.jiziItems.forEach { $0.syncWithPreferences(selectedFont, nil, work: selectedWork) }
  }
  
  func loaded(index: Int) {
    DispatchQueue.main.async {
      self.jiziImageLoaded[index] = true
      self.buttonEnabled = self.jiziImageLoaded.values.sumOf(mapper: { $0 ? 1 : 0 }) == self.jiziItems.count
    }
  }
  
  var currentItem: JiziItem {
    jiziItems[selectedIndex]
  }
  
  func selectChar(_ index: Int) {
    selectedIndex = index
    singleIndex = currentItem.getSelectedIndex()
    workIndex = currentItem.getWorkIndex(singleIndex)
  }
  
  func resetLoaded(_ index: Int) {
    jiziImageLoaded[index] = false
    buttonEnabled = false
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
  
   
  static func search(text: String) -> [JiziItem] {
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
      newItems.add(jiziItem)
    }
    return newItems
  }
}
