//
//  ConstraintHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/7.
//

import Foundation
import SwiftUI
import Alamofire

enum ConstraintItem: String {
  case SearchFilterCount
  case SearchZiCount
  case JiziZiCount
  case CentroidMiCount
  case CentroidAnalyze
  
  var defCount: Int {
    switch self {
    case .SearchFilterCount: 1
    case .SearchZiCount: 3
    case .JiziZiCount: 14
    case .CentroidMiCount: 3
    case .CentroidAnalyze: 3
    }
  }
  
  var chinese: String {
    switch self {
    case .CentroidAnalyze: "single_analyze".localized
    case .CentroidMiCount: "重心米字格"
    default: "功能"
    }
  }
  
  var topMostConstraint: Int {
    ConstraintHelper.shared.getConstraint(rawValue) ?? defCount
  }
  
  var topMostConstraintMessage: String {
    switch self {
    case .SearchZiCount: "非VIP会员仅支持\(topMostConstraint)个汉字同时搜索，是否开通VIP继续？"
        .orCht("非VIP會員僅支持\(topMostConstraint)個漢字同時搜索，是否開通VIP繼續？")
    case .JiziZiCount: "非VIP用户集字数超出范围(\(topMostConstraint)字)，是否开通VIP继续？"
        .orCht("非VIP用戶集字數超出範圍(\(topMostConstraint)字)，是否開通VIP繼續？")
    case .SearchFilterCount: "非VIP会员仅支持\(topMostConstraint)个过滤器，是否开通VIP继续？"
        .orCht("非VIP會員僅支持\(topMostConstraint)個過濾器，是否開通VIP繼續？")
    default: "VIP功能「\(chinese)」使用次数已超过非VIP单日上限，是否开通VIP继续？"
        .orCht("VIP功能「\(chinese)」使用次數已超過非VIP單日上限，是否開通VIP繼續？")
    }
  }
  
}


let STORAGE_URL = "https://appdatacontainer.blob.core.windows.net"


extension String {
  var urlEncoded: String? {
    return self.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
  }
  
  func split(_ separator: Char) -> [String] {
    return self.split(separator: separator).map { String($0) }
  }
  
}


class ConstraintHelper {
  static let shared = ConstraintHelper()
  static let shiciPreviewKey = "shiciPreviewConstraint"
  private static let PLAY_TEXT_SOUND_NON_VIP_USAGE_COUNT = 3
  private let DAY_FORMAT = {
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "yyyy/MM/dd"
    return dateFormatterGet
  }()
  
  private var MAX_USAGE_COUNT = {
    var this = HashMap<String, Int>()
     
    this[shiciPreviewKey] = 3
     
    return this
  }()
  
  func getConstraint(_ key: String) -> Int? {
    return MAX_USAGE_COUNT[key]
  }
  
  func syncAzure() {
    let url = STORAGE_URL + "/jiyun/config/constraint.json"
    AF.request(url.urlEncoded!).responseDecodable(of: [String: Int].self) { response in
      switch response.result {
      case .success(let result):
        for (k, v) in result {
          self.MAX_USAGE_COUNT[k] = v
        }
      case .failure(let error):
        print(error)
      }
    }
  }
  
  func getCurrentUsageCount() -> HashMap<String, Int> {
    var result = HashMap<String, Int>()
    for (k, _) in MAX_USAGE_COUNT {
      result[k] = getCount(k)
    }
    return result
  }
  
  
  private func getCount(_ value: String) -> Int {
    let today = DAY_FORMAT.string(from: Date())
    let parts = value.split(",")
    if (today != parts[0]) {
      return 0
    }
    return Int(parts[1]) ?? 0
  }
  
  
  private func getTodayUsageCount(_ key: String) -> Int {
    let value = Settings.mmkv.getString(key, "")
    if (value.isEmpty()) {
      return 0
    }
    return getCount(value)
  }
  
  func getTodayUsage(_ count: Int) -> String {
    let today = DAY_FORMAT.format(Date())
    return "\(today),\(count)"
  }
  
  func increaseUsageCount(_ key: String) {
    if (CurrentUser.isVip) {
      return
    }
    let count = getTodayUsageCount(key)
    Settings.mmkv.putString(key, getTodayUsage(count+1))
  }
  
  func reachedMaxUsageCount(_ key: String) -> Boolean {
    if (CurrentUser.isVip) {
      return false
    }
    return MAX_USAGE_COUNT[key]! <= getTodayUsageCount(key)
  }
}

extension DateFormatter {
  func format(_ date: Date) -> String {
    self.string(from: date)
  }
}
