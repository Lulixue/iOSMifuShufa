//
//  ChineseDbHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/27.
//
import SQLite
import Foundation

 
class ChineseChar: Decodable {
  var id: Int = 0
  var unicode: String? = nil
  var character: String = ""
  var radical: String? = nil
  var structure: String = ""
  var strokeCount: Int = 0
  var strokes: String? = nil
  var components: String? = nil
  var mainComponents: String? = nil
  var monogram: Int = 0
  var checked: Int = 0
  var lastUpdate: String? = nil
  var examples: String? = nil
}

extension Char {
  var utf8Code: String {
    for codeUnit in self.unicodeScalars {
      return String(format: "%04X", codeUnit.value)
    }
    return ""
  }
  
}

class ChineseDbHelper {
  static let dao = ChineseDbHelper()
  private let DB_NAME = "chinese.db"
  
  private lazy var databaseFile: URL = {
    let dbUrl = ResourceHelper.dataDir?.appendingPathComponent(self.DB_NAME)
    if dbUrl?.path.contains("Preview") == true {
      return Bundle.main.url(forResource: "chinese", withExtension:"db")!
    }
    return dbUrl!
  }()
  
  lazy var db: Connection = {
    do {
      let connection = try Connection(self.databaseFile.path)
      return connection
    } catch {
      fatalError("error")
    }
  }()
  private let charTable = Table("ChineseChar")
  private let unicodeExp = SQLite.Expression<String>("unicode")
  
//  @Query("select * from ChineseChar where unicode = :unicode")
  func getChineseChar(_ unicode: String) -> ChineseChar? {
    guard let row = try? db.prepare(charTable.filter(unicodeExp == unicode)).first else { return nil }
    return try? ChineseChar(from: row.decoder())
  }
}
