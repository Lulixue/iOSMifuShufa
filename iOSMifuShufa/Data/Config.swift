//
//  Config.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

public typealias ArrayList = Array
public typealias List = Array
public typealias Boolean = Bool
public typealias Char = Character
public typealias HashMap = Dictionary
public typealias Map = Dictionary
public typealias HashSet = Set
public typealias LinkedHashMap = Dictionary


class AzureConfig: Codable {
  var iosUpdate: String? = nil
  var iosNewest: String? = nil
  var iosNewestVersionCode: Int? = nil
  var cloudDataNonVipLengthKB: Int? = 512
  var showAdiOS: Bool = false
  var singleWatermark: Boolean = false
  var imageWatermark: Boolean = true
  var puzzleWatermark: Boolean = false
  var defaultShowVipSingle: Boolean = true
  
  enum CodingKeys: CodingKey {
    case iosUpdate
    case iosNewest
    case iosNewestVersionCode
    case cloudDataNonVipLengthKB
    case showAdiOS
    case singleWatermark
    case imageWatermark
    case puzzleWatermark
    case defaultShowVipSingle
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.iosUpdate = try container.decodeIfPresent(String.self, forKey: .iosUpdate)
    self.iosNewest = try container.decodeIfPresent(String.self, forKey: .iosNewest)
    self.iosNewestVersionCode = try container.decodeIfPresent(Int.self, forKey: .iosNewestVersionCode)
    self.cloudDataNonVipLengthKB = try container.decodeIfPresent(Int.self, forKey: .cloudDataNonVipLengthKB)
    self.showAdiOS = try container.decode(Bool.self, forKey: .showAdiOS)
    self.singleWatermark = try container.decode(Boolean.self, forKey: .singleWatermark)
    self.imageWatermark = try container.decode(Boolean.self, forKey: .imageWatermark)
    self.puzzleWatermark = try container.decode(Boolean.self, forKey: .puzzleWatermark)
    self.defaultShowVipSingle = try container.decode(Boolean.self, forKey: .defaultShowVipSingle)
  }
}
