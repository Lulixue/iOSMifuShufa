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
    if text.isEmpty {
      text = "寒雨连江夜入吴，平明送客楚山孤"
    }
#endif
  }
  
  override var textEmpty: String {
    "集字文本不能为空".orCht("集字文本不能為空")
  }
  
  func onSearch(navi: NavigationViewModel) {
    if (!verifySearchText(text: text)) {
      return
    }
    if !CurrentUser.isVip && text.chineseCount > ConstraintItem.JiziZiCount.topMostConstraint {
      showConstraintVip(ConstraintItem.JiziZiCount.topMostConstraintMessage)
      return
    }
    let logs = HistoryViewModel.shared.getSearchLogs(.Jizi)
    for log in logs {
      if text.trim() == log.text!.trim() {
        navi.gotoJizi(text, log) { [weak self] in
          self?.buttonEnabled = true
        }
        return
      }
    }
    
    self.buttonEnabled = false
    navi.gotoJizi(text) { [weak self] in
      self?.buttonEnabled = true
    }
  }
  
  func convert(_ mode: TranslateMode) {
    NetworkHelper.convert(text: text, mode: mode) { result, success in
      DispatchQueue.main.async {
        if success {
          self.text = result
          self.showAlertDlg("已转换为：".orCht("已轉換為：") + result)
        } else {
          self.showAlertDlg("error_try_later".localized)
        }
      }
    }
  }
}

struct JiziPage : View {
  @StateObject var viewModel = JiziPageViewModel()
  @StateObject var naviVM = NavigationViewModel()
  @StateObject var historyVM = HistoryViewModel.shared
  @State var historyExpanded = [SearchLog: Bool]()
  @FocusState var focused: Bool
  @State private var showDropdown = false
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
  
  var dropdownView: some View {
    VStack(spacing: 0) {
      if text.chineseCount > 0 {
        
        Button {
          viewModel.convert(.HansToHant)
        } label: {
          HStack {
            Image("fan").renderingMode(.template).square(size: 20)
            Text("轉為繁體").font(.callout)
          }.foregroundStyle(Colors.iconColor(1))
        }.buttonStyle(.plain)
        Divider().padding(.vertical, 8)
        Button {
          viewModel.convert(.HansToHant)
           
        } label: {
          HStack {
            Image("jian").renderingMode(.template).square(size: 20)
            Text("转为简体").font(.callout)
          }.foregroundStyle(Colors.iconColor(0))
        }.buttonStyle(.plain)
        Divider().padding(.vertical, 8)
      }
      
      NavigationLink {
        JfConverterView()
      } label: {
        HStack {
          Image("jf_converter").renderingMode(.template).square(size: 20)
          Text("jf_convert".localized).font(.callout)
        }.foregroundStyle(Colors.iconColor(2))
      }.buttonStyle(.plain)
    }.padding(.vertical, 12).padding(.horizontal, 10)
      .background(.white)
      .cornerRadius(5)
      .shadow(radius: 1.5)
      .frame(width: 120)
  }

  
  private let paddingHor: CGFloat = 15
  var body: some View {
    NavigationStack {
      ZStack(alignment: .topTrailing) {
        content
        if showDropdown {
          dropdownView
            .offset(x: -10, y: 30)
        }
      }.background(.white)
      .modifier(TapDismissModifier(show: $showDropdown))
      .modifier(DragDismissModifier(show: $showDropdown))
    }.modifier(VipViewModifier(viewModel: viewModel))
      .navigationDestination(isPresented: $naviVM.gotoJiziView) {
        if naviVM.gotoJiziView {
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
          withAnimation(.easeIn(duration: 0.2)) {
            historyCollapsed.toggle()
          }
        } label: {
          HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("history".localized).font(.system(size: 16)).foregroundStyle(.searchHeader)
            Text("(\(logs.size))").font(.system(size: 13)).foregroundStyle(.searchHeader)
            Spacer()
            Image(systemName: "chevron.right").square(size: 10)
              .foregroundStyle(.colorPrimary).rotationEffect(.degrees(historyCollapsed ? 0 : 90))
          }.padding(.vertical, 10.5).padding(.horizontal, 10).background(Colors.surfaceContainer.swiftColor)
        }.buttonStyle(.plain)
        if !historyCollapsed {
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(0..<logs.size, id: \.self) { i in
                let log = logs[i]
                let text = log.text!
                let items = log.extra?.toPuzzleLog().items
                let binding = Binding {
                  self.historyExpanded[log] ?? false
                } set: {
                  self.historyExpanded[log] = $0
                }
                Button {
                  viewModel.buttonEnabled = false
                  naviVM.gotoJizi(text, log) {
                    viewModel.buttonEnabled = true
                  }
                } label: {
                  VStack(spacing: 4) {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(log.text!).font(.system(size: 16)).foregroundStyle(.darkSlateGray)
                        HStack {
                          Text(Utils.getNaturalTime(log.time!))
                          Spacer()
                          Text("(\(log.text!.chineseCount)字)")
                        }.font(.footnote)
                          .foregroundStyle(.searchHeader)
                      }
                      Spacer()
                      Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                          binding.wrappedValue.toggle()
                        }
                      } label: {
                        Image(systemName: "arrowtriangle.right.circle.fill").square(size: 20).foregroundStyle(.darkSlateGray)
                          .rotationEffect(.degrees(binding.wrappedValue ? 90 : 0))
                      }.buttonStyle(.plain)
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
                                    .contentShape(RoundedRectangle(cornerRadius: 2))
                                    .clipped()
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
        Text("title_jizi".localized).font(.system(size: 23)).foregroundStyle(Color.colorPrimary).bold()
        Image("jizi").renderingMode(.template).square(size: 14)
          .padding(.leading, 5)
        Spacer()
        Button {
          showDropdown = true
          focused = false
        } label: {
          Image(systemName: "line.3.horizontal").square(size: 20)
            .foregroundStyle(Color.colorPrimary)
        }.buttonStyle(.plain)
      }.padding(.horizontal, paddingHor)
        .padding(.top, UIDevice.current.hasNotch ? 0 : 6)
      10.VSpacer()
      ZStack(alignment: .top) {
        Color.white.onTapGesture {
          focused = true
        }
        TextField("jizi_hint".localized, text: $viewModel.text,
                  axis: .vertical)
        .font(.system(size: 17))
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
                .square(size: 20)
                .foregroundStyle(.gray)
            }.padding(4).buttonStyle(.plain)
          }.padding(.trailing, 4).buttonStyle(.plain)
        }
      }
      .frame(height: editHeight)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .background(RoundedRectangle(cornerRadius: 10).fill(.white).shadow(radius: focused ? 2 : 0))
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
          Image("chevron.up.2").renderingMode(.template).square(size: 10).foregroundStyle(.darkSlateGray)
            .rotationEffect(.degrees(editHeight == 120 ? 0 : 180))
        }.padding(.trailing, 5).buttonStyle(.plain)
        Button {
          focused = false
          viewModel.onSearch(navi: naviVM)
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "command").square(size: 12)
            Text("title_jizi".localized).font(.callout)
          }.foregroundStyle(.white)
        }.buttonStyle(PrimaryButton(bgColor: .blue))

      }.padding(.horizontal, paddingHor)
      10.VSpacer()
      historyView
    }.navigationBarHidden(true)
      .modifier(AlertViewModifier(viewModel: viewModel))
  }
}

#Preview {
  JiziPage()
}


extension String {
  func toPuzzleLog() -> PuzzleLog {
    let log = try? JSONDecoder().decode(PuzzleLog.self, from: self.utf8Data)
    if let log {
      return log
    }
    let puzzleLog = PuzzleLog()
    puzzleLog.items = (try? JSONDecoder().decode([PuzzleItem].self, from: self.utf8Data)) ?? []
  
    return puzzleLog
  }
}
