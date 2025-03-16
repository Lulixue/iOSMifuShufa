//
//  ChineseConverter.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//
import Foundation

extension Set {
  mutating func add(_ element: Element) {
    insert(element)
  }
  
  func apply(action: @escaping (Set) -> Void) -> Set {
    action(self)
    return self
  }
}

extension Array {
  func `let`(action: @escaping (Array) -> Array) -> Array {
    return action(self)
  }
  
  func ifEmpty(callback: @escaping () -> Array?) -> Array? {
    if isEmpty() {
      return callback()
    } else {
      return self
    }
  }
}

extension Char {
  func `let`(action: @escaping (Char) -> Void) -> Char {
    action(self)
    return self
  }
  func also(action: @escaping (Char) -> Void) {
    action(self)
  }
}

class ChineseConverter {
  private static var standardVariantsMap = HashMap<Char, Set<Char>>()
  private static let variants: [Char: Set<Char>] = {
    var variantsMap = HashMap<Char, Set<Char>>()
    for file in ["variants", "sf_variants"] {
      let contents = ResourceHelper.readFileContents(fileURL: Bundle.main.url(forResource: file, withExtension:"json")!)
      do {
        let collections = try JSONDecoder().decode([String: String].self, from: contents.utf8Data)
        for key in collections.keys {
          let fan = key.toString().first()
          let value = collections[key]!.toString()
          var variants = HashSet<Char>()
          variants.add(fan)
          value.forEach { it in
            variants.add(it)
          }
          standardVariantsMap[fan] = variants
          variantsMap[fan] = variants
          for char in variants {
            var resultSet = HashSet(variants)
            resultSet.remove(char)
            variantsMap[char] = resultSet
          }
        }
      } catch {
        println("variants \(error)")
      }
    }
    return variantsMap
  }()
  
  private static let chtChsMap = {
    var map = HashMap<Char, String>()
    chsChtMap.forEach { (k, v) in
      v.forEach { c in
        if map.containsKey(c) {
          map[c] = map[c]! + "/" + k.toString()
        } else {
          map[c] = k.toString()
        }
      }
    }
    return map
  }()
  
  private static let chsChtMap = {
    var map = HashMap<Char, Set<Char>>()
    let contents = ResourceHelper.readFileContents(fileURL: Bundle.main.url(forResource: "chs_cht", withExtension:"json")!)
    do {
      let collections = try JSONDecoder().decode([String: String].self, from: contents.utf8Data)
      for key in collections.keys {
        let chsChar = key.toString().first()
        let chars = collections[key]!.toString()
        map[chsChar] = Set(chars.map({ $0 }))
      }
    } catch {
      println("chsChtMap \(error)")
    }
    return map
  }()
  
  
  static func getCht(_ char: Char) -> Char {
    if chtChsMap.containsKey(char) {
      return char
    }
    if (chsChtMap.containsKey(char)) {
      let chts = chsChtMap[char]!
      if (chts.size == 1) {
        return chts.first()
      }
      for c in chts {
        if standardVariantsMap.containsKey(c) {
          return c
        }
      }
    }
    for (t, u) in standardVariantsMap {
      if u.contains(char) {
        return t
      }
    }
    return char
  }
  
  private static var variantStdMap: HashMap<Char, Char> = {
    var variantsMap = HashMap<Char, Char>()
    for (k, v) in variants {
      v.forEach { it in
        variantsMap[it] = k
      }
    }
    return variantsMap
  }()
  
  static func getStdCht(_ char: Char) -> Char {
    variantStdMap[char] ?? char
  }

  
  private static let FORCE_SHORT_CHARS = "冈"

  static func charForceShow(_ char: Char) -> Boolean {
    return FORCE_SHORT_CHARS.contains(char)
  }
  
  static func getChs(_ char: Char) -> String {
    if (chsChtMap.containsKey(char)) {
      return char.toString()
    }
    
    if (chtChsMap.containsKey(char)) {
      return chtChsMap[char]!
    }
    
    for (t, u) in standardVariantsMap {
      if (u.contains(char)) {
        if chtChsMap.containsKey(t) {
          return chtChsMap[t]!
        }
      }
    }
    return char.toString()
  }
  
  
  private static func getAllChtChars(_ char: Char) -> String {
    if chtChsMap.containsKey(char) {
      return char.toString()
    }
    if chsChtMap.containsKey(char) {
      let chts = chsChtMap[char]!
      var sb = StringBuilder()
      for c in chts {
        sb.append(c)
        if standardVariantsMap.containsKey(c) {
          sb.append(standardVariantsMap[c]!.toCharString())
        }
      }
      return sb.toString()
    }
    for (t, u) in standardVariantsMap {
      if u.containsItem(char) {
        return t.toString()
      }
    }
    return char.toString()
  }

  
  static func getNotPartCht(_ char: Char) -> String? {
    let cht = getAllChtChars(char)
    if (cht == char.toString()) {
      return nil
    }
    var result = StringBuilder()
    for c in cht {
      if let it = ChineseDbHelper.dao.getChineseChar(c.utf8Code) {
        if (it.mainComponents?.contains(char.toString()) != true) {
          result.append(c)
        }
      }
    }
    return result.toString()
  }
  
  static func getPrintChars(_ char: Char, _ chsFirst: Boolean) -> List<Char> {
    return (chsFirst) ? getAllCandidateChars(char) : getPrintChtChars(char)
  }

  static func getPrintChtChars(_ char: Char) -> List<Char> {
    var result = List<Char>()
    if chsChtMap.containsKey(char) {
      let chts = chsChtMap[char]!
      result.addAll(chts.toList())
      for c in chts {
        if let it = variants[c] {
          result.addAll(it.toList())
        }
      }
    }
    for (t, u) in standardVariantsMap {
      if u.containsItem(char) {
        result.add(t)
        break
      }
    }
    result.add(char)
    return result
  }

  static func getAllCandidateChars(_ char: Char) -> List<Char> {
    if (char == "间" || char == "間") {
      return Array.listOf("间", "間", "閒")
    } else if (char == "闲" || char == "閑") {
      return Array.listOf("闲", "閒", "閑")
    }
    
    var chars = Array<Char>()
    chars.add(char)
    
    if let it = chtChsMap[char] {
      for c in it {
        if c.charIsChinesChar() {
          chars.addDistinct(c)
        }
      }
    }
    chsChtMap[char]?.forEach { it in
      chars.addDistinct(it)
    }
    chars.forEach { it in
      variants[it]?.forEach { c in
        chars.addDistinct(c)
      }
    }
    return chars
  }
}

extension Set where Element == Char {
  func toCharString() -> String {
    var sb = StringBuilder()
    for c in self {
      sb.append(c)
    }
    return sb.toString()
  }
}
