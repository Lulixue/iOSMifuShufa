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
    let contents = ResourceHelper.readFileContents(fileURL: Bundle.main.url(forResource: "variants", withExtension:"json")!)
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
    return variantsMap
  }()
  
  private static let chtChsMap = {
    var map = HashMap<Char, Char>()
    chsChtMap.forEach { (k, v) in
      v.forEach { c in
        map[c] = k
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
  
  static func getChs(_ char: Char) -> Char {
    if (chsChtMap.containsKey(char)) {
      return char
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
    return char
  }
  
  static func getAllCandidateChars(_ char: Char) -> List<Char> {
    var chars = Array<Char>()
    chars.add(char)
    
    chtChsMap[char]?.also { it in
      chars.addDistinct(it)
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
