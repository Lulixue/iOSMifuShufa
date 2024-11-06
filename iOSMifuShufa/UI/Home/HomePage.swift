//
//  Home.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import SwiftUI


struct TodayCardView<Content: View>: View {
  let title: String
  let onClick: () -> Void
  let content: Content
  init(title: String,
       onClick: @escaping () -> Void,
       @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.onClick = onClick
    self.content = content()
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      Button {
        onClick()
      } label: {
        VStack(alignment: .leading) {
          HStack {
            Text(title).font(.callout).foregroundColor(Colors.searchHeader.swiftColor)
            Spacer()
          }
          ZStack(alignment: .topLeading) {
            Color.clear
            content
          }
        }.padding(.horizontal, 12)
          .padding(.top, 10).padding(.bottom, 15)
          .background(.white)
      }.buttonStyle(BgClickableButton())
      
    }.background(RoundedRectangle(cornerRadius: 10).fill(.white))
      .frame(maxWidth: .infinity)
      .cornerRadius(10)
      .shadow(radius: 0.8, y: 0.5)
  }
}

struct HomePage: View {
  @StateObject var viewModel: HomeViewModel
  @StateObject var sideVM = SideMenuViewModel()
  @State var searching: Bool = false
  @FocusState var focused: Bool
  private let searchBarHeight = 36.0
  private let radius = 4.0
  private let font = Font.system(size: 14)
  
  var searchBar: some View {
    HStack {
      HStack {
        HStack {
          8.HSpacer()
          Button {
            
          } label: {
            HStack(spacing: 0) {
              Text(viewModel.searchCharType.chinese).font(font)
              3.HSpacer()
              Image(systemName: "chevron.down").square(size: 8)
            }.padding(.horizontal, 3).foregroundStyle(Color.gray)
              .font(.callout)
          }
          8.HSpacer()
        }.frame(height: searchBarHeight).background(Color.background)
        
        Color.gray.frame(width: 0.4)
        
        TextField(viewModel.searchCharType.hint, text: $viewModel.text,
                  onEditingChanged: { focused in
          if viewModel.showDeleteAlert {
            return
          }
          viewModel.focused = focused
          viewModel.updateHistoryBarVisible()
        })
        .font(font)
        .focused($focused)
        .textFieldStyle(.plain)
        .submitLabel(.search)
        .onSubmit {
          onSearch()
        }
        Button {
          
        } label: {
          HStack(spacing: 3) {
            Image(systemName: "magnifyingglass").square(size: 10)
            Text("search".resString).font(font)
          }
        }.buttonStyle(PrimaryButton(bgColor: .blue)).padding(.trailing, 5)
      }.clipShape(RoundedRectangle(cornerRadius: radius)).padding(0.6).background(RoundedRectangle(cornerRadius: radius, style: .circular).stroke(Color.gray, lineWidth: 0.6)).frame(height: searchBarHeight)
    }.padding(.horizontal, 35)
  }
  
  private func onSearch() {
    focused = false
    let text = viewModel.text
    let chars = text.toCharList.unique
    if chars.isEmpty() {
      viewModel.searchResults.clear()
      viewModel.showAlertDlg("no_available_chinese".localized)
      return
    }
    searching = true
    DispatchQueue.global(qos: .background).async {
      DispatchQueue.main.async {
        searching = false
        viewModel.searchResults.clear()
      }
    }
  }
  
  @ViewBuilder func todayWork(_ work: BeitieWork) -> some View {
    TodayCardView(title: "今日法帖") {
      
    } content: {
      VStack(alignment: .center, spacing: 8) {
        HStack(alignment: .center) {
          Spacer()
          AsyncImage(url: work.cover.url!) { img in
            img.image?.resizable()
              .scaledToFill()
              .frame(height: 80, alignment: .center)
              .frame(maxWidth: UIScreen.currentWidth * 0.75, alignment: .center)
              .clipShape(RoundedRectangle(cornerRadius: 5))
          }
          .padding(3)
          .background(content: {
            RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.5), lineWidth: 0.5)
          })
          Spacer()
        }.padding(.vertical, 5)
        
        Text(work.workNameAttrStr(.body, smallerFont: .footnote))
          .foregroundStyle(Color.searchHeader)
        
        if work.chineseIntro()?.isNotEmpty() == true {
          Text(work.chineseIntro()!).font(.footnote)
            .lineLimit(5)
            .foregroundStyle(Color.defaultText)
        }
      }
    }
  }
  
  @ViewBuilder func todaySingle(_ single: BeitieSingle) -> some View {
    TodayCardView(title: "今日单字".orCht("今日單字")) {
      
    } content: {
      VStack(alignment: .center) {
        HStack(alignment: .center) {
          Spacer()
          AsyncImage(url: single.thumbnailUrl.url!) { img in
            img.image?.resizable()
              .scaledToFill()
              .frame(height: 60)
              .frame(maxWidth: 60)
              .clipShape(RoundedRectangle(cornerRadius: 5))
          }
          .padding(3)
          .background(content: {
            RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.5), lineWidth: 0.5)
          })
          Spacer()
        }
        Text(single.showChars)
          .foregroundStyle(Color.defaultText)
          .font(.body)
        Text(single.work.workNameAttrStr(.body, smallerFont: .footnote))
          .foregroundStyle(Color.searchHeader)
          .padding(.top, 1)
      }
    }
  }
  
  var resultView: some View {
    ScrollView {
      VStack(spacing: 0) {
        HStack {
          
        }.background(Color.pullerBar)
        ScrollViewReader { proxy in
          LazyVStack(spacing: 0) {
            
          }
        }
      }
    }
  }
  
  var defaultView: some View {
    ScrollView {
      VStack(spacing: 10) {
        let single = viewModel.todaySingle
        if single != nil {
          todaySingle(single!)
        }
        let work = viewModel.todayWork
        if work != nil {
          todayWork(work!)
        }
      }.padding(.horizontal, 12).padding(.vertical, 12)
    }.background(Colors.surfaceVariant.swiftColor)
  }
  
  var sideMenu: some View {
    FilterView().environmentObject(viewModel.filterViewModel)
  }
  
  var body: some View {
    SideMenu(leftMenu: sideMenu, centerView: {
      centerView
    }, viewModel: sideVM)
  }
  
  var centerView: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Image("mi").renderingMode(.template).resizable().frame(width: 18, height: 20)
          .foregroundStyle(Color.searchHeader)
          .rotationEffect(.degrees(5))
        3.HSpacer()
        Image("fu").renderingMode(.template).resizable().scaledToFill().frame(width: 18, height: 22).rotationEffect(.degrees(2))
          .foregroundStyle(Color.searchHeader)
        Spacer()
        Button {
          sideVM.sideMenuLeftPanel.toggle()
        } label: {
          Image(systemName: "line.3.horizontal")
            .square(size: 20)
            .foregroundStyle(Color.colorPrimary)
            .buttonStyle(PrimaryButton())
          
        }
        5.HSpacer()
      }.padding(.horizontal, 15)
      10.VSpacer()
      searchBar
      if viewModel.showHistoryBar {
        HistoryBarView(page: .Search, showDeleteAlert: $viewModel.showDeleteAlert, onClearLogs: {
          viewModel.updateHistoryBarVisible()
        }) { l in
          viewModel.text = l.text!
          onSearch()
        }
        8.VSpacer()
      } else {
        10.VSpacer()
      }
      0.4.HDivder()
      defaultView
    }.background(.white)
      .onAppear {
        UITextField.appearance().clearButtonMode = .whileEditing
      }
  }
}

#Preview {
  HomePage(viewModel: HomeViewModel())
}
