//
//  Home.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import SwiftUI


struct HomePage: View {
  @StateObject var viewModel: HomeViewModel
  @State var searching: Bool = false
  @FocusState var focused: Bool
  private let searchBarHeight = 36.0
  private let radius = 4.0
  
  var searchBar: some View {
    HStack {
      HStack {
        HStack {
          8.HSpacer()
          Button {
            
          } label: {
            HStack(spacing: 0) {
              Text("汉字")
              3.HSpacer()
              Image(systemName: "chevron.down").square(size: 8)
            }.padding(.horizontal, 3).foregroundStyle(Color.gray)
              .font(.callout)
          }
          8.HSpacer()
        }.frame(height: searchBarHeight).background(Color.background)
        
        Color.gray.frame(width: 0.4)
        
        TextField("search_hint".localized, text: $viewModel.text,
                  onEditingChanged: { focused in
          if viewModel.showDeleteAlert {
            return
          }
          viewModel.focused = focused
          viewModel.updateHistoryBarVisible()
        })
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
            Text("search".resString).font(.footnote)
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
  
  var body: some View {
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
      Color.background
    }.background(.white)
      .onAppear {
        UITextField.appearance().clearButtonMode = .whileEditing
      }
  }
}

#Preview {
  HomePage(viewModel: HomeViewModel())
}
