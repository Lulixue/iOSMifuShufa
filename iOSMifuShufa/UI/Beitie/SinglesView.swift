//
//  SinglesView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/8.
//

import SwiftUI
import Foundation
import SDWebImageSwiftUI

class SingleViewModel: AlertViewModel {
  @Published var drawViewModel = DrawViewModel()
  let singles: List<BeitieSingle>
  @Published var showDrawPanel = false
  @Published var currentIndex: Int = 0
  init(singles: List<BeitieSingle>, selected: Int = 0) {
    self.singles = singles
    self.currentIndex = selected
    super.init()
    drawViewModel.onCloseDraw = { [weak self] in
      self?.showDrawPanel = false
    }
  }
  
  func toggleDrawPanel() {
    showDrawPanel.toggle()
    if !showDrawPanel {
      drawViewModel.onReset()
    }
  }
}


struct SinglesView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel: SingleViewModel
  @State var scrollProxy: ScrollViewProxy? = nil
  @State var pageIndex = 0
  var singles: List<BeitieSingle> {
    viewModel.singles
  }
  var currentSingle: BeitieSingle {
    singles[viewModel.currentIndex]
  }
  private let bottomBarHeight: CGFloat = 80
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        let title = {
          let s = currentSingle
          var t = AttributedString(s.showChars)
          var sub = AttributedString(" \(viewModel.currentIndex+1)/\(singles.size)")
          t.font = .body
          t.foregroundColor = Color.colorPrimary
          sub.font = .footnote
          sub.foregroundColor = Color.colorPrimary
          return t + sub
        }()
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        Text(title)
        Spacer()
        Button {
          
        } label: {
          Image("collect").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE+1)
            .foregroundStyle(Color.colorPrimary)
        }
        Button {
          
        } label: {
          Image("big_image").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE)
            .foregroundStyle(Color.colorPrimary)
        }
      }
      Divider()
      ZStack {
        TabView(selection: $pageIndex) {
          ForEach(0..<singles.size, id: \.self) { i in
            let single = singles[i]
            SinglePreviewItem(single: single)
          }
        }.tabViewStyle(.page(indexDisplayMode: .never))
          .background {
            Image("background").resizable().scaledToFill()
          }
        if viewModel.showDrawPanel {
          DrawPanel().environmentObject(viewModel.drawViewModel)
        }
      }
      Divider()
      HStack(spacing: 0) {
        let single = currentSingle
        if single.repeat {
          Text("重复符号".orCht("重複符號")).font(.footnote).foregroundStyle(Color.colorPrimary)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background {
              RoundedRectangle(cornerRadius: 5).stroke(Color.colorPrimary, lineWidth: 0.5)
            }
        } else {
          
          Text("radical".localized).font(.footnote).foregroundStyle(Color.colorPrimary)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background {
              RoundedRectangle(cornerRadius: 5).stroke(Color.colorPrimary, lineWidth: 0.5)
            }
          Text(single.radical ?? UNKNOWN).padding(.leading, 5)
          8.HSpacer()
          Text("structure".localized).font(.footnote).foregroundStyle(Color.blue)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background {
              RoundedRectangle(cornerRadius: 5).stroke(Color.colorPrimary, lineWidth: 0.5)
            }
          Text(single.structure ?? UNKNOWN).padding(.leading, 5)
        }
        Spacer()
        Button {
          viewModel.toggleDrawPanel()
        } label: {
          Image("handwriting").square(size: 16)
        }
      }.padding(.horizontal, 10).padding(.vertical, 8).background(.white)
      Divider()
      ScrollView([.horizontal]) {
        ScrollViewReader { proxy in
          LazyHStack(spacing: 12) {
            ForEach(0..<singles.size, id: \.self) { i in
              let single = singles[i]
              let selected = i == viewModel.currentIndex
              HStack{
                Button {
                  viewModel.currentIndex = i
                } label: {
                  WebImage(url: single.thumbnailUrl.url!) { img in
                    img.image?.resizable()
                      .aspectRatio(contentMode: .fit)
                  }.clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(0.5)
                    .background {
                      RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .white, lineWidth: selected ? 2 : 1)
                    }.padding(.horizontal, selected ? 0 : 0.5)
                }
              }.id(i)
            }
          }.padding(.vertical, 10).padding(.horizontal, 15).frame(height: bottomBarHeight)
            .onAppear {
              scrollProxy = proxy
              if viewModel.currentIndex > 0 {
                Task {
                  sleep(1)
                  DispatchQueue.main.async {
                    proxy.scrollTo(max(self.viewModel.currentIndex-1, 0), anchor: .leading)
                  }
                }
              }
            }
        }
      }.frame(maxWidth: .infinity).frame(height: bottomBarHeight).background(Color.singlePreviewBackground)
        .onChange(of: viewModel.currentIndex) { newValue in
          pageIndex = newValue
        }
        .onAppear {
          pageIndex = viewModel.currentIndex
        }
        .onChange(of: pageIndex) { newValue in
          if viewModel.currentIndex != newValue {
            scrollProxy?.scrollTo(max(newValue-1, 0), anchor: .leading)
            viewModel.currentIndex = pageIndex
          }
        }
    }
  }
}

#Preview {
  let singles = BeitieDbHelper.shared.getSingles("人")
  return SinglesView(viewModel: SingleViewModel(singles: singles, selected: 10))
}
