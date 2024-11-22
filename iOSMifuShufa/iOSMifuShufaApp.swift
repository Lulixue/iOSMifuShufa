//
//  iOSMifuShufaApp.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/7/7.
//

import SwiftUI

@main
struct iOSMifuShufaApp: App {
  let persistenceController = PersistenceController.shared
  
  init() {
    Settings.syncLocale()
  }
  
  var body: some Scene {
    WindowGroup {
      SplashView()
    }
  }
}
