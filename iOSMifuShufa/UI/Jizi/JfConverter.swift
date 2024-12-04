//
//  JfConverter.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/21.
//
import SwiftUI

class JfConverterViewModel: AlertViewModel {
  @Published var text = ""
  @Published var buttonEnabled = true
  @Published var convertedText = ""
  
  func convert(mode: TranslateMode) {
    if text.chineseCount == 0 {
      showAlertDlg("text_is_empty".localized)
      return
    }
    NetworkHelper.convert(text: text, mode: mode) { result, success in
      if success {
        DispatchQueue.main.async {
          self.convertedText = result
        }
      }
    }
  }
}

struct JfConverterView: View {
  @StateObject var viewModel = JfConverterViewModel()
  @Environment(\.presentationMode) var presentationMode
  
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
  
  @FocusState var focused: Bool
  private let paddingHor: CGFloat = 20
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        NaviContents(title: "jf_convert".resString) {
          BackButtonView {
            presentationMode.wrappedValue.dismiss()
          }
        } trailing: {
          
        }
      }
      6.VSpacer()
      ZStack(alignment: .top) {
        Color.white.onTapGesture {
          focused = true
        }
        TextField("jf_hint".localized, text: $viewModel.text,
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
          }.padding(.trailing, 8).buttonStyle(.plain)
        }
      }
      .frame(height: 120)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .background {
        RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)
      }
      .padding(.horizontal, paddingHor)
      10.VSpacer()
      HStack {
        Text(chineseCount).font(.footnote).foregroundStyle(.gray)
        Spacer()
        Button {
          viewModel.convert(mode: .HantToHans)
        } label: {
          Text("转为简体").font(.callout)
        }.buttonStyle(PrimaryButton(bgColor: .searchHeader))
          .disabled(!viewModel.buttonEnabled)
        
        Button {
          viewModel.convert(mode: .HansToHant)
        } label: {
          Text("轉為繁體").font(.callout)
        }.buttonStyle(PrimaryButton(bgColor: .souyun))
          .disabled(!viewModel.buttonEnabled)
      }.padding(.horizontal, paddingHor)
      Divider().padding(.vertical, 10)
      ScrollView {
        HStack {
          Text(viewModel.convertedText).textSelection(.enabled).font(.title3)
            .kerning(1).multilineTextAlignment(.leading)
          Spacer()
        }.padding(.leading, 20).padding(.vertical, 15)
      }
    }.onAppear {
#if DEBUG
      viewModel.text = "寒雨连江夜入吴"
#endif
    }.modifier(AlertViewModifier(viewModel: viewModel))
      .navigationBarHidden(true)
  }
}

#Preview {
  JfConverterView()
}
