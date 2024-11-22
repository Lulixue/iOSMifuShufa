//
//  Config.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import Collections
import Foundation

public typealias ArrayList = Array
public typealias List = Array
public typealias Boolean = Bool
public typealias Char = Character
public typealias HashMap = Dictionary
public typealias Map = Dictionary
public typealias HashSet = Set
public typealias LinkedHashMap = OrderedDictionary


class AzureConfig: Codable {
  var iosUpdate: String? = nil
  var iosNewest: String? = nil
  var iosNewestVersionCode: Int? = nil
  var showAdiOS: Bool = false
  var singleWatermark: Boolean = false
  var imageWatermark: Boolean = true
  var puzzleWatermark: Boolean = false
  var defaultShowVipSingle: Boolean = true
  
  enum CodingKeys: CodingKey {
    case iosUpdate
    case iosNewest
    case iosNewestVersionCode
    case showAdiOS
    case singleWatermark
    case imageWatermark
    case puzzleWatermark
    case defaultShowVipSingle
  }
  
  func hasUpdate() -> Bool {
    if let code = iosNewestVersionCode  {
      if let appBuildNo = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as! String) {
        return appBuildNo < code
      }
    }
    return false
  }
  
  func showUpdateDialog(_ alert: AlertViewModel) {
    alert.showFullAlert("发现新版本:".orCht("發現新版本:") + "\(iosNewest ?? "未知")", iosUpdate ?? "",
                        okTitle: "前往应用商店更新".orCht("前往應用商店更新"), okRole: .destructive, ok: {
      Utils.gotoAppStore()
    }, cancelTitle: "cancel".resString)
  }
  required init(from decoder: any Decoder) {
    do {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.iosUpdate = try container.decodeIfPresent(String.self, forKey: .iosUpdate)
      self.iosNewest = try container.decodeIfPresent(String.self, forKey: .iosNewest)
      self.iosNewestVersionCode = try container.decodeIfPresent(Int.self, forKey: .iosNewestVersionCode)
      self.showAdiOS = (try? container.decodeIfPresent(Bool.self, forKey: .showAdiOS)) ?? false
      self.singleWatermark = try container.decode(Boolean.self, forKey: .singleWatermark)
      self.imageWatermark = try container.decode(Boolean.self, forKey: .imageWatermark)
      self.puzzleWatermark = try container.decode(Boolean.self, forKey: .puzzleWatermark)
      self.defaultShowVipSingle = (try? container.decodeIfPresent(Boolean.self, forKey: .defaultShowVipSingle)) ?? true
    } catch {
      
    }
  }
}
