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
  
  var chinese: String {
    switch self {
    case .Structure:
      "结构".orCht("結構")
    case .Radical:
      "部首"
    case .Stroke:
      "笔画".orCht("筆畫")
    }
  }
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
      getFilter(type).forEach { f in
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
  
  func toggleFilter(filter: String, type: SearchFilterType) {
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
  
  
}
