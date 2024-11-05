//
//  HomeViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//


import SwiftUI

class HomeViewModel : AlertViewModel {
  @Published var searchByPart = false
  @Published var text = ""
  @Published var focused = false
  @Published var showHistoryBar = false
  @Published var showDeleteAlert: Bool = false
  private let page = SearchPage.Search
  @Published var searchResults = [Any]()
  
  
  var historyBinding: Binding<[SearchLog]> {
    Binding {
      self.logs
    } set: { _ in
      
    }
  }
  
  func updateHistoryBarVisible() {
    showHistoryBar = focused && logs.isNotEmpty()
  }
  
  var logs: [SearchLog] {
    SearchViewModel.shared.getSearchLogs(page)
  }
}
