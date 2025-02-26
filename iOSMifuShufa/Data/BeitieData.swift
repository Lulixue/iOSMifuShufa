//
//  BeitieData.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/31.
//
import SwiftUI

enum ShuType: String {
  case Short
  case Long
  
  var chinese: String {
    switch self {
    case .Short: "尺牍".orCht("尺牘")
    case .Long: "长卷".orCht("長卷")
    }
  }
}
 
enum CalligraphyFont: String, CaseIterable {
  case Kai
  case XingKai
  case Xing
  case XingCao
  case Cao
  case Li
  case Zhuan
  case Others
  
  var chinese: String {
    switch self {
    case .Kai:
      "楷"
    case .XingKai:
      "行楷"
    case .Xing:
      "行"
    case .XingCao:
      "行草"
    case .Cao:
      "草"
    case .Li:
      "隶".orCht("隸")
    case .Zhuan:
      "篆"
    case .Others:
      "其他"
    }
  }
  
  var longChinese: String {
    chinese.length == 2 ? chinese : "\(chinese)\("书".orCht("書"))"
  }
  
  var padding: Int {
    switch self {
    case .Kai, .Xing: 2
    case .Li: 1
    default:
      0
    }
  }
}

enum CalligraphyAuthenticity: String {
  case Unknown
  case GenerallyRecognized
  case Doubtful
  case Fake
  
  var chinese: String {
    switch self {
      case .Unknown: "未知".orCht("未知")
      case .GenerallyRecognized: "公认".orCht("公認")
      case .Doubtful: "存疑".orCht("存疑")
      case .Fake: "伪作".orCht("偽作")
    }
  }
}


enum CalligraphyType: String, CaseIterable {
  case Unknown
  case Tie
  case Bei
  case Hua
  
  var chinese: String {
    switch self {
    case .Unknown:
      "未知"
    case .Tie:
      "帖"
    case .Bei:
      "碑"
    case .Hua:
      "画".orCht("畫")
    }
  }
  
  var typeChinese: String {
    switch (self) {
    case .Unknown: chinese
    case .Tie: "纸本".orCht("紙本")
    case .Bei: "拓本".orCht("搨本")
    case .Hua: "绘画".orCht("繪畫")
    }
  }
}

enum Dynasty: String {
  case Unknown
  case PreQin
  case Qin
  case Han
  case SanGuo
  case WeiJin
  case NanBeiChao
  case Sui
  case Tang
  case WuDai
  case Song
  case Yuan
  case Ming
  case Qing
  case Recent
  case Current
  
  var chinese: String {
    switch self {
    case .Unknown:
      "未知"
    case .PreQin:
      "先秦"
    case .Qin:
      "秦"
    case .Han:
      "汉".orCht("漢")
    case .SanGuo:
      "三国".orCht("三國")
    case .WeiJin:
      "魏晋".orCht("魏晉")
    case .NanBeiChao:
      "南北朝"
    case .Sui:
      "隋"
    case .Tang:
      "唐"
    case .WuDai:
      "五代"
    case .Song:
      "宋"
    case .Yuan:
      "元"
    case .Ming:
      "明"
    case .Qing:
      "清"
    case .Recent:
      "近代"
    case .Current:
      "当代".orCht("當代")
    }
  }
}

class BeitieWork: Decodable, Equatable, Hashable {
  static func == (lhs: BeitieWork, rhs: BeitieWork) -> Bool {
    lhs.id == rhs.id
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  var id: Int
  var name: String
  var version: String? = nil
  var shortName: String
  var author: String
  var dynasty: Dynasty
  var detailDynasty: String
  var year: String? = nil
  var articleAuthor: String? = nil
  var folder: String
  var coverUrl: String
  var urlPrefix: String
  var font: CalligraphyFont
  var detailFont: String
  var type: CalligraphyType
  var primary: Boolean
  var imageCount: Int
  var singleCount: Int
  var text: String? = nil
  var intro: String? = nil
  var authenticity: CalligraphyAuthenticity = CalligraphyAuthenticity.Unknown
  var vip: Boolean = false
  var nameCht: String? = nil
  var textCht: String? = nil
  var versionCht: String? = nil
  var introCht: String? = nil
  var yearCht: String? = nil
  var authorCht: String? = nil
  var ceYear: Int = 0
  var shuType: ShuType? = nil
  
  enum CodingKeys: CodingKey {
    case id
    case name
    case version
    case shortName
    case author
    case dynasty
    case detailDynasty
    case year
    case articleAuthor
    case folder
    case coverUrl
    case urlPrefix
    case font
    case detailFont
    case type
    case primary
    case imageCount
    case singleCount
    case text
    case intro
    case authenticity
    case vip
    case nameCht
    case textCht
    case versionCht
    case introCht
    case yearCht
    case authorCht
    case ceYear
    case shuType
  }
  
  func matchKeyword(keyword: String) -> Bool {
    name.contains(keyword) || nameCht.notNullContains(keyword) || version.notNullContains(keyword) ||
      versionCht.notNullContains(keyword)
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: Self.CodingKeys)
    self.id = try container.decode(Int.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    self.version = try container.decode(String.self, forKey: .version)
    self.shortName = try container.decode(String.self, forKey: .shortName)
    self.author = try container.decode(String.self, forKey: .author)
    self.dynasty = Dynasty(rawValue: try container.decode(String.self, forKey: .dynasty))!
    self.detailDynasty = try container.decode(String.self, forKey: .detailDynasty)
    self.year = try container.decode(String.self, forKey: .year)
    self.articleAuthor = try container.decode(String.self, forKey: .articleAuthor)
    self.folder = try container.decode(String.self, forKey: .folder)
    self.coverUrl = try container.decode(String.self, forKey: .coverUrl)
    self.urlPrefix = try container.decode(String.self, forKey: .urlPrefix)
    self.font = CalligraphyFont(rawValue: try container.decode(String.self, forKey: .font))!
    self.detailFont = try container.decode(String.self, forKey: .detailFont)
    self.type = CalligraphyType(rawValue: try container.decode(String.self, forKey: .type))!
    self.primary = try container.decode(Bool.self, forKey: .primary)
    self.imageCount = try container.decode(Int.self, forKey: .imageCount)
    self.singleCount = try container.decode(Int.self, forKey: .singleCount)
    self.text = try container.decode(String.self, forKey: .text)
    self.intro = try container.decode(String.self, forKey: .intro)
    self.authenticity = CalligraphyAuthenticity(rawValue: try container.decode(String.self, forKey: .authenticity))!
    self.vip = try container.decode(Bool.self, forKey: .vip)
    self.nameCht = try container.decode(String.self, forKey: .nameCht)
    self.textCht = try container.decode(String.self, forKey: .textCht)
    self.versionCht = try container.decode(String.self, forKey: .versionCht)
    self.introCht = try container.decode(String.self, forKey: .introCht)
    self.yearCht = try container.decode(String.self, forKey: .yearCht)
    self.authorCht = try container.decode(String.self, forKey: .authorCht)
    self.ceYear = try container.decode(Int.self, forKey: .ceYear)
    self.shuType = ShuType(rawValue: try container.decode(String.self, forKey: .shuType))!
  }
}

class BeitieSingle: Decodable, Equatable, Hashable {
  static func == (lhs: BeitieSingle, rhs: BeitieSingle) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  var id: Int = 0
  var index: Int = 0
  var fileName: String = ""
  var imageName: String = ""
  var path: String = ""
  var chars: String = ""
  var imageId: Int = 0
  var workId: Int = 0
  var brokenLevel: Int = 0
  var `repeat`: Boolean = false
  var lian: Boolean = false
  var radical: String? = nil
  var structure: String? = nil
  var strokeCount: Int = 0
  var strokes: String? = nil
  var components: String? = nil
  var mainComponents: String? = nil
  var box: String? = nil
  var font: CalligraphyFont? = nil
  var matched: Char? = nil
  
  enum CodingKeys: CodingKey {
    case id
    case index
    case fileName
    case imageName
    case path
    case chars
    case imageId
    case workId
    case brokenLevel
    case lian
    case radical
    case structure
    case strokeCount
    case strokes
    case components
    case mainComponents
    case box
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int.self, forKey: .id)
    self.index = try container.decode(Int.self, forKey: .index)
    self.fileName = try container.decode(String.self, forKey: .fileName)
    self.imageName = try container.decode(String.self, forKey: .imageName)
    self.path = try container.decode(String.self, forKey: .path)
    self.chars = try container.decode(String.self, forKey: .chars)
    self.imageId = try container.decode(Int.self, forKey: .imageId)
    self.workId = try container.decode(Int.self, forKey: .workId)
    self.brokenLevel = try container.decode(Int.self, forKey: .brokenLevel)
    self.lian = try container.decode(Boolean.self, forKey: .lian)
    self.radical = try container.decodeIfPresent(String.self, forKey: .radical)
    self.structure = try container.decodeIfPresent(String.self, forKey: .structure)
    self.strokeCount = try container.decode(Int.self, forKey: .strokeCount)
    self.strokes = try container.decodeIfPresent(String.self, forKey: .strokes)
    self.components = try container.decodeIfPresent(String.self, forKey: .components)
    self.mainComponents = try container.decodeIfPresent(String.self, forKey: .mainComponents)
    self.box = try container.decodeIfPresent(String.self, forKey: .box)
  }
}

class BeitieImage: Decodable, Hashable {
  static func == (lhs: BeitieImage, rhs: BeitieImage) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id.toString())
  }
  
  var id: Int
  var fileName: String
  var path: String
  var text: String?
  var index: Int
  var workFolder: String
  var workId: Int
  var singleCount: Int
  var textCht: String? = nil
  
  func chineseText() -> String? { text?.orChtNullable(textCht) }
  
  enum CodingKeys: CodingKey {
    case id
    case fileName
    case path
    case text
    case index
    case workFolder
    case workId
    case singleCount
    case textCht
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int.self, forKey: .id)
    self.fileName = try container.decode(String.self, forKey: .fileName)
    self.path = try container.decode(String.self, forKey: .path)
    self.text = try container.decodeIfPresent(String.self, forKey: .text)
    self.index = try container.decode(Int.self, forKey: .index)
    self.workFolder = try container.decode(String.self, forKey: .workFolder)
    self.workId = try container.decode(Int.self, forKey: .workId)
    self.singleCount = try container.decode(Int.self, forKey: .singleCount)
    self.textCht = try container.decodeIfPresent(String.self, forKey: .textCht)
  }
}

extension String {
  func orChtNullable(_ cht: String?) -> String? {
    if (cht?.isNotEmpty() == true && !Settings.langChs) {
      return cht
    } else {
      return self
    }
  }
}

extension BeitieWork {
  func hasSingle() -> Bool {
    singleCount > 0
  }
  var matchVip: Bool { CurrentUser.userIsVip || !self.vip }
  var notMatchVip: Bool { !matchVip }
  
  var this: BeitieWork {
    self
  }
  private var searchKey: String {
    "\(this.name)\(String(describing: this.version))CanSearch"
  }
  private var jiziKey: String {
    "\(this.name)\(String(describing: this.version))CanJizi"
  }

  func isTrue() -> Bool { authenticity == CalligraphyAuthenticity.GenerallyRecognized }

  
  var canSearch: Boolean {
    get {
      return Settings.getBoolean(searchKey, true)
    }
    set {
      Settings.putBoolean(searchKey, newValue)
      
    }
  }
  
  var canJizi: Boolean {
    get {
      if this.vip && !CurrentUser.isVip {
        return true
      } else {
        return Settings.getBoolean(jiziKey, true)
      }
    }
    set {
      Settings.putBoolean(jiziKey, newValue)
    }
  }
  
  func baseChineseName() -> String { name.orCht(nameCht) }
  func chineseName() -> String { baseChineseName() }
  func chineseAuthor() -> String { author.orCht(authorCht) }
  
  func chineseFolder() -> String {
    let version = chineseVersion()
    return baseChineseName() + {
      if (version?.isNotEmpty() == true) {
        "_\(version!)"
      } else {
        ""
      }
    }()
  }
   
  func chineseText() -> String? { text?.orChtNullable(textCht) }
  
  func chineseYear() -> String? { year?.orChtNullable(yearCht) }
  
  func chineseIntro() -> String? { intro?.orChtNullable(introCht) }
  
  func chineseVersion() -> String? { version?.orChtNullable(versionCht) }
  
  func miGridColor() -> UIColor { (type == CalligraphyType.Tie) ? UIColor.black : UIColor.lightGray }
      
  
}

extension BeitieSingle {
  var writtenChar: Char {
    chars.first()
  }
  var work: BeitieWork {
    BeitieDbHelper.shared.getWorkById(workId) ?? PreviewHelper.defaultWork
  }
  
  var showChars: String {
    let wc = writtenChar
    let stdCht = ChineseConverter.getStdCht(wc)
    let chs = ChineseConverter.getChs(wc)
    let wcStr =  (stdCht != wc && chs.contains(stdCht)) ? "\(wc)[\(stdCht)]" : wc.toString()
    if (!Settings.langChs) {
      return wc.toString()
    } else {
      if wcStr.contains(chs) {
        return wc.toString()
      }
      return "\(wc)(\(chs))"
    }  }
  
  var image: BeitieImage? {
    BeitieDbHelper.shared.getImageById(imageId)
  }
}

extension BeitieWork {
  var smallChineseVersion: String {
    if (chineseVersion()?.isNotEmpty() == true) { " <small>\(chineseVersion()!)</small>" } else { "" }
  }
  var workName: String {
    "《\(chineseName())》\(smallChineseVersion)"
  }
  
  func workNameAttrStr(_ font: Font = .body, smallerFont: Font = .footnote, curves: Bool = true) -> AttributedString {
    var name = AttributedString(!curves ? chineseName() : "《\(chineseName())》")
    let v = chineseVersion() ?? ""
    var version = AttributedString(v.isNotEmpty() ? " \(v)" : v)
    name.font = font
    version.font = smallerFont
    return name + version
  }
  
  var workHtmlInfo: String {
    chineseName() + smallChineseVersion
  }
  
  var vipToast: String {
    "VIP碑帖：\(workName)"
  }
}


enum ImageLoadType {
  case Original, Thumbnail, Compress, JpgCompressed, JpgCompressedThumbnail;
}

extension BeitieImage {
  var work: BeitieWork {
    BeitieDbHelper.shared.getWorkById(self.workId) ?? PreviewHelper.defaultWork
  }
}



let radicalChsChtMap: [String: String] = [
  "讠": "言", "门": "門", "马": "馬", "鸟": "鳥", "长": "長",
  "见": "見", "车": "車", "贝": "貝", "页": "頁", "饣": "飠",
  "钅": "釒", "齐": "齊", "卤": "鹵", "韦": "韋", "纟": "糹",
  "麦": "麥", "风": "風", "鱼": "魚", "龙": "龍", "齿": "齒",
  "仑": "龠"
]

extension String {
  var lastIndex: Int {
    count - 1
  }
  
  mutating func deleteCharAt(_ index: Int) {
    self.remove(at: self.index(startIndex, offsetBy: index))
  }
  var separatedChars: String {
    var sb = StringBuilder()
    this.forEach { it in
      sb.append(it)
      sb.append("/")
    }
    sb.deleteCharAt(sb.lastIndex)
    return sb.toString()
  }
  
}


class Calligrapher: Decodable {
  var id: Int
  var name: String
  var nameCht: String
  var dynasty: Dynasty
  var detailDynasty: String
  var intro: String
  var introCht: String
  var avatarUrl: String? = nil
  var az: String
  var famous: Boolean
  
  enum CodingKeys: CodingKey {
    case id
    case name
    case nameCht
    case dynasty
    case detailDynasty
    case intro
    case introCht
    case avatarUrl
    case az
    case famous
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    self.nameCht = try container.decode(String.self, forKey: .nameCht)
    self.dynasty = Dynasty(rawValue: try container.decode(String.self, forKey: .dynasty))!
    self.detailDynasty = try container.decode(String.self, forKey: .detailDynasty)
    self.intro = try container.decode(String.self, forKey: .intro)
    self.introCht = try container.decode(String.self, forKey: .introCht)
    self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
    self.az = try container.decode(String.self, forKey: .az)
    self.famous = try container.decode(Boolean.self, forKey: .famous)
  }
}


extension BeitieDbHelper {
  func searchComponent(_ char: Char) -> List<BeitieSingle> {
    let componentResult = getSinglesByComponent(char: char)

    if (Settings.languageVersion == ChineseVersion.Simplified) {
       if let cht = ChineseConverter.getNotPartCht(char) {
         var result = ArrayList<BeitieSingle>()
         result.addAll(componentResult)
         for c in cht {
           let chtResult = getSinglesByComponent(char: c)
           result.addAll(chtResult)
         }
         return result
       }
     }
     return componentResult
  }
}


extension BeitieSingle {
  var matchVip: Bool {
    work.matchVip
  }
  
  var notMatchVip: Bool {
    !matchVip
  }
}
