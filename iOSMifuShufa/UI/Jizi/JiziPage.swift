//
//  JiziPage.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import Foundation
import SwiftUI

class JiziPageViewModel: AlertViewModel {
  @Published var text = ""
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
        if viewModel.text.isNotEmpty() {
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
          
        } label: {
          Image(systemName: "chevron.up.2").square(size: 10).foregroundStyle(.gray)
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
      Spacer()
    }.navigationBarHidden(true)
  }
}

#Preview {
  JiziPage()
}
