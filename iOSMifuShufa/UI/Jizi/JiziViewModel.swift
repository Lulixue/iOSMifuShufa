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
    self.printCharUrl
  }
}

extension BeitieSingle {
  
  var charUrl: URL? {
    let selected = self
    if selected.isPrintChar {
      return selected.printChar.printCharUrl
    } else {
      if let orgUrl = selected.orgUrl {
        if orgUrl.contains("/var") {
          return selected.printChar.printCharUrl
        }
      }
      let url = selected.orgUrl?.fileHttpUrl ?? selected.url.url
      return url
    }
  }
  
  var charThumbnailUrlPath: String {
    isPrintChar ? charUrl!.path() : thumbnailUrl
  }
  
  var charUrlPath: String {
    isPrintChar ? charUrl!.path() : self.url
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
  @Published var resultWorkIndex = [(Int, Int)]()
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
    if singleIndex < resultWorkIndex.count {
      resultWorkIndex[singleIndex].1
    } else {
      0
    }
  }
  
  func getSelectedIndex() -> Int {
    if let selected = selected {
      return max(results?.indexOf(selected) ?? 0, 0)
    } else {
      return 0
    }
  }
  
  
  var charUrl: URL? {
    selected?.charUrl ?? char.jiziCharUrl
  }
  
  
  static func getCharImage(_ char: Char) -> UIImage {
    
    let size = CGSize(width: 80, height: 80)
    let renderer = UIGraphicsImageRenderer(size: size)
    let newImage = renderer.image { ctx in
      let context = UIGraphicsGetCurrentContext()!
      context.setFillColor(Colors.bitmapBg.cgColor)
      context.fill(CGRect(origin: .zero, size: size))
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      
      let attrs = [NSAttributedString.Key.font: UIFont.getPrintFont(50 + BeitieDbHelper.shared.PRINT_CHAR_OFFSET)!,
                   NSAttributedString.Key.paragraphStyle: paragraphStyle,
                   NSAttributedString.Key.foregroundColor: UIColor.white]
      
      let string = char.toString()
      let bound = string.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
      string.draw(with: CGRect(x: (size.width - bound.width)/2, y: (size.height - bound.height)/2, width: bound.width, height: bound.height), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
    }
    return newImage
  }
  
  static func generateCharBitmap(_ char: Char) {
    let url = char.printCharUrl
    if url.exists() {
      return
    }
    debugPrint("generate char bitmap", char)
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
    initResultWorkIndex()
  }
  
  func syncWithPuzzleItem(_ puzzle: PuzzleItem) {
    presetSelected = allResult.first(where: { $0.id == puzzle.id })
  }
  
  private func initResultWorkIndex() {
    resultWorkIndex.clear()
    guard let ordered = candidates else { return }
    let elements = ordered.elements
    for i in 0..<elements.count {
      let items = elements[i].value
      for _ in 0..<items.size {
        resultWorkIndex.add((resultWorkIndex.size, i))
      }
    }
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
      initResultWorkIndex()
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
    let history = allResult.filter { $0.workId == PreviewHelper.RECENT_WORK_ID }
    let anotherResults = allResult.filter { $0.workId != PreviewHelper.RECENT_WORK_ID }
    let result = anotherResults.let { list in
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
    }.sortedByDescending { it in it.work.matchVip }
    var all = [BeitieSingle]()
    all.addAll(history)
    all.addAll(result)
    return all.ifEmpty {
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
  
  private var newLog: Bool = false
  
  init(text: String, items: [JiziItem]) {
    self.text = text
    self.newLog = items.isEmpty()
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
  
   
  static func search(text: String, newLog: Bool = true) -> [JiziItem] {
    let chars = text.filter { it in it.charIsChinesChar() }.toCharList
    var newItems = [JiziItem]()
    
    let orderWorks = BeitieDbHelper.shared.orderedWork
    chars.forEach { it in
      let result = BeitieDbHelper.shared.search(it).matchJizi()
        .sortedBy { s in orderWorks[s.workId]! }
      let history = newLog ? JiziHistoryHelper.shared.searchChar(it).map { $0.toSingle() } : []
      let jiziItem = {
        if (result.isNotEmpty() || !SettingsItem.jiziCandidateEnable) {
          var all = ArrayList<BeitieSingle>()
          if (history.isNotEmpty()) {
            all.addAll(history)
          }
          if (result.count(where: { $0.work.matchVip }) < 1) {
            all.addAll(ChineseConverter.getPrintChars(it, BeitieDbHelper.shared.FONT_CHS_FIRST).map({ $0.printCharSingle() }))
          }
          all.addAll(result)
          return JiziItem(char: it, ziResult: all)
        } else {
          let cht = ChineseConverter.getCht(it)
          var allComponents = "\(it)\(cht)"
          for i in Array.arrayOf(cht, it).distinct() {
            allComponents += ChineseDbHelper.dao.getChineseChar(i.utf8Code)?.mainComponents ?? ""
          }
          var map = LinkedHashMap<AnyHashable, List<BeitieSingle>>()
          if (history.isNotEmpty()) {
            map[PreviewHelper.recentWork.chineseName()] = history
          }
          map[PreviewHelper.defaultWork.chineseName()] = ChineseConverter.getPrintChars(it, BeitieDbHelper.shared.FONT_CHS_FIRST).map({ $0.printCharSingle() })
          for c in allComponents.toCharList.distinct() {
            let singles = BeitieDbHelper.shared.getSinglesByComponent(char: c).matchJizi()
            if (singles.isNotEmpty()) {
              let resultSingles = singles.sample(size: 50)!
              map["部件「\(c)」"] = resultSingles.sortedBy { s in orderWorks[s.workId] ?? 0 }
            }
          }
          return JiziItem(char: it, ziResult: result, componentCandidates: map.isEmpty ? nil : map)
        }
      }()
      newItems.add(jiziItem)
    }
    return newItems
  }
}

extension String {
  var sqlLike: String {
    "%\(this)%"
  }
}

extension Array {
  
  /// 从数组中返回一个随机元素
  public var sample: Element? {
    //如果数组为空，则返回nil
    guard count > 0 else { return nil }
    let randomIndex = Int(arc4random_uniform(UInt32(count)))
    return self[randomIndex]
  }
  
  /// 从数组中从返回指定个数的元素
  ///
  /// - Parameters:
  ///   - size: 希望返回的元素个数
  ///   - noRepeat: 返回的元素是否不可以重复（默认为false，可以重复）
  public func sample(size: Int, noRepeat: Bool = false) -> [Element]? {
    //如果数组为空，则返回nil
    guard !isEmpty else { return nil }
    
    if self.count < size {
      return self
    }
    var sampleElements: [Element] = []
    
    //返回的元素可以重复的情况
    if !noRepeat {
      for _ in 0..<size {
        sampleElements.append(sample!)
      }
    }
    //返回的元素不可以重复的情况
    else{
      //先复制一个新数组
      var copy = self.map { $0 }
      for _ in 0..<size {
        //当元素不能重复时，最多只能返回原数组个数的元素
        if copy.isEmpty { break }
        let randomIndex = Int(arc4random_uniform(UInt32(copy.count)))
        let element = copy[randomIndex]
        sampleElements.append(element)
        //每取出一个元素则将其从复制出来的新数组中移除
        copy.remove(at: randomIndex)
      }
    }
    
    return sampleElements
  }
}


extension Char {
  
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
  
  var printCharUrl: URL {
    Self.charDir!.appendingPathComponent("new_\(self).png")
  }
  
  func printCharSingle() -> BeitieSingle {
    let c = self
    JiziItem.generateCharBitmap(c)
    let single = PreviewHelper.printSingle
    single.chars = c.toString()
    return single
  }
}

extension BeitieSingle {
  var isPrintChar: Boolean { self.workId == PreviewHelper.DEFAULT_WORK_ID }
  var printChar: Char { chars.first() }
  
  var jiziUrl: URL? {
    if isPrintChar {
      return printChar.jiziCharUrl
    } else {
      if let orgThumb = orgThumbnailUrl {
        if orgThumb.contains("/var") {
          return printChar.jiziCharUrl
        }
      }
      let url = orgThumbnailUrl?.fileHttpUrl ?? thumbnailUrl.url
      return url
    }
  }
  
}

class PreviewHelper {
  
  static func toCustomWork(_ id: Int) -> BeitieWork {
    switch id {
    case RECENT_WORK_ID:
      return recentWork
    default:
      return defaultWork
    }
  }
  
  static let RECENT_WORK_ID = 123510
  static let DEFAULT_WORK_ID = 123511
  static let recentWork: BeitieWork = {
       let json = """
  {"articleAuthor":"","authenticity":"Unknown","author":"","authorCht":"","ceYear":0,"coverUrl":"","detailDynasty":"","detailFont":"","dynasty":"Unknown","folder":"最近使用","font":"Others","id":\(RECENT_WORK_ID),"imageCount":1,"intro":"","introCht":"","name":"最近使用","nameCht":"最近使用","primary":false,"shortName":"","shuType":"Short","singleCount":52,"text":"","textCht":"","type":"Unknown","urlPrefix":"","version":"","versionCht":"","vip":false,"year":"","yearCht":""}
  """
      return try! JSONDecoder().decode(BeitieWork.self, from: json.utf8Data)
  }()
  
  static var printSingle: BeitieSingle {
      let json = """
     {"brokenLevel":0,"chars":"王","fileName":"","font":"Others","id":0,"imageId":0,"imageName":"","index":0,"lian":false,"path":"","repeat":false,"strokeCount":0,"workId":\(DEFAULT_WORK_ID)}
     """
    return try! JSONDecoder().decode(BeitieSingle.self, from: json.utf8Data)
  }
  
  static let defaultWork: BeitieWork = {
     let json = """
{"articleAuthor":"","authenticity":"Unknown","author":"","authorCht":"","ceYear":0,"coverUrl":"","detailDynasty":"","detailFont":"","dynasty":"Unknown","folder":"印刷体","font":"Others","id":\(DEFAULT_WORK_ID),"imageCount":1,"intro":"","introCht":"","name":"印刷体","nameCht":"印刷體","primary":false,"shortName":"","shuType":"Short","singleCount":52,"text":"","textCht":"","type":"Unknown","urlPrefix":"","version":"","versionCht":"","vip":false,"year":"","yearCht":""}
"""
    return try! JSONDecoder().decode(BeitieWork.self, from: json.utf8Data)
  }()
}
