//
//  SettingsView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/13.
//

enum SettingsItem: String, CaseIterable {
  case Home
  case SingleRotate
  case Beitie
  case Language
  case Jizi
  
  var key: String { "\(self)SettingsKey" }
  
  static var languageOption: ChineseVersion {
    get { ChineseVersion(rawValue: Settings.getString(Language.key, ChineseVersion.Unspecified.toString()))! }
    set {
      Settings.putString(Language.key, newValue.toString())
    }
  }
    
  static var jiziCandidateEnable: Boolean {
    get { Settings.getBoolean(Jizi.key, true) }
    set {
      Settings.putBoolean(Jizi.key, newValue)
    }
  }
}
