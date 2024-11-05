//
//  ContentView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/7/7.
//

import SwiftUI
import CoreData

struct ContentView: View {
  @StateObject var homeViewModel = HomeViewModel()
  @State private var selection = 0
  var body: some View {
    NavigationStack {
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
        
      }
    }
  }
}

#Preview {
    ContentView()
}
