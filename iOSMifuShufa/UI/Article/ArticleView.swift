//
//  ArticleView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/13.
//

import SwiftUI


struct ArticlePage : View {
  @StateObject var viewModel: ArticleViewModel = ArticleViewModel.shared
  
  @State private var proxy: ScrollViewProxy? = nil
  @StateObject var naviVM = NavigationViewModel()
  
  var sections: [ArticleSection] {
    viewModel.sections
  }
  
  var sectionView: some View {
    let sections = sections
    
    return LazyVStack(alignment: .leading, spacing: 0) {
      ForEach(0..<sections.size, id: \.self) { i in
        let s = sections[i]
        Section {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<s.articles.count, id: \.self) { j in
              let article = s.articles[j]
              let clicked = viewModel.clicked.contains(article.title)
              Button {
                naviVM.gotoWeb(article)
                viewModel.clicked.add(article.title)
              } label: {
                VStack {
                  Text(article.title)
                    .font(.system(size: 18)).underline().foregroundStyle(clicked ? Color.darkSlateBlue : UIColor.blue.swiftColor).padding(.horizontal, 3).padding(.vertical, 4)
                }.background(.white)
              }.buttonStyle(BgClickableButton())
            }
          }
        } header: {
          Text(s.htmlSection).padding(.top, 10)
            .padding(.bottom, 2)
        }.tag(i)
      }
    }.padding(.horizontal, 10).padding(.top, 5).padding(.bottom, 10)
  }
  var sideMenu: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(0..<sections.size, id: \.self) { i in
        Button {
          proxy?.scrollTo(i, anchor: .top)
          DispatchQueue.main.async {
            sideVM.sideMenuRightPanel.toggle()
          }
        } label: {
          HStack {
            Text(sections[i].menuSection).padding(.vertical, 6).padding(.leading, 10)
            Spacer()
          }.background(.white)
        }.buttonStyle(BgClickableButton())
        if i != sections.lastIndex {
          Divider()
        }
      }
      Spacer()
    }.padding(.top, 5).padding(.bottom, 10).background(.white)
  }
  
  @StateObject var sideVM = SideMenuViewModel()
  var body: some View {
    VStack(spacing: 0) {
      let size = CUSTOM_NAVI_ICON_SIZE - 2
      NaviView {
        size.HSpacer()
        Spacer()
        NaviTitle(text: "title_article".localized)
        Spacer()
        Button {
          sideVM.sideMenuRightPanel.toggle()
        } label: {
          Image(systemName: "line.3.horizontal")
            .square(size: size)
            .foregroundStyle(.colorPrimary)
        }
      }.background(Colors.surfaceVariant.swiftColor)
      Divider()
      
      SideMenu(rightMenu: sideMenu, centerView: {
        ScrollView {
          ScrollViewReader { proxy in
            sectionView
              .onAppear {
                self.proxy = proxy
              }
          }
        }
      }, viewModel: sideVM, config: SideMenuConfig(menuBGColor: .clear, menuBGOpacity: 0.2, menuWidth: 150))
    }.navigationBarHidden(true)
      .navigationDestination(isPresented: $naviVM.gotoWebView) {
        if let url = naviVM.webUrl {
          WebSwiftView(title: "", url: url)
        }
      }
  }
}

#Preview {
  ArticlePage()
}
