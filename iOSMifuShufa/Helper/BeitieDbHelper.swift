//
//  BeitieDbHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/3.
//
import SQLite
import Collections

let STORAGE_DIR = "mifu"
let APP_ID = "6520390752"
let CSJ_AD_ID = "5624945"
let CSJ_SPLASH_AD_ID = "890222718"
var ABOUT_TEXT: String {
  "米芾书法字典属于立人书法系列，字典收集了米芾的经典书法作品，希望对米芾书法爱好者学习、研究米芾书法有所帮助。<br /><br /><small>卢立雪<br />2024年7月3日</small>"
    .orCht("米芾書法字典屬於立人書法系列，字典收集了米芾的經典書法作品，希望對米芾書法愛好者學習、研究米芾書法有所幫助。<br /><br /><small>盧立雪<br />2024年7月3日</small>")
}

enum WorkTime: String, CaseIterable{
  case Early
  case Middle
  case Late
  case Unknown
  
  var chinese:String {
    switch self {
    case .Early: "早期"
    case .Middle: "中期"
    case .Late: "晚期"
    case .Unknown: "未知"
    }
  }
  
  var start: Int {
    switch self {
    case .Early: 1050
    case .Middle: 1091
    case .Late: 1101
    case .Unknown: 0
    }
  }
  
  var end: Int {
    switch self {
    case .Early: 1090
    case .Middle: 1100
    case .Late: 1199
    case .Unknown: 0
    }
  }
}

enum WorkCategory: String, CaseIterable {
  case Boutique
  case Handu
  case MojiXuan
  case Sanzha
  case Canshu
  case Normal
  case Beikei
  case Linben
  case Reference
  case Hua
  case Miyouren
  case Ba
  case Collection
  
  var chinese: String {
    switch self {
    case .Miyouren:
      "米友仁"
    case .Ba:
      "米芾题跋".orCht("米芾題跋")
    case .Boutique:
      "精品"
    case .Handu:
      "翰牍九帖".orCht("翰牘九帖")
    case .MojiXuan:
      "米芾墨迹选".orCht("米芾墨蹟選")
    case .Sanzha:
      "行书三札".orCht("行書三札")
    case .Canshu:
      "草书九帖".orCht("草書九帖")
    case .Normal:
      "法帖"
    case .Beikei:
      "刻帖"
    case .Linben:
      "疑米芾临本".orCht("疑米芾臨本")
    case .Reference:
      "参考".orCht("參考")
    case .Hua:
      "绘画".orCht("繪畫")
    case .Collection:
      "长卷".orCht("長卷")
    }
  }
  
  static let TIBA = "褚遂良摹兰亭序跋赞、破羌帖跋赞、跋蔡襄赐御书诗卷、跋集古录跋、跋步辇图".split(separator: "、")
  static let HANDU_NINE = "来戏帖、伯修帖、晋纸帖、适意帖、贺铸帖、丹阳帖、业镜帖、惠柑帖、戏成诗帖".split(separator: "、")
  static let MOJI_XUAN = "三吴诗帖、伯充帖、彦和帖、乡石帖、岁丰帖、闻张都大宣德帖、论书帖、值雨帖、清和帖、临沂使君帖".split(separator: "、")
  static let SANZHA_SAN = "长至帖、韩马帖、新恩帖".split(separator: "、")
  static let LINBEN_SAN = Array.listOf("湖州帖", "大道帖", "中秋帖")
  static let CANSHU_NINE = "葛君德忱帖、家计帖、元日帖、吾友帖、论草书帖、中秋登海岱楼作诗帖、目穷帖、奉议帖、焚香帖".split(separator: "、")
}

extension AnySequence {
  var first: Element? {
    return Array(self).first
  }
}

extension String {
  var stringExp: Expression<String> {
    Expression<String>(self)
  }
  
  var intExp: Expression<Int> {
    Expression<Int>(self)
  }
  
  var boolExp: Expression<Bool> {
    Expression<Bool>(self)
  }
}

let AZ_INITS = {
  var azs = [Char]()
  let startingValue = Int(("A" as UnicodeScalar).value) // 65
  for i in 0 ..< 26 {
    let c = (Character(UnicodeScalar(i + startingValue)!))
    azs.append(c)
  }
  return azs
}()

class BeitieDbHelper {
  static let shared = BeitieDbHelper()
  let CALLIGRAPHER = "米芾"
  let DB_NAME = "beitie.db"
  let FONT_FILE = "mifu.ttf"
  let FONT_FAMILY = "书体坊米芾体"
  let FONT_CHS_FIRST = true
  let PRINT_CHAR_OFFSET: CGFloat = 10
  let SINGLE_HAS_ORIGINAL = true
  let SUPPORT_ORDER_TYPES = BeitieOrderType.entries
  
  var searchWorks = ArrayList<Int>()
  var jiziWorks = ArrayList<Int>()
  
  init() {
    syncWorkRanges()
  }
  
  static func getWorkByFolder(_ folder: String) -> BeitieWork? {
    shared.works.first { $0.folder == folder }
  }
  
  func getTodaySingles(_ id: Int) -> List<Int> {
    var result = [Int]()
    do {
      let rows = try db.prepare(singleTable.filter(workIdExp == id).select([idExp]))
      for row in rows {
        result.append(try! row.get(idExp))
      }
    } catch {
      println("getTodaySingles \(error)")
    }
    return result
  }
  
//  @Query("select * from BeitieImage where id = :id")
  func getImageById(_ id: Int) -> BeitieImage? {
    guard let row = try? db.prepare(imageTable.filter(idExp == id)).first else { return nil }
    return try? BeitieImage(from: row.decoder())
  }
  
  func getMatchKeywordImages(_ keyword: String) -> List<BeitieImage> {
    let textEpr = Expression<String>("text")
    let textChtEpr = Expression<String>("textCht")
    do {
      guard let rows = try? db.prepare(imageTable.filter(textEpr.like(keyword) || textChtEpr.like(keyword))) else { return [] }
      return try rows.map { try BeitieImage(from: $0.decoder()) }
    } catch {
      return []
    }
  }

  func getSingleById(_ id: Int) -> BeitieSingle? {
    guard let row = try? db.prepare(singleTable.filter(idExp == id)).first else { return nil }
    return try? BeitieSingle(from: row.decoder())
  }
  
  private lazy var databaseFile: URL = {
    let dbUrl = ResourceHelper.dataDir?.appendingPathComponent(self.DB_NAME)
    if dbUrl?.path.contains("Preview") == true {
      return Bundle.main.url(forResource: "beitie", withExtension:"db")!
    }
    return dbUrl!
  }()
  
  lazy var db: Connection = {
    do {
      let connection = try Connection(self.databaseFile.path)
      return connection
    } catch {
      fatalError("error")
    }
  }()
  
  private let workTable = Table("BeitieWork")
  private let imageTable = Table("BeitieImage")
  private let singleTable = Table("BeitieSingle")
  private let workIdExp = Expression<Int>("workId")
  private let idExp = Expression<Int>("id")
  
  func dao() -> BeitieDbHelper {
    self
  }
  
  func getWorkImages(_ id: Int) -> List<BeitieImage> {
    var result = [BeitieImage]()
    do {
      let rows = try db.prepare(imageTable.filter(workIdExp == id))
      for row in rows {
        result.append(try BeitieImage(from: row.decoder()))
      }
    } catch {
      println("getWorkImages \(error)")
    }
    return result
  }
  
  
//  @Query("select * from BeitieSingle where imageId = :imageId")
  func getSinglesByImageId(_ id: Int) -> List<BeitieSingle> {
    var result = [BeitieSingle]()
    do {
      let exp = "imageId".intExp
      let rows = try db.prepare(singleTable.filter(exp == id))
      for row in rows {
        result.append(try BeitieSingle(from: row.decoder()))
      }
    } catch {
      println("getSinglesByImageId \(error)")
    }
    return result.sortedBy {
      $0.index
    }
  }
  
  func getAllWorks() -> List<BeitieWork> {
    var result = [BeitieWork]()
    do {
      let rows = try db.prepare(workTable)
      for row in rows {
        result.append(try BeitieWork(from: row.decoder()))
      }
    } catch {
      println("getAllWorks \(error)")
    }
    return result
  }
  
  lazy var works: List<BeitieWork> = {
    dao().getAllWorks()
  }()
  
  func syncWorkRanges() {
    let singleWorks = works.filter { it in it.hasSingle()}
    searchWorks.clear()
    jiziWorks.clear()
    searchWorks.addAll(singleWorks.filter { it in it.canSearch }.map { it in it.id })
    jiziWorks.addAll(singleWorks.filter { it in it.canJizi }.map { it in it.id })
  }
  
  private lazy var azWorks = {
    var azAll = LinkedHashMap<AnyHashable, List<List<BeitieWork>>>()
    var left = List(works)
    for az in AZ_INITS {
      guard var zis = BeitieOrderType.azMap[az] else { continue }
      let works = left.filter { it in
        zis.contains(it.name.first())
      }
      if (works.isNotEmpty()) {
        azAll[az.toString()] = works.map { it in Array.listOf(it) }
        left.removeAll { works.contains($0) }
      }
    }
    if (left.isNotEmpty()) {
      azAll[UNKNOWN] = left.map { it in Array.listOf(it) }
    }
    return azAll
  }()
  
  private lazy var azWorksStack = {
    return toStack(ordered: azWorks)
  }()
  
  func getDefaultTypeWorks(_ stack: Boolean = true) -> OrderedDictionary<AnyHashable, List<List<BeitieWork>>> {
    return getOrderTypeWorks(BeitieOrderType.orderType, stack)
  }
  private lazy var worksByType = {
    var ordered = LinkedHashMap<AnyHashable, List<List<BeitieWork>>>()
    CalligraphyType.allCases.forEach { type in
      let w = works.filter { it in it.type == type }
      if (w.isNotEmpty()) {
        ordered[type.typeChinese] = w.sortedByDescending { it in it.isTrue() }.map { it in Array.listOf(it) }
      }
    }
    return ordered
  }()
  
  private lazy var worksByTypeStack = {
    toStack(ordered: worksByType)
  }()
  private lazy var worksByFontStack = {
    toStack(ordered: worksByFont)
  }()
  private lazy var worksByFont = {
    var ordered = LinkedHashMap<AnyHashable, List<List<BeitieWork>>>()
    CalligraphyFont.allCases.forEach { font in
      let w = works.filter { it in it.font == font }
      if (w.isNotEmpty()) {
        ordered[font.longChinese] = w.sortedByDescending { it in it.isTrue() }.map { it in Array.listOf(it) }
      }
    }
    return ordered
  }()
  
  private lazy var worksByTimeDescStack = {
    toStack(ordered: worksByTimeDesc)
  }()
  
  private lazy var worksByTimeDesc = {
    var ordered = LinkedHashMap<AnyHashable, List<List<BeitieWork>>>()
    
    Array.arrayOf(WorkTime.Late, WorkTime.Middle, WorkTime.Early, WorkTime.Unknown).map({ $0.chinese }).forEach { it in
      if let value = worksByTimeAsc[it] {
        if (it == WorkTime.Unknown.chinese) {
          ordered[it] = value
        } else {
          ordered[it] = value.reversed()
        }
      }
    }
    return ordered
  }()
  
  private lazy var worksByTimeAsc = {
    var ordered = LinkedHashMap<AnyHashable, List<List<BeitieWork>>>()
    WorkTime.allCases.forEach { it in
      let result = if (it == WorkTime.Unknown) {
        works.filter { w in w.ceYear == 0 }.sortedByDescending { it in it.isTrue() }.map { w in Array.listOf(w) }
      } else {
        works.filter { w in w.ceYear >= it.start && w.ceYear <= it.end }
          .sortedBy { w in w.ceYear }.sortedByDescending { it in it.isTrue() }.map { w in Array.listOf(w) }
      }
      if result.isNotEmpty() {
        ordered[it.chinese] = result
      }
    }
    return ordered
  }()
  
  private lazy var worksByTImeAscStack = {
    toStack(ordered: worksByTimeAsc)
  }()

  typealias BeitieDictionary = OrderedDictionary<AnyHashable, List<List<BeitieWork>>>
  func getOrderTypeWorks(_ orderType: BeitieOrderType, _ stack: Boolean = true) -> OrderedDictionary<AnyHashable, List<List<BeitieWork>>> {
    let result = switch orderType {
    case .Default:
      stack ? defaultWorksStack : defaultWorks
    case .Az:
      stack ? azWorksStack : azWorks
    case .Type:
      stack ? worksByTypeStack : worksByType
    case .Font:
      stack ? worksByFontStack : worksByFont
    case .TimeAsc:
      stack ? worksByTImeAscStack : worksByTimeAsc
    case .TimeDesc:
      stack ? worksByTimeDescStack: worksByTimeDesc
    }
    
    return result
  }
  private func toStack(ordered: BeitieDictionary) -> BeitieDictionary {
    var result = BeitieDictionary()
    var left = ArrayList(works)
    ordered.forEach { (key, value) in
      let items = ArrayList(value).map { w in
        let name = w.first().name
        return left.filter { $0.name == name }.apply { it in left.removeAll { it.containsItem($0) } }
      }.filter { it in it.isNotEmpty() }
      if (items.isNotEmpty()) {
        result[key] = items
      }
    }
    return result
  }
  
  private lazy var defaultWorksStack = {
    return toStack(ordered: defaultWorks)
  }()
  
  private lazy var defaultWorks = {
    var ordered = BeitieDictionary()
    var left = ArrayList(works)
    
    let huas = left.filter { it in it.type == CalligraphyType.Hua }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    let fake = left.filter { it in !it.isTrue() }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    let linbens = left.filter { it in WorkCategory.LINBEN_SAN.contains(it.name) }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    
    let beis = left.filter { it in it.type == CalligraphyType.Bei }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    ordered[WorkCategory.Boutique] = left.filter { it in it.primary && it.hasSingle() }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    ordered[WorkCategory.MojiXuan] = WorkCategory.MOJI_XUAN.filter({ it in left.contains { $0.name == it } }).map { name in
      left.first { it in it.name == name }!
    }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    ordered[WorkCategory.Handu] = WorkCategory.HANDU_NINE.filter({ it in left.contains { $0.name == it } }).map { name in      left.first { it in it.name == name }!
    }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    
    ordered[WorkCategory.Sanzha] = WorkCategory.SANZHA_SAN.filter({ it in left.contains { $0.name == it } }).map { name in      left.first { it in it.name == name }!
    }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    ordered[WorkCategory.Canshu] = WorkCategory.CANSHU_NINE.filter({ it in left.contains { $0.name == it } }).map { name in      left.first { it in it.name == name }!
    }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    let myr = left.filter { it in it.author == "米友仁" }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    let bas =  WorkCategory.TIBA.filter({ it in left.contains { $0.name == it } }).map { name in left.first { it in it.name == name }!
    }.apply { it in
      left.removeAll { it.containsItem($0) }
    }.map({ Array.listOf($0)})
    
    ordered[WorkCategory.Normal] = left.filter { it in !it.primary && it.hasSingle() }
      .apply { it in
        left.removeAll { it.containsItem($0) }
      }.map({ Array.listOf($0)})
    
    ordered[WorkCategory.Beikei] = beis
    
    
    ordered[WorkCategory.Ba] = bas
    ordered[WorkCategory.Miyouren] = myr
    ordered[WorkCategory.Collection] = left.map { it in Array.listOf(it) }
    ordered[WorkCategory.Linben] = linbens
    ordered[WorkCategory.Reference] = fake
    ordered[WorkCategory.Hua] = huas
    return ordered
  }()
  
  
  private lazy var worksMap = {
    var map = [Int: BeitieWork]()
    works.forEach { w in
      map[w.id] = w
    }
    return map
  }()
  
  
  func getWorkById(_ id: Int) -> BeitieWork? {
    return worksMap[id]
  }
  
//  @Query("select * from BeitieSingle where chars like :cLike " +
//         "or radical like :cLike " +
//         "or components like :cLike " +
//         "or mainComponents like :cLike limit :lmt")
  func getSinglesByComponent(char: Char, lmt: Int = 10000) -> List<BeitieSingle> {
    var result = [BeitieSingle]()
    do {
      let cLike = "%\(char)%"
      let charsExp = "chars".stringExp
      let radicalExp = "radical".stringExp
      let componentsExp = "components".stringExp
      let mainCExp = "mainComponents".stringExp
      let rows = try db.prepare(singleTable.filter(charsExp.like(cLike) || radicalExp.like(cLike) ||
                                                   componentsExp.like(cLike) || mainCExp.like(cLike)).limit(lmt))
      for row in rows {
        result.append(try BeitieSingle(from: row.decoder()))
      }
    } catch {
      println("error \(error)")
    }
    return result
  }

  
//  @Query("select * from BeitieSingle where strokes like '%' || :stroke || '%'")
  func getSinglesByStroke(_ stroke: String) -> List<BeitieSingle> {
    var result = [BeitieSingle]()
    do {
      let rows = try db.prepare(singleTable.filter(Expression<String>("strokes").like("%\(stroke)%")))
      for row in rows {
        result.append(try BeitieSingle(from: row.decoder()))
      }
    } catch {
      println("error \(error)")
    }
    return result
  }

//  @Query("select * from BeitieSingle where structure in (:structures)")
  func getSinglesByStructures(_ structures: List<String>) -> List<BeitieSingle> {
    var result = [BeitieSingle]()
    do {
      let stExp = Expression<String>("structure")
      let rows = try db.prepare(singleTable.filter(structures.contains(stExp)))
      for row in rows {
        result.append(try BeitieSingle(from: row.decoder()))
      }
    } catch {
      println("error \(error)")
    }
    return result
  }
  
//  @Query("select * from BeitieSingle where radical in (:radicals)")
  func getSinglesByRadicals(_ radicals: List<String>) -> List<BeitieSingle> {
    var result = [BeitieSingle]()
    do {
      let exp = Expression<String>("radical")
      let rows = try db.prepare(singleTable.filter(radicals.contains(exp)))
      for row in rows {
        result.append(try BeitieSingle(from: row.decoder()))
      }
    } catch {
      println("error \(error)")
    }
    return result
  }
  
//  @Query("select * from BeitieSingle where chars like :cLike and repeat = 0")
  func getSingles(_ char: Char) -> List<BeitieSingle> {
    var result = [BeitieSingle]()
    do {
      let rows = try db.prepare(singleTable.filter(Expression<String>("chars").like("%\(char)%")))
      for row in rows {
        result.append(try BeitieSingle(from: row.decoder()))
      }
    } catch {
      println("error \(error)")
    }
    return result
  }
  
  
  func searchByFilter(_ filter: FilterViewModel) -> List<BeitieSingle> {
    let strokes = filter.strokes.map { it in
      it.toSearchStroke()
    }
    let structures = filter.structures.map { it in it.toSearchStructure() }
    let radicals = filter.radicals
    var result = HashMap<Int, BeitieSingle>()
    strokes.forEach { stroke in
      dao().getSinglesByStroke(stroke.first().toStrokeInit()).forEach { it in
        result[it.id] = it
      }
    }
    if structures.isNotEmpty() {
      dao().getSinglesByStructures(structures).forEach { it in
        result[it.id] = it
      }
    }
    if radicals.isNotEmpty() {
      var mapped = Set<String>()
      
      radicals.forEach { it in
        mapped.add(it)
        if let m = radicalChsChtMap[it] {
          mapped.add(m)
        }
      }
      dao().getSinglesByRadicals(mapped.toList()).forEach { it in
        result[it.id] = it
      }
    }
    return result.values.map({ $0 })
  }
  
  func search(_ char: Char) -> List<BeitieSingle> {
    var result = Array<BeitieSingle>()
    ChineseConverter.getAllCandidateChars(char).forEach { it in
      result.addAll(dao().getSingles(it))
    }
    return result.distinctBy { it in it.id }
  }
}


extension BeitieImage {
  
  func fileName(_ type: ImageLoadType) -> String {
    switch type {
    case .JpgCompressed, .JpgCompressedThumbnail:
      fileName.replacing(".png", with: ".jpg")
    default:
      fileName
    }
  }
  
  func toTypePath(_ type: ImageLoadType) -> String {
    switch type {
    case ImageLoadType.Original: path
    case ImageLoadType.Thumbnail: path.replacing(fileName, with: ".thumbnail/\(fileName)")
    case ImageLoadType.JpgCompressed: path.replacing(fileName, with: fileName.replacing(".png", with: ".jpg"))
    case ImageLoadType.Compress: path.replacing(fileName, with: ".compress/\(fileName)")
    case ImageLoadType.JpgCompressedThumbnail: path.replacing(fileName, with: ".thumbnail/\(fileName)").replacing(fileName, with: fileName.replacing(".png", with: ".jpg"))
    }
  }
  
  func url(_ type: ImageLoadType) -> String {
    work.urlPrefix + "/" + toTypePath(type)
  }
}

extension BeitieWork {
  
  var showTypeChinese: String {
    shuType?.chinese ?? ""
  }
  var cover: String {
    if (coverUrl.isNotEmpty()) {
      return coverUrl
    }
    let images = BeitieDbHelper.shared.getWorkImages(this.id)
    let img = if (this.hasSingle()) {
      images.first { it in it.singleCount > 0 }
    } else {
      images.first
    }
    return img?.url(ImageLoadType.JpgCompressedThumbnail) ?? ""
  }

}

extension String {
  
  var orgPath: String {
    replacing("单字/", with: "单字_org/")
  }
}

extension BeitieSingle {
  var thumbnailUrl: String {
    let prefix = "images/\(work.folder)"
    let url = url.replacing(prefix, with: "\(prefix)/.thumbnail")
    return if (AnalyzeHelper.singleOriginal) {
      url.orgPath
    } else {
      url
    }
  }
  
  var url: String {
    return work.urlPrefix + "/" + ((AnalyzeHelper.singleOriginal) ? path.orgPath : path )
  }

}
