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
    let single = BeitieDbHelper.shared.getSingleById(puzzle.id) ?? puzzle.char.first().printCharSingle()
    single.vip = single.work.vip
    single.orgUrl = puzzle.url
    single.orgThumbnailUrl = puzzle.thumbnailUrl
    single.workId = PreviewHelper.RECENT_WORK_ID
    debugPrint(puzzle.char, puzzle.thumbnailUrl)
    return single
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
      let it = getHistory(puzzle.char.first())
      if it.isNotEmpty() {
        let puzzles = it.map { try! JSONDecoder().decode(PuzzleItem.self, from: $0.selected!.utf8Data) }
        let index = puzzles.indexOf(puzzle)
        if index >= 0 {
          it[index].time = Date()
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
      history[puzzle.char] = newAll
      try managedContext.save()
    } catch {
      
    }
  }
  
  private func getHistory(_ char: Char) -> List<JiziHistory> {
    var result = history[char.toString()] ?? []
    if !history.containsKey(char.toString()) {
      let all = doSearchChar(char)
      history[char.toString()] = all
      result.addAll(all)
    }
    return result.sortedByDescending(mapper: { $0.time! })
  }
  
  func searchChar(_ char: Char) -> List<JiziHistory> {
    let result = getHistory(char)
    if (result.size > 3) {
      return Array(result[0..<3])
    } else {
      return result
    }
  }
  
  private func doSearchChar(_ char: Char) -> List<JiziHistory> {
    let fetchRequest = JiziHistory.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "c = %@", char.toString())
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
