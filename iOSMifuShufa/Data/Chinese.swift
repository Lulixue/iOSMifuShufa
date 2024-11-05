//
//  Chinese.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import Foundation
import UIKit

enum ChineseVersion : String, Codable, CaseIterable {
  case Simplified
  case Traditional
  case Unspecified
  
  var isChs: Bool {
    self == .Simplified
  }
  
  func getValue<T>(_ chs: T, _ cht: T) -> T {
    isChs ? chs : cht
  }
  
}

extension ChineseVersion {
  var name: String {
    switch self {
    case .Simplified: return "简体中文"
    case .Traditional: return "繁體中文"
    case .Unspecified: return "跟随系统".orCht("跟隨系統")
    }
  }
  
  var otherwise: ChineseVersion {
    switch self {
    case .Traditional: return .Simplified
    case .Simplified: return .Traditional
    default: return .Unspecified
    }
  }
  
  func getObject<T>(chs: T, cht: T) -> T {
    switch (self) {
    case .Simplified: return chs
    case .Traditional: return cht
    case .Unspecified: return chs
    }
  }
}


private let LOCALIZE_STRINGS: [String:[String]] = loadStrings()
private var CHS_CHT_PAIRS: [String: String] = [String: String]()

extension String? {
  func orCht(_ cht: String?) -> String? {
    Settings.languageVersion == ChineseVersion.Simplified ? self : cht
  }
}

extension Character {
  func isNumber() -> Bool {
    return isNumber
  }
  
  func toString() -> String {
    return "\(self)"
  }
  
  func toInt() -> Int {
    let scalar = self.unicodeScalars.first?.value
    return Int(scalar ?? 0)
  }
  
  func charIsChinesChar() -> Bool {
    return ChineseHelper.charIsChineseChar(self)
  }
}

extension String {
  func orCht(_ cht: String?) -> String {
    if (cht?.isNotEmpty() == true) {
      return Settings.languageVersion == ChineseVersion.Simplified ? self : cht!
    } else {
      return self
    }
  }
  
  var toCharList: List<Char> {
    var chars = [Char]()
    for c in self {
      if c.charIsChinesChar() {
        chars.append(c)
      }
    }
    return chars
  }
  
  var hasChinese: Bool {
    for c in self {
      if c.charIsChinesChar() {
        return true
      }
    }
    return false
    
  }
  var localized: String {
    let index = Settings.languageVersion == ChineseVersion.Simplified ? 0 : 1
    return LOCALIZE_STRINGS.containsKey(self) ? LOCALIZE_STRINGS[self]![index] : self
  }
  
  var resString: String {
    localized
  }
  var localizedFromChs: String {
    if Settings.languageVersion == ChineseVersion.Simplified {
      return self
    }
    return CHS_CHT_PAIRS.containsKey(self) ? CHS_CHT_PAIRS[self]! : self
  }
  var interfaceStr: String {
    if self.hasChinese {
      return localizedFromChs
    } else {
      return localized
    }
  }
}


private func loadStrings() -> [String: [String]] {
  let chsMap = loadChineseStrings(filename: "strings_chs.xml")
  let chtMap = loadChineseStrings(filename: "strings.xml")
  var result = [String: [String]]()
  for key in chsMap.keys {
    let chs = chsMap[key] ?? key
    let cht = chtMap[key] ?? key
    result[key] = [chs, cht]
    CHS_CHT_PAIRS[chs] = cht
  }
  return result
}



private func loadChineseStrings(filename: String) -> [String: String] {
  guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
  else {
    fatalError("Couldn't find \(filename) in main bundle.")
  }
  
  do {
    let regex = try! NSRegularExpression(pattern: "<string name=\"(?<name>[a-zA-Z_0-9]+)\">\"?(?<text>.*?)\"?</string>")
    let fontRegex = try! NSRegularExpression(pattern: "<font.*?>\"?(.*?)\"?</font>")
    var resultMap = [String: String]()
    let data = try String(contentsOf: file, encoding: .utf8)
    let myStrings = data.components(separatedBy: .newlines)
    for str in myStrings {
      let range = NSRange(location: 0, length: str.count)
      if let result = regex.firstMatch(in: str, range: range) {
        let nameRange = result.range(withName: "name")
        let textRange = result.range(withName: "text")
        let nsString = str as NSString
        let name = nsString.substring(with: nameRange)
        let text = nsString.substring(with: textRange)
        if text.contains("<font") {
          let replaced = fontRegex.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "$1")
          resultMap[name] = replaced
        } else {
          resultMap[name] = text
        }
      }
    }
    return resultMap
  } catch {
    fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
  }
  
}



class ChineseHelper {
  public static let CHINESE_TEN_NUMBERS: [Character] = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
  private static let CHINESE_SHI: Character = "十"
  private static let CHINESE_BAI: Character = "百"
  private static let CHINESE_QIAN: Character = "千"
  private static let CHINESE_WAN: Character = "万"
  private static let ChineseNumberMap: [Int : Character] = [
    10000: CHINESE_WAN,
    1000: CHINESE_QIAN,
    100: CHINESE_BAI,
    10: CHINESE_SHI
  ]
  
  /*
   * Block                                   Range       Comment
   CJK Unified Ideographs                  4E00-9FFF   Common
   CJK Unified Ideographs Extension A      3400-4DBF   Rare
   CJK Unified Ideographs Extension B      20000-2A6DF Rare, historic
   CJK Unified Ideographs Extension C      2A700–2B73F Rare, historic
   CJK Unified Ideographs Extension D      2B740–2B81F Uncommon, some in current use
   CJK Unified Ideographs Extension E      2B820–2CEAF Rare, historic
   private use                             E815 - E864
   CJK Compatibility Ideographs            F900-FAFF   Duplicates, unifiable variants, corporate characters
   CJK Compatibility Ideographs Supplement 2F800-2FA1F Unifiable variants
   *
   */
  /*
   * private use  E815 - E864
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","",
   */
  
  /*
   * Block                                   Range       Comment
   CJK Unified Ideographs                  4E00-9FFF   Common
   CJK Unified Ideographs Extension A      3400-4DBF   Rare
   CJK Unified Ideographs Extension B      20000-2A6DF Rare, historic
   CJK Unified Ideographs Extension C      2A700–2B73F Rare, historic
   CJK Unified Ideographs Extension D      2B740–2B81F Uncommon, some in current use
   CJK Unified Ideographs Extension E      2B820–2CEAF Rare, historic
   private use                             E815 - E864
   CJK Compatibility Ideographs            F900-FAFF   Duplicates, unifiable variants, corporate characters
   CJK Compatibility Ideographs Supplement 2F800-2FA1F Unifiable variants
   *
   */
  /*
   * private use  E815 - E864
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","","","","","","","","","","","",
   * "","","","","",
   */
  static let UNICODE_CHS_START = 0x4E00 // CJK字符集
  static let UNICODE_CHS_END = 0x9FBB
  static let DICT_UNICODE_CHINESE_RANGES: [ClosedRange<UInt32>] = [
    0x4E00...0x9FFF,   // main block
    0x3400...0x4DBF,   // extended block A
    0x20000...0x2A6DF, // extended block B
    0x2A700...0x2B73F, // extended block C
  ]
  
  
  static func getChineseCharsDistinct(txt: String) -> [Character] {
    var chars = [Character]()
    for ch in txt {
      if (ChineseHelper.charIsChineseChar(ch)) {
        if (!chars.contains(ch)) {
          chars.append(ch)
        }
      }
    }
    return chars
  }
  
  static func getChineseCharCount(txt: String) -> Int {
    var count = 0
    for c in txt {
      if (charIsChineseChar(c)) {
        count += 1
      }
    }
    return count
  }
  
  
  static func charIsChineseChar(_ ch: Character) -> Bool {
    let uInt = ch.unicodeScalars.first!.value
    return charIsChineseChar(uInt)
  }
  
  static func charIsChineseChar(_ hex: UInt32) -> Bool {
    for range in DICT_UNICODE_CHINESE_RANGES {
      if (range.contains(hex)) {
        return true
      }
    }
    return false
  }
  
  private static func numberToChineseTen(_ number: Int) -> Character {
    return ChineseHelper.CHINESE_TEN_NUMBERS[number-1]
  }
  
  static func numberToChineseIndex(number: Int) -> String {
    let ge = (number % 10)
    var sb = ""
    for (level, chinese) in ChineseHelper.ChineseNumberMap {
      let count = (number % (level*10)) / level
      if (count > 0) {
        if (level == 10) {
          if (!sb.isEmpty || count > 1) {
            sb.append(numberToChineseTen(count))
          }
        } else {
          sb.append(numberToChineseTen(count))
        }
        sb.append(chinese)
      }
    }
    if (ge != 0) {
      sb.append(numberToChineseTen(ge))
    }
    return sb
  }
  
}
