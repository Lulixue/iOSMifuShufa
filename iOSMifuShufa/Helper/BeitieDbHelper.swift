//
//  BeitieDbHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/3.
//
import SQLite
import Collections
 
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
  case Collection
  
  var chinese: String {
    switch self {
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

class BeitieDbHelper {
  static let shared = BeitieDbHelper()
  let CALLIGRAPHER = "米芾"
  let DB_NAME = "beitie.db"
  let SINGLE_HAS_ORIGINAL = true
  let SUPPORT_ORDER_TYPES = BeitieOrderType.entries
  
  var searchWorks = ArrayList<Int>()
  var jiziWorks = ArrayList<Int>()
  
  init() {
    syncWorkRanges()
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
    let singleWorks = works.filter { it in it.hasSingle() && (!it.vip || CurrentUser.isVip) }
    searchWorks.clear()
    jiziWorks.clear()
    searchWorks.addAll(singleWorks.filter { it in it.canSearch }.map { it in it.id })
    jiziWorks.addAll(singleWorks.filter { it in it.canJizi }.map { it in it.id })
  }
  
  
  func getDefaultTypeWorks(_ stack: Boolean = BeitieOrderType.organizeStack) -> OrderedDictionary<AnyHashable, List<List<BeitieWork>>> {
    return getOrderTypeWorks(BeitieOrderType.orderType, stack)
  }

  typealias BeitieDictionary = OrderedDictionary<AnyHashable, List<List<BeitieWork>>>
  func getOrderTypeWorks(_ orderType: BeitieOrderType, _ stack: Boolean = BeitieOrderType.organizeStack) -> OrderedDictionary<AnyHashable, List<List<BeitieWork>>> {
    let result = switch orderType {
    case .Default:
      stack ? defaultWorksStack : defaultWorks
    default:
      stack ? defaultWorksStack : defaultWorks
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
    
    ordered[WorkCategory.Normal] = left.filter { it in !it.primary && it.hasSingle() }
      .apply { it in
        left.removeAll { it.containsItem($0) }
      }.map({ Array.listOf($0)})
    
    ordered[WorkCategory.Beikei] = beis
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
  private func getSinglesByComponent(char: Char, lmt: Int = 10000) -> List<BeitieSingle> {
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

  
  func searchComponent(_ char: Char) -> List<BeitieSingle> {
    getSinglesByComponent(char: char)
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
    let strokes = filter.strokes
    let structures = filter.structures
    let radicals = filter.radicals
    var result = HashMap<Int, BeitieSingle>()
    strokes.forEach { stroke in
      dao().getSinglesByStroke(stroke.first().toStrokeInit()).forEach { it in
        result[it.id] = it
      }
    }
    if structures.isNotEmpty() {
      dao().getSinglesByStructures(structures.map { it in it.toSearchStructure() }).forEach { it in
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
    return if (AnalyzeHelper.shared.singleOriginal) {
      url.orgPath
    } else {
      url
    }
  }
  
  
  
  var url: String {
    return work.urlPrefix + "/" + ((AnalyzeHelper.shared.singleOriginal) ? path.orgPath : path )
  }

}
