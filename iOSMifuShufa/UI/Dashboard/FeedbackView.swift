//
//  FeedbackView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/20.
//
import SwiftUI

class FeedbackViewModel: AlertViewModel {
  @Published var text = ""
  @Published var contact = ""
  @Published var sendEnabled = true
  
  var viewModel: FeedbackViewModel {
    self
  }
  func submitFeedback(feedback: String, contact: String) {
    viewModel.sendEnabled = false
    NetworkHelper.submitFeedback(feedback: feedback, contact: contact) { [weak self] error in
      if error == nil {
        self?.showFullAlert("提交".localizedFromChs,  "反馈已经收到，感谢你的反馈!".localizedFromChs)
      } else {
        self?.showFullAlert("错误".localizedFromChs, "发送反馈失败，请稍后重试!".localizedFromChs)
      }
      self?.viewModel.sendEnabled = true
    }
  }
}

enum ContactMethod: String, CaseIterable {
  case wechat = "微信"
  case qq = "QQ群"
  case phone = "手机"
  case email = "邮箱"
}

extension ContactMethod {
  var chinese: String {
    self.rawValue.localizedFromChs
  }
  
  var image: UIImage? {
    switch self {
    case .wechat: return UIImage(systemName: "w.circle")
    case .qq: return UIImage(systemName: "q.circle")
    case .phone: return UIImage(systemName: "flipphone")
    case .email: return UIImage(systemName: "envelope")
    }
  }
  
  var content: String {
    switch self {
    case .wechat: return "sf_lulixue"
    case .qq: return "497826827"
    case .phone: return "13612977027"
    case .email: return "lulixueapp@163.com"
    }
  }
  
  var color: Color {
    switch self {
    case .wechat:
        .searchHeader
    case .qq:
        .darkSlateBlue
    case .phone:
        .blue
    case .email:
        .darkBlue
    }
  }
  
  var textType: UITextContentType {
    switch self {
    case .wechat: return .name
    case .qq: return .postalCode
    case .phone: return .telephoneNumber
    case .email: return .emailAddress
    }
  }
}

struct FeedbackView: View {
  @StateObject var viewModel = FeedbackViewModel()
  @FocusState private var feedbackFocused: Bool
  @FocusState private var contactFocused: Bool
  @Environment(\.presentationMode) var presentationMode
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "feedback".localized)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }
      content
    }.navigationBarHidden(true)
  }
  
  func sendFeedback() {
    let feedback = viewModel.text
    let contact = viewModel.contact
    if feedback.isEmpty {
      viewModel.showFullAlert("提示", "kanwu_chinese_not_found".localized)
      return
    }
    contactFocused = false
    feedbackFocused = false
    if contact.isEmpty {
      viewModel.showFullAlert("提示", "联系方式未填写，开发人员无法就问题回访你，是否提交？".localizedFromChs, okTitle: "无须回访，继续提交".localizedFromChs, okRole: .destructive, ok: {
        self.viewModel.submitFeedback(feedback: feedback, contact: contact)
      }, cancelTitle: "返回填写".localizedFromChs, cancel: {
        self.contactFocused = true
      })
      return
    }
    viewModel.submitFeedback(feedback: feedback, contact: contact)
  }
  
  var content: some View {
    ScrollView {
      VStack(alignment: .leading) {
        ZStack(alignment: .top) {
          Color.white.onTapGesture {
            feedbackFocused = true
          }
          TextField("jizi_hint".localized, text: $viewModel.text,
                    axis: .vertical)
          .font(.body)
          .focused($feedbackFocused)
          .foregroundStyle(Color.colorPrimary)
          .multilineTextAlignment(.leading)
          .textFieldStyle(.plain)
          .padding(10)
          .padding(.trailing, 16)
          if feedbackFocused && viewModel.text.isNotEmpty() {
            ZStack(alignment: .trailing) {
              Color.clear
              Button {
                viewModel.text = ""
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .foregroundStyle(.gray)
              }.buttonStyle(.plain)
            }.padding(.trailing, 8)
          }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background {
          RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)
        }
        HStack {
          Text("contact".localized).foregroundColor(Colors.darkSlateGray.swiftColor).font(.callout)
          TextField("input_contact".localized, text: $viewModel.contact)
            .font(.callout)
            .focused($contactFocused)
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 0.5))
        }
        Button {
          sendFeedback()
        } label: {
          Text("发送".orCht("發送"))
            .foregroundColor(viewModel.sendEnabled ? .white : .gray)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Colors.searchHeader.swiftColor)
            .cornerRadius(5)
        }.buttonStyle(BgClickableButton(cornerRadius: 5))
          .disabled(!viewModel.sendEnabled)
        
        Spacer().frame(height: 40)
        Text("contact_developer".localized)
          .foregroundColor(Colors.colorPrimary.swiftColor)
          .multilineTextAlignment(.leading)
          .font(.title3.bold()).frame(maxWidth: .infinity, alignment: .leading)
        Spacer.height(9)
        Divider()
        Spacer.height(10)
        Group {
          ForEach(ContactMethod.allCases, id: \.self) { c in
            HStack {
              Image(uiImage: c.image!).resizable().scaledToFit().frame(width: 20, height: 20)
              Spacer.width(15)
              Text(c.chinese).font(.system(size: 19)).frame(minWidth: 90, alignment: .leading)
              Text(c.content)
                .textSelection(.enabled)
                .textContentType(c.textType)
                .foregroundStyle(c.color)
            }
          }
        }.padding(.horizontal, 10).padding(.top, 5)
      }.padding(.horizontal, 15)
        .padding(.vertical, 10)
        .modifier(AlertViewModifier(viewModel: viewModel))
    }
  }
}

#Preview {
  FeedbackView()
}
