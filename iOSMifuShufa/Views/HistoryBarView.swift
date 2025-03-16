//
//  HistoryBarView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import SwiftUI
import UIKit
import Foundation
import CoreData

enum SearchPage: String {
  case Search
  case Jizi
}

extension Array where Element : Equatable {
  mutating func removeItem(_ item: Element) {
    if let index = self.firstIndex(of: item) {
      remove(at: index)
    }
  }
}

class HistoryViewModel : BaseObservableObject {
  static var shared = HistoryViewModel()
  @Published var allSearchLogs = [SearchPage: List<SearchLog>]()
  
  func getSearchLogs(_ page: SearchPage) -> [SearchLog] {
    return allSearchLogs[page] ?? []
  }
  private lazy var managedContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  
  override init() {
    super.init()
    self.initSearchLogs()
  }
  
  func initSearchLogs() {
    let fetchRequest = SearchLog.fetchRequest()
    do {
      let result = try managedContext.fetch(fetchRequest)
      let sorted = result.sorted { a, b in
        a.time! > b.time!
      }
      for data in sorted {
        let page = SearchPage(rawValue: data.page!)!
        self.insertLog(log: data, page: page)
      }
    } catch {
      print("Failed")
    }
  }
  
  func appendLog(_ page: SearchPage, _ text: String, _ extra: String? = nil) -> String {
    return appendHistory(text: text, page: page, extra: extra)
  }
  
  func insertLog(log: SearchLog, page: SearchPage, new: Bool = false) {
    if !allSearchLogs.containsKey(page) {
      allSearchLogs[page] = [log]
    } else if (new) {
      allSearchLogs[page]?.insert(log, at: 0)
    } else {
      allSearchLogs[page]?.append(log)
    }
  }
  
  func deletePageHistory(page: SearchPage) {
    do {
      guard let logs = allSearchLogs[page] else { return }
      for log in logs  {
        managedContext.delete(log)
      }
      DispatchQueue.main.async {
        self.allSearchLogs.removeValue(forKey: page)
      }
      try managedContext.save()
    } catch {
      print("failed deleteHistory \(error)")
    }
  }
  
  func deleteHistory(log: SearchLog, page: SearchPage) {
    do {
      DispatchQueue.main.async {
        self.allSearchLogs[page]?.remove(at: self.allSearchLogs[page]!.indexOf(log))
      }
      managedContext.delete(log)
      try managedContext.save()
    } catch {
      print("failed deleteHistory \(error)")
    }
  }
  
  func hasSameBefore(text: String, page: SearchPage, extra: String?) -> SearchLog? {
    guard let logs = allSearchLogs[page] else { return nil }
    return logs.first(where: { log in
      log.text == text
    })
  }
  
  func refreshLog(log: SearchLog, page: SearchPage, extra: String?) {
    guard var logs = allSearchLogs[page] else { return }
    logs.removeItem(log)
    log.time = Date()
    log.extra = extra
    logs.insert(log, at: 0)
    allSearchLogs[page] = logs
    do {
      try managedContext.save()
    } catch {
      print("failed refreshLog \(error)")
    }
  }
  
  func appendHistory(text: String, page: SearchPage, extra: String?=nil) -> String {
    if let previous = hasSameBefore(text: text, page: page, extra: extra) {
      DispatchQueue.main.async {
        self.refreshLog(log: previous, page: page, extra: extra)
      }
      return previous.id.toString()
    }
    let slog = SearchLog(context: managedContext)
    slog.text = text
    slog.page = page.rawValue
    slog.time = Date()
    slog.extra = extra
    DispatchQueue.main.async {
      self.insertLog(log: slog, page: page, new: true)
    }
    do {
      try managedContext.save()
    } catch let error as NSError {
      print("Could not save. \(error), \(error.userInfo)")
    }
    return slog.id.toString()
  }
}

extension ObjectIdentifier {
  func toString() -> String {
    UInt(bitPattern: self).description
  }
}


struct HistoryBarView: View {
  @StateObject var viewModel: HistoryViewModel = HistoryViewModel.shared
  let page: SearchPage
  @Binding var showDeleteAlert: Bool
  @State var textHeight: CGFloat = 0
  let onClearLogs: () -> Void
  let onSelectLog: (SearchLog) -> Void
  private let iconSize: CGFloat = 14
  var body: some View {
    if viewModel.getSearchLogs(page).isNotEmpty() {
      content
    } else {
      HStack { }
    }
  }
  var content: some View {
    HStack(alignment: .center, spacing: 0) {
      Image(systemName: "clock")
        .resizable()
        .scaledToFit()
        .foregroundColor(Colors.searchHeader.swiftColor)
        .frame(width: iconSize, height: iconSize)
        .padding(.trailing, 5)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          let logs: [SearchLog] = viewModel.getSearchLogs(page)
          ForEach(0..<logs.size, id:\.self) { i in
            let log = logs[i]
            HStack {
              Button {
                onSelectLog(log)
              } label: {
                Text(log.text!).font(.system(size: 13))
                  .foregroundColor(Colors.darkSlateGray.swiftColor)
                  .padding(.horizontal, 3)
                  .padding(.vertical, 2)
              }.buttonStyle(.plain)
              .background(
                GeometryReader { p in
                  Color.clear
                    .onAppear {
                      if textHeight == 0 {
                        textHeight = p.size.height
                      }
                    }
                }
              )
            }
            if log != logs.last {
              Divider()
                .background(UIColor.systemGray3.swiftColor)
                .padding(.vertical, 5)
                .frame(width: 1, height: textHeight)
                .padding(.horizontal, 2)
            }
          }
          Spacer()
        }
      }
      Button {
        showDeleteAlert = true
      } label: {
        Image(systemName: "trash")
          .resizable()
          .scaledToFit()
          .foregroundColor(Colors.searchHeader.swiftColor)
          .frame(width: iconSize, height: iconSize)
      }.buttonStyle(.plain)
      .padding(.leading, 5)
      .alert(isPresented: $showDeleteAlert) {
        getClearAlert()
      }
    }.padding(.horizontal, 2)
      .padding(.vertical, 3)
  }
  
  func getClearAlert() -> Alert {
    Alert(
      title: Text("confirm_empty_logs".localized),
      primaryButton: .cancel(Text("cancel".localized)),
      secondaryButton: .destructive(Text("confirm".localized)) {
        viewModel.deletePageHistory(page: page)
        onClearLogs()
      }
    )
  }
}
