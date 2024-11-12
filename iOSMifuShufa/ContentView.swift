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
          Label("title_beitie".localized, systemImage: "photo")
        }.tag(1)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.background, for: .tabBar)
      
      JiziPage()
        .tabItem {
          Label("title_jizi".localized, systemImage: "photo")
        }.tag(2)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.background, for: .tabBar)
    }.navigationDestination(isPresented: $navigationVM.gotoWorkView) {
      WorkView(viewModel: navigationVM.workVM!)
    }
    .navigationDestination(isPresented: $navigationVM.gotoWorkIntroView) {
      WorkIntroView(viewModel: navigationVM.introWorkVM!)
    }.navigationDestination(isPresented: $navigationVM.gotoSingleView) {
      SinglesView(viewModel: navigationVM.singleViewModel!)
    }.environmentObject(navigationVM)
  }
  
  var body: some View {
    NavigationStack {
        tabView
        .navigationBarHidden(true)
    }
  }
}

#Preview {
    ContentView()
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
