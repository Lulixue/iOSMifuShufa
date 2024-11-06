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
  @Published var radicals = [String]()
  @Published var structures = [String]()
  @Published var strokes = [String]()
  
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
    switch type {
    case .Structure:
      structures.size
    case .Radical:
      radicals.size
    case .Stroke:
      strokes.size
    }
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
