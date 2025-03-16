//
//  JiziHistoryHelper.swift
//  iOSYanzqShufa
//
//  Created by lulixue on 2025/3/16.
//
import CoreData
import Foundation


extension JiziHistory {
  func toSingle() -> BeitieSingle {
    let puzzle = try! JSONDecoder().decode(PuzzleItem.self, from: self.selected!.utf8Data)
    if puzzle.thumbnailUrl.contains("http") {
      guard let single = BeitieDbHelper.shared.getSingleById(puzzle.id) else { return puzzle.char.first().printCharSingle() }
      single.vip = single.work.vip
      single.orgUrl = puzzle.url
      single.orgThumbnailUrl = puzzle.thumbnailUrl
      single.workId = PreviewHelper.RECENT_WORK_ID
      return single
    }
    return puzzle.char.first().printCharSingle()
  }
}

class JiziHistoryHelper {
  static let shared = JiziHistoryHelper()
  
  private lazy var managedContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  
  var history = [String: List<JiziHistory>]()
  
  func insertItem(_ puzzle: PuzzleItem, _ logId: String) {
    var newAll = [JiziHistory]()
    do {
      let json = try JSONEncoder().encode(puzzle).utf8String
      if let it = history[puzzle.char] {
        if let first = it.first(where: { $0.selected == json }) {
          first.time = Date()
          try managedContext.save()
          return
        }
        it.filter { $0.logId == logId }.forEach { log in
          managedContext.delete(log)
        }
        newAll.addAll(it.filter({ $0.logId != logId }))
      }
      let newHistory = JiziHistory(context: managedContext)
      newHistory.c = puzzle.char
      newHistory.logId = logId
      newHistory.selected = json
      newHistory.time = Date()
      managedContext.insert(newHistory)
      newAll.add(newHistory)
      history[puzzle.char] = newAll.sortedByDescending(mapper: { $0.time! })
      try managedContext.save()
    } catch {
      
    }
  }
  
  func searchChar(_ char: Char) -> List<JiziHistory> {
    var result = history[char.toString()] ?? []
    if !history.containsKey(char.toString()) {
      let all = doSearchChar(char)
      history[char.toString()] = all
      result.addAll(all)
    }
    if (result.size > 3) {
      return Array(result[0..<3])
    } else {
      return result
    }
  }
  
  private func doSearchChar(_ char: Char) -> List<JiziHistory> {
    
    let fetchRequest = JiziHistory.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "c = '%@'", char.toString())
    do {
      let result = try managedContext.fetch(fetchRequest)
      let sorted = result.sortedByDescending(mapper: { $0.time! })
      return sorted.map { $0 }
    } catch {
      print("Failed")
    }
    return []
  }
  
}
