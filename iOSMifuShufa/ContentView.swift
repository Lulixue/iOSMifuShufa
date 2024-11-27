//
//  ContentView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/7/7.
//

import SwiftUI
import CoreData
import DeviceKit

struct ContentView: View {
  @StateObject var homeViewModel = HomeViewModel()
  @StateObject var navigationVM = NavigationViewModel()
  @State private var selection = 0
  
  var tabView: some View {
    TabView(selection: $selection) {
      HomePage(viewModel: homeViewModel)
        .tabItem {
          Label("title_home".localized, systemImage: "magnifyingglass")
        }.tag(0)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.background, for: .tabBar)
      
      BeitiePage()
        .tabItem {
          if selection == 1 {
            
            if #available(iOS 18, *) {
              Image(systemName: "photo.on.rectangle.angled.fill").environment(\.symbolVariants, .none)
            } else {
              if Device.current.isPad {
                Image("image_filter_fill").renderingMode(.template)
              } else {
                Image(systemName: "photo.fill.on.rectangle.fill").environment(\.symbolVariants, .none)
              }
            }
          } else {
            Image("image_filter").renderingMode(.template)
          }
          Text("title_beitie".localized)
        }.tag(1)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.background, for: .tabBar)
      
      JiziPage()
        .tabItem {
          Label("title_jizi".localized, systemImage: selection == 2 ? "plus.square.fill.on.square.fill" : "plus.square.on.square")
            .environment(\.symbolVariants, .none)
        }.tag(2)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.background, for: .tabBar)
      
      ArticlePage()
        .tabItem {
          Image(systemName: selection == 3 ? "checkmark.circle.fill" : "checkmark.circle")
            .renderingMode(.template)
            .resizable()
            .environment(\.symbolVariants, .none)
          Text("title_article".localized)
        }.tag(3)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.background, for: .tabBar)
      
      DashboardPage()
        .tabItem {
          Label("title_dashboard".localized, systemImage: selection == 4 ? "info.circle.fill" : "info.circle")
            .environment(\.symbolVariants, .none)
        }.tag(4)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.background, for: .tabBar)
      
    }.modifier(WorkDestinationModifier(naviVM: navigationVM))
      .modifier(WorkIntroDestinationModifier(naviVM: navigationVM))
      .modifier(SingleDestinationModifier(naviVM: navigationVM)).environmentObject(navigationVM)
  }
  
  var body: some View {
    NavigationStack {
        tabView
        .navigationBarHidden(true)
        .onAppear {
          if Settings.config == nil {
            _ = ConstraintHelper.shared
            Task {
              NetworkHelper.syncConfig { it in
                DispatchQueue.main.async {
                  if it.hasUpdate() {
                    it.showUpdateDialog(homeViewModel)
                  }
                }
              }
            }
          }
        }
    }
  }
}

#Preview {
    ContentView().environmentObject(NetworkMonitor())
}

struct TabBarAccessor: UIViewControllerRepresentable {
  var callback: (UITabBar) -> Void
  private let proxyController = ViewController()
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<TabBarAccessor>) ->
  UIViewController {
    proxyController.callback = callback
    return proxyController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<TabBarAccessor>) {
  }
  
  typealias UIViewControllerType = UIViewController
  
  private class ViewController: UIViewController {
    var callback: (UITabBar) -> Void = { _ in }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      if let tabBar = self.tabBarController {
        self.callback(tabBar.tabBar)
      }
    }
  }
}
