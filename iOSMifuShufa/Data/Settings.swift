//
//  Settings.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import MMKV

extension Settings {
  static func getBoolean(_ key: String, _ defValue: Bool) -> Bool {
    return Self.mmkv?.getBoolean(key, defValue) ?? defValue
  }
  
  static func putBoolean(_ key: String, _ value: Bool) {
    Self.mmkv?.putBoolean(key, value)
  }
  
  static func getString(_ key: String, _ defValue: String) -> String {
    return Self.mmkv?.getString(key, defValue) ?? defValue
  }
  
  static func getInt(_ key: String, _ defValue: Int) -> Int {
    return Self.mmkv?.getInt(key, defValue) ?? defValue
  }
  static func putInt(_ key: String, _ value: Int) {
    Self.mmkv?.putInt(key, value)
  }
  
  static func getInt64(_ key: String, _ defValue: Int64) -> Int64 {
    return Self.mmkv?.getInt64(key, defValue) ?? defValue
  }
  
  static func putInt64(_ key: String, _ value: Int64) {
    Self.mmkv?.putInt64(key, value)
  }
  static func putString(_ key: String, _ value: String) {
    Self.mmkv?.putString(key, value)
  }
}

extension MMKV {
  func getBoolean(_ key: String, _ defValue: Bool) -> Bool {
    self.bool(forKey: key, defaultValue: defValue)
  }
  
  func putBoolean(_ key: String, _ value: Bool) {
    self.set(value, forKey: key)
  }
  
  func getString(_ key: String, _ defValue: String) -> String {
    self.string(forKey: key, defaultValue: defValue)!
  }
  
  func getInt(_ key: String, _ defValue: Int) -> Int {
    return Int(self.int32(forKey: key, defaultValue: Int32(defValue)))
  }
  func putInt(_ key: String, _ value: Int) {
    self.set(Int32(value), forKey: key)
  }
  
  func getInt64(_ key: String, _ defValue: Int64) -> Int64 {
    return (self.int64(forKey: key, defaultValue: (defValue)))
  }
  
  func putInt64(_ key: String, _ value: Int64) {
    self.set(Int64(value), forKey: key)
  }
  func putString(_ key: String, _ value: String) {
    set(value, forKey: key)
  }
}


class Settings {
  static let shared = Settings()
  
  private static let KEY_RESOURCE_MD5 = "resourceMd5"
  private static let KEY_LANGUAGE = "language"
  private static let KEY_PRIVACY_AGREED = "privacyAgreed"
  private static let KEY_APP_RESOURCE_MD5 = "appResourceMd5"
  private static let KEY_SHOW_EXAMPLE = "showExample"
  private static let KEY_SHICI_SOUND_TYPE = "shiciSoundType"
  private static let KEY_LAST_SYSTEM_LANG = "lastSystemLanguage"
  private static let KEY_DEVICE_ID = "deviceId"
  private static let KEY_SHOW_AD_IOS = "showAdiOS"
  private static let KEY_IS_VIP = "lastUserIsVip"
#if DEBUG
  private static var defaultMMKV = {
    MMKV.initialize(rootDir: nil)
    return MMKV.default()
  }()
  static var mmkv: MMKV! = defaultMMKV
#else
  static var mmkv: MMKV! = {
    MMKV.initialize(rootDir: nil)
    return MMKV.default()
  }()
#endif
  
  
  static var deviceId: String {
    var value = mmkv.getString(KEY_DEVICE_ID, "")
    if value.isEmpty {
      value = UUID().uuidString
      mmkv.putString(KEY_DEVICE_ID, value)
    }
    return value
  }
  static var isVip: Bool {
    get {
      mmkv.getBoolean(KEY_IS_VIP, false)
    }
    set {
      mmkv.putBoolean(KEY_IS_VIP, newValue)
    }
  }
  
  static var showAdiOS: Bool {
    get {
      mmkv.getBoolean(KEY_SHOW_AD_IOS, false)
    }
    set {
      mmkv.putBoolean(KEY_SHOW_AD_IOS, newValue)
    }
  }
  
  static var config: AzureConfig! {
    didSet {
      showAdiOS = config.showAdiOS
    }
  }
  static var resourceUpdated = false
  
  
  private static var _last_system_lang: String? {
    get { return mmkv.string(forKey: KEY_LAST_SYSTEM_LANG) }
    set { mmkv.set(newValue ?? "", forKey: KEY_LAST_SYSTEM_LANG) }
  }
  static var _languageVersion: ChineseVersion {
    get {
      let value = mmkv.string(forKey: KEY_LANGUAGE, defaultValue: ChineseVersion.Unspecified.rawValue)!
      return ChineseVersion(rawValue: value) ?? ChineseVersion.Unspecified
    }
    set {
      mmkv.set(newValue.rawValue, forKey: KEY_LANGUAGE)
    }
  }
  
  static var languageVersion: ChineseVersion = ChineseVersion.Traditional
  
  static var langChs: Bool {
    languageVersion == ChineseVersion.Simplified
  }
  
  static var currentLocale: String = "zh-hans-cn"
  static var settingsUpdated = false
  static var resourceMd5: String  {
    get { return mmkv.string(forKey: KEY_RESOURCE_MD5, defaultValue: "")! }
    set {
      mmkv.set(newValue, forKey: KEY_RESOURCE_MD5)
    }
  }
  
  static func initSettings() {
    let locale = Locale.current.identifier.lowercased()
    let option = _languageVersion
    var chtLang = "zh-hant-tw"
    if option == ChineseVersion.Unspecified {
      if locale.contains("hant") {
        languageVersion = ChineseVersion.Traditional
        chtLang = locale
      } else {
        languageVersion = ChineseVersion.Simplified
      }
    } else {
      languageVersion = option
      if _last_system_lang != locale {
        _last_system_lang = locale
      }
    }
    let lang = languageVersion == ChineseVersion.Simplified ? "zh-hans-cn" : chtLang
    currentLocale = lang
    UserDefaults.standard.set([lang], forKey: "AppleLanguages")
    UserDefaults.standard.synchronize()
  }
}
