//
//  iOSMifuShufaApp.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/7/7.
//

import SwiftUI
import Foundation
import Network

class NetworkMonitor: BaseObservableObject {
  private let networkMonitor = NWPathMonitor()
  private let workerQueue = DispatchQueue(label: "Monitor")
  var isConnected = false
  
  override init() {
    super.init()
    networkMonitor.pathUpdateHandler = { path in
      self.isConnected = path.status == .satisfied
      Task {
        await MainActor.run {
          self.objectWillChange.send()
        }
      }
    }
    networkMonitor.start(queue: workerQueue)
  }
}

@main
struct iOSMifuShufaApp: App {
  let persistenceController = PersistenceController.shared
  
  init() {
    Settings.syncLocale()
  }
  
  var body: some Scene {
    WindowGroup {
      SplashView().environmentObject(NetworkMonitor())
    }
  }
}
