//
//  LoginView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/20.
//
import SwiftUI
import UIKit
import Foundation
import Alamofire
import Combine
import AuthenticationServices

var DEVICE_ID: String {
  Settings.deviceId
}
class LoginViewModel: AlertViewModel {
   
  @Published var showLoading = false
  @Published var loadingText = ""
  
  @Published var phoneNum: String = UserItem.phoneNumber.stringValue {
    didSet {
      Settings.User.phoneNumber = phoneNum
    }
  }
  @Published var verifyCode: String = ""
  
  @Published var loginText: String = "login".localized
  @Published var checkAgreed = Settings.User.phoneAgree {
    didSet {
      Settings.User.phoneAgree = checkAgreed
    }
  }
  @Published var checkCodeFree = Settings.User.codeFree {
    didSet {
      Settings.User.codeFree = checkCodeFree
    }
  }
  @Published var canSkipVerify = false
  @Published var tokenReady = false
  @Published var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  @Published var countDown = 0
  
  var canSendVerifyCode: Bool {
    countDown == 0
  }
  
  var dismiss: () -> Void = {}
  
  func privacyAgreeBinding() -> Binding<Bool> {
    Binding {
      self.checkAgreed
    } set: { newValue in
      self.checkAgreed = newValue
    }
  }
   
  var verifyButtonText: String {
    if countDown > 0 {
      "resend".localized + " \(countDown)s"
    } else {
      "get_verify_code".localized
    }
  }
  
  let firstInitSkipVerify: Bool
  
  var loginWithoutVerify: Bool {
    firstInitSkipVerify && canSkipVerify && checkCodeFree
  }
  
  override init() {
    let lastLoginPhone = UserItem.phoneNumber.stringValue
    let lastEditPhone = Settings.User.phoneNumber
    let canSkip = lastLoginPhone.isNotEmpty() && lastLoginPhone == lastEditPhone && CurrentUser.loginCanIgnoreCode
    canSkipVerify = canSkip
    firstInitSkipVerify = canSkip && Settings.User.codeFree
    super.init()
  }
  
  func loginApple(_ au: ASAuthorization) {
    if let credential = au.credential as? ASAuthorizationAppleIDCredential {
      showLoading("logining".resString)
      Task {
        NetworkHelper.loginPoem(credential.user, DEVICE_ID, onResult: { user in
          self.onUser(user)
        })
      }
    }
  }
  
  func sendVerfiyCode() {
    if !checkAgreed {
      showAlertDlg("agree_privacy_first".localized)
      return
    }
    if phoneNum.isEmpty {
      showMessageDialog("input_phone_number".resString)
      return
    }
    showLoading("requesting_sms_code".localized)
    Task {
      for i in 0..<3 {
        do {
          try VerifyHelper.requestSmsCode(phoneNumber: phoneNum)
          DispatchQueue.main.async {
            self.hideLoading()
            self.countDown = 60
          }
          break
        } catch {
          if i == 2 {
            DispatchQueue.main.async {
              self.hideLoading()
              self.showAlertDlg("sms_code_failed".localized)
            }
          }
        }
      }
    }
  }
  
  private func hideLoading() {
    showLoading = false
  }
  
  private func showLoading(_ text: String) {
    loadingText = text
    showLoading = true
  }
  
  var loginButtonText: String {
    if loginText == "doing_loging".resString {
      return loginText
    } else if loginWithoutVerify {
      return "login_without_verify".localized
    } else {
      return "login".localized
    }
  }
  
  func verify() {
    if !checkAgreed {
      showAlertDlg("agree_privacy_first".localized)
      return
    }
    if phoneNum.isEmpty {
      showMessageDialog("input_phone_number".resString)
      return
    }
    
    if verifyCode.isEmpty {
      showMessageDialog("input_verify_code".resString)
      return
    }
    showLoading("logining".resString)
    Task {
      for i in 0..<3 {
        do {
          try VerifyHelper.checkVerifyCode(phoneNum, verifyCode)
          NetworkHelper.loginPoemByPhone(phoneNum, DEVICE_ID) { user in
            self.onUser(user)
          }
          break
        } catch {
          if i == 2 {
            DispatchQueue.main.async {
              self.hideLoading()
              self.showAlertDlg("error_try_later".localized)
            }
          }
        }
      }
    }
  }
  
  
  private func onUser(_ user: PoemUser?) {
    DispatchQueue.main.async {
      CurrentUser.updateUser(user)
      self.hideLoading()
      if user != nil {
        self.dismiss()
      } else {
        self.canSkipVerify = false
        self.loginText = "login".resString
        self.showAlertDlg("login_failed".resString)
      }
    }
  }
  
  func loginByPhone() {
    if !checkAgreed {
      showAlertDlg("agree_privacy_first".localized)
      return
    }
    if phoneNum.isEmpty {
      showMessageDialog("input_phone_number".resString)
      return
    }
    showLoading("doing_login".resString)
    NetworkHelper.loginPoemByPhone(phoneNum, DEVICE_ID) { user in
      self.onUser(user)
    }
  }
}

struct LoginView: View {
  @StateObject var viewModel = LoginViewModel()
  var onClickAppleLogin: () -> Void = { }
   
  @Environment(\.presentationMode) var presentationMode
  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        NaviView {
          BackButtonView {
            presentationMode.wrappedValue.dismiss()
          }.padding(.leading, 8)
          Spacer()
        }
        content.blur(radius: viewModel.showLoading ? 5: 0)
      }
      if viewModel.showLoading {
        LoadingView(title: $viewModel.loadingText)
      }
    }.navigationBarHidden(true)
      .navigationDestination(isPresented: $gotoPrivacyView) {
        if gotoPrivacyView {
          PrivacyView()
        }
      }
  }
  
  enum Field: Hashable {
    case phone
    case verify
  }
  
  
  @FocusState var focused: Field?
  @State private var gotoPrivacyView: Bool = false
  
  var content: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        Spacer.height(UIScreen.currentHeight * 0.15)
        Group {
          HStack(spacing: 15) {
            Text("phone_num".localized).foregroundColor(Colors.darkSlateGray.swiftColor)
            TextField("input_phone_number".localized, text: $viewModel.phoneNum)
              .font(.title3.bold())
              .keyboardType(.numberPad)
              .focused($focused, equals: .phone)
          }.padding(.vertical, 5)
            .onChange(of: viewModel.phoneNum) { _ in
              viewModel.canSkipVerify = false
            }
          Divider()
          Spacer.height(20)
          if !viewModel.loginWithoutVerify {
            HStack(spacing: 15) {
              Text("verify_code".localized).foregroundColor(Colors.darkSlateGray.swiftColor)
              TextField("input_verify_code".localized, text: $viewModel.verifyCode)
                .font(.title3.bold())
                .keyboardType(.numberPad)
                .focused($focused, equals: .verify)
              Button {
                viewModel.sendVerfiyCode()
              } label: {
                Text(viewModel.verifyButtonText)
              }.disabled(!viewModel.canSendVerifyCode)
            }.padding(.vertical, 5)
              .onReceive(viewModel.timer) { _ in
                if viewModel.countDown > 0 {
                  viewModel.countDown = viewModel.countDown - 1
                }
              }
            Divider()
              Text("注：手机号仅支持中国大陆手机号，无须添加+86前缀，其他地区请使用苹果登录".orCht("注：手機號僅支持中國大陸手機號，無須添加+86前綴，其他地區請使用蘋果登錄"))
                  .font(.footnote)
                  .foregroundStyle(.gray.opacity(0.75))
                  .padding(.top, 12)
          }
        }
        
        Spacer.height(30)
        Button {
          focused = nil
          if viewModel.loginWithoutVerify {
            viewModel.loginByPhone()
          } else {
            viewModel.verify()
          }
        } label: {
          HStack {
            Text(viewModel.loginButtonText).font(.body).tracking(2)
              .padding(.vertical, 3)
          }.frame(maxWidth: .infinity)
        }.buttonStyle(PrimaryButton())
        Spacer.height(15)
        HStack {
          VStack(alignment: .leading, spacing: 5) {
            Toggle(isOn: viewModel.privacyAgreeBinding()) {
              HStack(spacing: 0) {
                Text("agree".localized)
                Text("[《\("privacy".resString)》](https://www.google.com)")
                  .environment(\.openURL, OpenURLAction(handler: { _ in
                    self.gotoPrivacyView = true
                    return .handled
                  }))
              }
            }.toggleStyle(CheckboxStyle(backgroundColor: .white))
            Toggle(isOn: $viewModel.checkCodeFree) {
              Text("login_code_free_in_3_days".localized)
            }.toggleStyle(CheckboxStyle(backgroundColor: .white))
          }
          Spacer()
        }
        Group {
          Spacer.height(100)
          Divider.overlayColor(.gray.opacity(0.8))
          VStack {
            HStack {
              Spacer()
              SignInWithAppleButton(.signUp) { request in
                request.requestedScopes = [.email]
              } onCompletion: { result in
                  // completion handler that is called when the sign-in completes
                switch result {
                case .success(let aus):
                  viewModel.loginApple(aus)
                case .failure(_):
                  do {}
                }
              }.frame(width: 200)
                .signInWithAppleButtonStyle(.whiteOutline)
              Spacer()
            }
          }.padding(.vertical, 10)
        }
      }.padding(.horizontal, 25)
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.white)
      .modifier(AlertViewModifier(viewModel: viewModel))
      .onAppear {
        #if DEBUG
        viewModel.phoneNum = "13612977027"
        #endif
        viewModel.dismiss = {
          self.presentationMode.wrappedValue.dismiss()
        }
      }
  }
}

#Preview(body: {
  LoginView()
})
