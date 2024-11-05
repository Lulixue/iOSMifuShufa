//
//  Extension.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import Foundation

extension Dictionary {
  
  func containsKey(_ key: Key) -> Bool {
    return self[key] != nil
  }
  
  mutating func clear() {
    removeAll()
  }
  
  var size: Int {
    return count
  }
  
  func isEmpty() -> Bool {
    return size == 0
  }
  
  mutating func putAll(_ dict: [Key: Value]) {
    for (k, v) in dict {
      self[k] = v
    }
  }
}

extension Collection where Element: Equatable {
  public func containsItem(_ item: Element) -> Bool {
    return self.contains { val in
      val == item
    }
  }
}
extension Array {
  func apply(operation: @escaping (Array) -> Void) -> Array {
    operation(self)
    return self
  }
   
  mutating func replaceLast(_ last: Element?) {
    guard last != nil else { return }
    self.removeLast()
    self.append(last!)
  }
  
  static func arrayOf(_ elems: Element...) -> Array<Element> {
    return elems
  }
  static func listOf(_ elems: Element...) -> Array<Element> {
    return elems
  }
  static func arrayListOf(_ elems: Element...) -> Array<Element> {
    return elems
  }
  
  var size: Int {
    return self.count
  }
  
  var lastIndex: Int {
    return count - 1
  }
  
  func distinctBy<E: Equatable>(_ mapper: (Element) -> E) -> Array {
    var ids = [E]()
    var unique = [Element]()
    for elem in self {
      let elemID = mapper(elem)
      if !ids.contains(elemID) {
        unique.append(elem)
        ids.append(elemID)
      }
    }
    return unique
  }
  
  func isNotEmpty() -> Bool {
    return !isEmpty
  }
  
  mutating func add(_ elem: Element) {
    self.append(elem)
  }
  
  func isEmpty() -> Bool {
    return isEmpty
  }
  mutating func clear() {
    self.removeAll()
  }
  mutating func addAll(_ fromCollection: Array) {
    self.append(contentsOf: fromCollection)
  }
  func first() -> Element {
    return first!
  }
  func last() -> Element {
    return last!
  }
}


extension Array where Element : Equatable {
  func indexOf(_ elem: Element) -> Int {
    var index = 0
    for item in self {
      if item == elem {
        return index
      }
      index += 1
    }
    return -1
  }
  var unique: [Element] {
    var uniqueValues: [Element] = []
    forEach { item in
      guard !uniqueValues.contains(item) else { return }
      uniqueValues.append(item)
    }
    return uniqueValues
  }
}


extension String {
  var length: Int {
    return self.count
  }
  
  var containsChineseChar: Bool {
    self.first { $0.charIsChinesChar() } != nil
  }
  
  func isNotEmpty() -> Bool {
    return !isEmpty
  }
  
  func isEmpty() -> Bool {
    return isEmpty
  }
  func last() -> Character {
    return last!
  }
  func first() -> Character {
    return first!
  }
  func toString() -> String {
    return self
  }
  
  var utf8Data: Data {
    return self.data(using: .utf8)!
  }
  
  var charUtf8: String {
    for codeUnit in self.unicodeScalars {
      return String(format: "%04X", codeUnit.value)
    }
    return ""
  }
  
  func trim() -> String {
    trimEnd()
  }
  
  func trimEnd() -> String {
    return self.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  mutating func clear() {
    self = ""
  }
}

extension String? {
  var isEmptyOrNil: Bool {
    self == nil || self?.length == 0
  }
  var isNotEmptyOrNil: Bool {
    !isEmptyOrNil
  }
  
  func notNullContains(_ text: String) -> Bool {
    self?.contains(text) == true
  }
}


extension CGFloat {
  func toInt() -> Int {
    Int(self)
  }
}

extension Int {
  func toCGFloat() -> CGFloat {
    CGFloat(self)
  }
  func toString() -> String {
    "\(self)"
  }
}
