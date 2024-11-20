//
//  JiziPage.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

class JiziPageViewModel: AlertViewModel {
  @Published var text = Settings.Jizi.lastJiziText {
    didSet {
      Settings.Jizi.lastJiziText = text
    }
  }
  @Published var focused = false
  @Published var buttonEnabled = true
  
  override init() {
    super.init()
#if DEBUG
    text = "寒雨连江夜入吴，平明送客楚山孤"
#endif
  }
  func onSearch(navi: NavigationViewModel) {
    if (!verifySearchText(text: text)) {
      return
    }
    self.buttonEnabled = false
    navi.gotoJizi(text) { [weak self] in
      self?.buttonEnabled = true
    }
  }
}

struct JiziPage : View {
  @StateObject var viewModel = JiziPageViewModel()
  @StateObject var naviVM = NavigationViewModel()
  @StateObject var historyVM = HistoryViewModel.shared
  @State var historyExpanded = [SearchLog: Bool]()
  @FocusState var focused: Bool
  @State private var editHeight: CGFloat = 120
  var text: String {
    viewModel.text
  }
  var chineseCount: String {
    if !text.containsChineseChar {
      return ""
    } else {
      let count = text.chineseCount
      return "共\(count)个汉字".orCht("共\(count)個漢字")
    }
  }
  private let paddingHor: CGFloat = 15
  var body: some View {
    NavigationStack {
      content
        .navigationDestination(isPresented: $naviVM.gotoJiziView) {
          JiziView(viewModel: naviVM.jiziVM!)
        }
    }
  }
  @State private var historyCollapsed = false
  
  var historyView: some View {
    let logs = historyVM.getSearchLogs(.Jizi)
    return VStack(spacing: 0) {
      if logs.isNotEmpty() {
        Button {
          historyCollapsed.toggle()
        } label: {
          HStack(spacing: 0) {
            Text("history".localized).font(.callout).foregroundStyle(.colorPrimary)
            Text("(\(logs.size))").font(.footnote).foregroundStyle(.colorPrimary)
            Spacer()
            Image(systemName: "chevron.right").square(size: 10)
              .foregroundStyle(.colorPrimary)
          }.padding(.vertical, 8).padding(.horizontal, 10).background(Colors.surfaceContainer.swiftColor)
        }
        if !historyCollapsed {
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(0..<logs.size, id: \.self) { i in
                let log = logs[i]
                let text = log.text!
                let items = log.extra?.toPuzzleItems()
                let binding = Binding {
                  self.historyExpanded[log] ?? false
                } set: {
                  self.historyExpanded[log] = $0
                }
                Button {
                  viewModel.buttonEnabled = false
                  naviVM.gotoJizi(text, items) {
                    viewModel.buttonEnabled = true
                  }
                } label: {
                  VStack(spacing: 4) {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(log.text!).font(.system(size: 16)).foregroundStyle(.darkSlateGray)
                        Text(Utils.getNaturalTime(log.time!)).font(.footnote)
                          .foregroundStyle(.gray)
                      }
                      Spacer()
                      Button {
                        binding.wrappedValue.toggle()
                      } label: {
                        Image(systemName: "arrowtriangle.right.circle.fill").square(size: 20).foregroundStyle(.darkSlateGray)
                          .rotationEffect(.degrees(binding.wrappedValue ? 90 : 0))
                      }
                    }
                    if binding.wrappedValue {
                      if let items {
                        ScrollView([.horizontal]) {
                          LazyHStack(spacing: 0) {
                            ForEach(0..<items.size, id: \.self) { j in
                              let item = items[j]
                              let url = item.thumbnailUrl.isEmpty ? item.char.first().jiziCharUrl : item.thumbnailUrl.url
                              if let url {
                                WebImage(url: url) { img in
                                  img.image?.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(minWidth: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                }.indicator(.activity)
                                  .tint(.white).padding(.trailing, 3)
                              }
                            }
                          }.padding(.horizontal, 3).padding(.vertical, 4)
                        }.frame(height: 40)
                          .background {
                            RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.75), lineWidth: 0.5)
                          }
                      }
                    }
                  }.padding(.vertical, 10).padding(.leading, 10).padding(.trailing, 15)
                    .background(.white)
                }.buttonStyle(BgClickableButton())
                if i != logs.lastIndex {
                  Divider().padding(.leading, 10)
                }
              }
            }
          }
        } else {
          Spacer()
        }
      } else {
        Spacer()
      }
    }
  }
  
  var content: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("title_jizi".localized).font(.system(size: 24)).foregroundStyle(Color.colorPrimary).bold()
        Image("jizi").renderingMode(.template).square(size: 14)
          .padding(.leading, 5)
        Spacer()
        Button {
          
        } label: {
          Image(systemName: "line.3.horizontal").square(size: 20)
            .foregroundStyle(Color.colorPrimary)
        }
      }.padding(.horizontal, paddingHor)
      10.VSpacer()
      ZStack(alignment: .top) {
        Color.white.onTapGesture {
          focused = true
        }
        TextField("jizi_hint".localized, text: $viewModel.text,
                  axis: .vertical)
        .font(.body)
        .focused($focused)
        .foregroundStyle(Color.colorPrimary)
        .multilineTextAlignment(.leading)
        .textFieldStyle(.plain)
        .padding(10)
        .padding(.trailing, 16)
        if focused && viewModel.text.isNotEmpty() {
          ZStack(alignment: .trailing) {
            Color.clear
            Button {
              viewModel.text = ""
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray)
            }
          }.padding(.trailing, 8)
        }
      }
      .frame(height: editHeight)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .background {
        RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)
      }
      .padding(.horizontal, paddingHor)
      8.VSpacer()
      HStack {
        Text(chineseCount).foregroundStyle(.gray).font(.footnote)
        Spacer()
        Button {
          withAnimation {
            self.editHeight = editHeight == 120 ? 80 : 120
          }
        } label: {
          Image(systemName: "chevron.up.2").square(size: 10).foregroundStyle(.gray)
            .rotationEffect(.degrees(editHeight == 120 ? 0 : 180))
        }.padding(.trailing, 5)
        Button {
          viewModel.onSearch(navi: naviVM)
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "command").square(size: 12)
            Text("title_jizi".localized).font(.callout)
          }.foregroundStyle(viewModel.buttonEnabled ? .white : .gray)
        }.buttonStyle(PrimaryButton(bgColor: .blue))
          .disabled(!viewModel.buttonEnabled)
      }.padding(.horizontal, paddingHor)
      10.VSpacer()
      historyView
    }.navigationBarHidden(true)
  }
}

#Preview {
  JiziPage()
}


extension String {
  func toPuzzleItems() -> [PuzzleItem] {
    return (try? JSONDecoder().decode([PuzzleItem].self, from: self.utf8Data)) ?? []
  }
}
