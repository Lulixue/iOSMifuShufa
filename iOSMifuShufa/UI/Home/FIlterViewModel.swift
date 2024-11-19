//
//  FIlterViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/6.
//
import SwiftUI
import Foundation

enum SearchFilterType: String, CaseIterable {
  case Structure, Radical, Stroke;
  
  var chs: String {
    switch self {
    case .Structure:
      "结构"
    case .Radical:
      "部首"
    case .Stroke:
      "笔画"
    }
  }
  
  var cht: String {
    switch self {
    case .Structure:
      ("結構")
    case .Radical:
      "部首"
    case .Stroke:
      ("筆畫")
    }
  }
  
  var chinese: String {
    chs.orCht(cht)
  }
  
  func isType(_ txt: String) -> Bool { chs == txt || cht == txt }
}

extension Array where Element: Equatable {
  mutating func toggleItem(_ item: Element) {
    if containsItem(item) {
      removeItem(item)
    } else {
      add(item)
    }
  }
}

class FilterViewModel: AlertViewModel {
  @Published var viewWidth: CGFloat = 0
  @Published var radicals = [String]()
  @Published var structures = [String]()
  @Published var strokes = [String]()
  
  var filterCount: Int {
    radicals.size + structures.size + strokes.size
  }
  
  var hasFilter: Bool {
    filterCount > 0
  }
  
  func getFilterInfo() -> String {
    var sb = StringBuilder()
    SearchFilterType.allCases.forEach { type in
      let f = getFilter(type)
      if f.isNotEmpty() {
        sb.append(type.chinese)
        sb.append(": ")
        f.forEach { r in
          sb.append(r)
          sb.append(",")
        }
        sb = String(sb.dropLast())
        sb.append(";")
      }
    }
    return sb
  }
  
  func getFilter(_ type: SearchFilterType) -> List<String> {
    switch type {
    case .Structure:
      structures
    case .Radical:
      radicals
    case .Stroke:
      strokes
    }
  }
  
  private func containsFilter(filter: String, type: SearchFilterType) -> Bool {
    switch type {
    case .Structure:
      structures.containsItem(filter)
    case .Radical:
      radicals.containsItem(filter)
    case .Stroke:
      strokes.containsItem(filter)
    }
  }
  
  func toggleFilter(filter: String, type: SearchFilterType) {
    if !CurrentUser.isVip && hasFilter && !containsFilter(filter: filter, type: type) {
      showConstraintVip(ConstraintItem.SearchFilterCount.topMostConstraintMessage)
      return
    }
    switch type {
    case .Structure:
      structures.toggleItem(filter)
    case .Radical:
      radicals.toggleItem(filter)
    case .Stroke:
      strokes.toggleItem(filter)
    }
  }
  
  func resetAll() {
    SearchFilterType.allCases.forEach {
      resetFilters(type: $0)
    }
  }
  
  func getItemCount(_ type: SearchFilterType) -> Int {
    getFilter(type).size
  }
  
  func resetFilters(type: SearchFilterType) {
    switch type {
    case .Structure:
      structures.clear()
    case .Radical:
      radicals.clear()
    case .Stroke:
      strokes.clear()
    }
  }
  
  static let FILTER_REGEX = /(\S{2}): (\S+?);/
  func parseFilters(_ txt: String) {
    let matches = txt.ranges(of: Self.FILTER_REGEX)
    resetAll()
    for it in matches {
      let sub = txt[it]
      guard let m = try? Self.FILTER_REGEX.wholeMatch(in: sub) else {
        continue
      }
      let type = m.output.1.toString()
      let value = m.output.2.split(separator: ",").map { $0.toString() }
      
      SearchFilterType.allCases.forEach { t in
        if (t.isType(type)) {
          for v in value {
            toggleFilter(filter: v, type: t)
          }
        }
      }
    }
  }
}

extension Substring {
  func toString() -> String {
    String(self)
  }
}
