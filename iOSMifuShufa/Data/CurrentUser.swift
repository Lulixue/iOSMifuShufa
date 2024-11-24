//
//  CurrentUser.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/4.
//

import UIKit
import SwiftUI

let UNKNOWN = "未知"

class PoemUser: Decodable
{
  var ID: String? = ""
  var UID: String? = ""
  var Source: String? = ""
  var Username: String? = ""
  var RegisterTime: String? = ""
  
  var LastLogin: String? = ""
  var Vip: Boolean = false
  var VipExpired: String? = ""
  
  var Sex: String? = ""
  var City: String? = ""
  var Province: String? = ""
  var Country: String? = ""
  
  var AvatarUrl: String? = ""
  
  var ResponseJson: String? = ""
  var Ip: String? = ""
  var Score: Int = 0
  var PurchaseOrderID: String? = ""
  var OrderNotified: Boolean = false
  var PurchaseOrderName: String? = ""
  var PurchaseOrderPrice: CGFloat = 0
  var Transferred: Boolean = false
  var DeviceID: String? = ""
  var AppID: String? = ""
  var LogInDevices: String? = ""
  
  static var DEFAULT_VIP_STATUS: String {
    "未开通".orCht("未開通")
  }
  
  enum CodingKeys: CodingKey {
    case ID
    case UID
    case Source
    case Username
    case RegisterTime
    case LastLogin
    case Vip
    case VipExpired
    case Sex
    case City
    case Province
    case Country
    case AvatarUrl
    case ResponseJson
    case Ip
    case Score
    case PurchaseOrderID
    case OrderNotified
    case PurchaseOrderName
    case PurchaseOrderPrice
    case Transferred
    case DeviceID
    case AppID
    case LogInDevices
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.ID = try container.decodeIfPresent(String.self, forKey: .ID)
    self.UID = try container.decodeIfPresent(String.self, forKey: .UID)
    self.Source = try container.decodeIfPresent(String.self, forKey: .Source)
    self.Username = try container.decodeIfPresent(String.self, forKey: .Username)
    self.RegisterTime = try container.decodeIfPresent(String.self, forKey: .RegisterTime)
    self.LastLogin = try container.decodeIfPresent(String.self, forKey: .LastLogin)
    self.Vip = try container.decode(Boolean.self, forKey: .Vip)
    self.VipExpired = try container.decodeIfPresent(String.self, forKey: .VipExpired)
    self.Sex = try container.decodeIfPresent(String.self, forKey: .Sex)
    self.City = try container.decodeIfPresent(String.self, forKey: .City)
    self.Province = try container.decodeIfPresent(String.self, forKey: .Province)
    self.Country = try container.decodeIfPresent(String.self, forKey: .Country)
    self.AvatarUrl = try container.decodeIfPresent(String.self, forKey: .AvatarUrl)
    self.ResponseJson = try container.decodeIfPresent(String.self, forKey: .ResponseJson)
    self.Ip = try container.decodeIfPresent(String.self, forKey: .Ip)
    self.Score = try container.decode(Int.self, forKey: .Score)
    self.PurchaseOrderID = try container.decodeIfPresent(String.self, forKey: .PurchaseOrderID)
    self.OrderNotified = try container.decode(Boolean.self, forKey: .OrderNotified)
    self.PurchaseOrderName = try container.decodeIfPresent(String.self, forKey: .PurchaseOrderName)
    self.PurchaseOrderPrice = try container.decode(CGFloat.self, forKey: .PurchaseOrderPrice)
    self.Transferred = try container.decode(Boolean.self, forKey: .Transferred)
    self.DeviceID = try container.decodeIfPresent(String.self, forKey: .DeviceID)
    self.AppID = try container.decodeIfPresent(String.self, forKey: .AppID)
    self.LogInDevices = try container.decodeIfPresent(String.self, forKey: .LogInDevices)
  }
  
  func getVipStatus() -> String {
    if !Vip {
      if VipExpired != nil {
        return "已过期".orCht("已過期")
      }
      return Self.DEFAULT_VIP_STATUS
    }
    return "已开通".orCht("已開通")
  }
}


enum LoginSource: String {
  case Apple, Phone, Tmp, Unknown
  
  var chinese: String {
    switch self {
    case .Apple: return "苹果账号".orCht("蘋果賬號")
    case .Phone: return "手机账号".orCht("手機賬號")
    case .Tmp: return "当前设备".orCht("當前設備")
    case .Unknown: return "未知账号".orCht("未知賬號")
    }
  }
}

enum UserItem: String {
  case login, loginTime, name, id, phoneNumber, loginSource, vipExpired, isVip
  
  var key: String {
    "\(rawValue)UserSettingsKey"
  }
  
  var stringValue: String {
    get{
      return Settings.mmkv.getString(key, "")
    }
    set {
      Settings.mmkv.putString(key, newValue)
    }
  }
  
  var boolValue: Boolean {
    get {
      return Settings.mmkv.getBoolean(key, false)
    }
    set {
      Settings.mmkv.putBoolean(key, newValue)
    }
  }
  
  static var source: LoginSource {
    LoginSource(rawValue: loginSource.stringValue) ?? .Unknown
  }
  
  static var hasUser: Boolean {
    id.stringValue.isNotEmpty()
  }
   
  static var loginExpired: Boolean {
    let sdf = Utils.loginFormater
    let converted = convertServerTime(UserItem.loginTime.stringValue)
    guard let last = sdf.date(from: converted) else { return false }
    let interval = DateInterval(start: last, end: Date())
    let span = interval.duration
    return Int(span / (1000 * 24 * 60 * 60)) > 30
  }
}

private var NO_USER_NAME: String {
  "click_to_login".localized
}

func convertServerTime(_ time: String) -> String {
  var replaced: String = time.replacing("T", with: " ")
  if let pos = replaced.firstIndex(of: ".") {
    replaced = String(replaced[replaced.startIndex..<pos])
  }
  return replaced
}

class UserViewModel: AlertViewModel {
  
  static let STATUS_FONT = UIFont.systemFont(ofSize: 19)
  static let NEED_LOGIN: AttributedString = {
    let txt = "当前未&nbsp;<font color=\"#0000FF\"><u><big>登录</big></u></font>".orCht("當前未&nbsp;<font color=\"#0000FF\"><u><big>登録</big></u></font>")
    let html = txt.toHtmlString(font: STATUS_FONT)!
    return try! AttributedString(html, including: \.uiKit)
  }()
  @Published var language = Settings.languageVersion
  @Published var poemUser: PoemUser? = nil
  
  @Published var userName: String = NO_USER_NAME {
    didSet {
      self.nameItem.stringValue = userName
    }
  }
  @Published var userType: String = ""
  @Published var userLogin: Bool = false {
    didSet {
      self.loginItem.boolValue = userLogin
    }
  }
  @Published var userVipStatus: String = ""
  @Published var updateStatus: String = ""
  @Published var userId: String = "" {
    didSet {
      self.idItem.stringValue = userId
    }
  }
  
  @Published var isVip = UserItem.isVip.boolValue {
    didSet {
      self.isVipItem.boolValue = isVip
    }
  }
  
  private var loginItem = UserItem.login
  private var loginTimeItem = UserItem.loginTime
  private var nameItem = UserItem.name
  private var idItem = UserItem.id
  private var phoneNumberItem = UserItem.phoneNumber
  private var loginSourceItem = UserItem.loginSource
  private var vipExpiredItem = UserItem.vipExpired
  private var isVipItem = UserItem.isVip
  
  var userIsVip: Bool {
    isVip
  }
  
  var isForeverVip: Bool {
    userLogin && isVip && poemUser != nil && poemUser!.VipExpired.isEmptyOrNil
  }
  
  private var loginCounter = 3
  override init() {
    super.init()
    Task {
      if !UserItem.loginExpired {
        let id = UserItem.id.stringValue
        if id.isNotEmpty() {
          self.login(id)
        }
      }
      let _ = Self.NEED_LOGIN
    }
  }
  
  func login(_ id: String, onLogout: @escaping () -> Void = {}) {
    NetworkHelper.syncUser(id: id) { user in
      if user == nil && self.loginCounter > 0 {
        self.loginCounter -= 1
        self.login(id)
      } else if let user = user {
        let id = DEVICE_ID
        let devices = user.LogInDevices
        DispatchQueue.main.async {
          if devices != nil && !devices!.contains(id) {
              self.logout()
              onLogout()
          } else {
            self.updateUser(user)
          }
        }
      }
    }
  }
  
  func updateUser(_ user: PoemUser?) {
    if let user = user {
      loginUser(user)
    } else {
      logout()
    }
  }
  
  var currentStatus: Any {
    if !userLogin {
      return Self.NEED_LOGIN
    } else if !isVip {
      return "非VIP会员".orCht("非VIP會員")
    } else {
      return "已经是VIP会员".orCht("已經是VIP會員")
    }
  }
  
  var currentStatusColor: Color {
    if !userLogin {
      return .clear
    } else if !isVip {
      return .black
    } else {
      return .blue
    }
  }
  
  var timeline: String {
    "时间截至".orCht("時間截至")
  }
  var expiredAt: String {
    "过期时间".orCht("過期時間")
  }
  
  var expiredTime: String? {
    if let expired = poemUser?.VipExpired {
      if userLogin && expired.isNotEmpty() {
        return "\(isVip ? timeline : expiredAt)：\(convertServerTime(expired))"
      }
    } else if isForeverVip {
      return "永 久"
    }
    return nil
  }
  
  private func loginUser(_ user: PoemUser) {
    loginSourceItem.stringValue = user.Source ?? LoginSource.Apple.rawValue
    poemUser = user
    userName = user.Username ?? UNKNOWN
    userType = UserItem.source.chinese
    userLogin = true
    userId = user.ID ?? UNKNOWN
    isVip = user.Vip
    userVipStatus = poemUser?.getVipStatus() ?? PoemUser.DEFAULT_VIP_STATUS
    if UserItem.source == .Phone {
      phoneNumberItem.stringValue = user.UID?.replacing("86", with: "") ?? ""
    } else {
      phoneNumberItem.stringValue = ""
    }
    loginTimeItem.stringValue = Utils.currentTime()
  }
  
  
  func logout() {
    poemUser = nil
    userLogin = false
    isVip = false
    userName = NO_USER_NAME
    userId = ""
    userVipStatus = PoemUser.DEFAULT_VIP_STATUS
  }
  
  static let shared = UserViewModel()
  
  
  func updateUserName(_ newName: String, onResult: @escaping (Bool) -> Void) {
    NetworkHelper.changeUserName(newName) { user in
      if user != nil {
        self.updateUser(user)
      }
      onResult(user?.Username == newName)
    }
  }
  
  
  var loginCanIgnoreCode: Boolean {
    let sdf = Utils.loginFormater
    let converted = convertServerTime(UserItem.loginTime.stringValue)
    guard let last = sdf.date(from: converted) else { return false }
    let interval = DateInterval(start: last, end: Date())
    let span = interval.duration
    return span < (3 * 24 * 60 * 60)
  }
  
}

let CurrentUser = UserViewModel.shared
