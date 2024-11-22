//
//  UserView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/20.
//

import SwiftUI

struct UserView: View {
  @StateObject var viewModel = CurrentUser
  @Environment(\.presentationMode) var presentationMode
  @State private var editName = false
  @State var editText = ""
  @FocusState var focused: Bool
  
  func onChangeName() {
    let text = editText.trim()
    if text.isEmpty {
      viewModel.showAlertDlg("username_is_empty".resString)
      return
    }
    if text == viewModel.userName {
      viewModel.showAlertDlg("username_equal".resString)
      return
    }
    viewModel.updateUserName(text) { result in
      viewModel.showAlertDlg(result ? "用户名已更新" : "用户名更新失败！".orCht("用户名更新失敗"))
      editName.toggle()
    }
  }
  func onDismiss() {
    presentationMode.wrappedValue.dismiss()
  }
  
  func onDeleteAccount() {
    if CurrentUser.isVip {
      viewModel.showAlertDlg("account_vip_no_delete".resString)
      return
    }
    viewModel.showFullAlert("warn".localized,
                            "delete_account_confirm".resString,
                            okTitle: "confirm".resString, okRole: .destructive,
                            ok: {
      NetworkHelper.deleteAccount(CurrentUser.userId) { value in
        DispatchQueue.main.async {
          if value {
            viewModel.logout()
            viewModel.showAlertDlg("account_deleted".resString)
          } else {
            viewModel.showAlertDlg("error_try_later".resString)
          }
        }
      }
    }, cancelTitle: "cancel".resString)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          onDismiss()
        }
        Spacer()
        NaviTitle(text: "my_center".resString)
        Spacer()
        Button {
          onDeleteAccount()
        } label: {
          Text("delete_account".localized).font(.callout)
            .foregroundStyle(.red)
        }
      }
      Divider()
      ScrollView {
        VStack(spacing: 0) {
          Button {
            UIPasteboard.general.string = viewModel.userId
            viewModel.showAlertDlg("ID已拷贝到剪贴板".orCht("ID已拷貝到剪貼板"))
          } label: {
            HStack {
              Image("id").renderingMode(.template).resizable().scaledToFit().frame(width: 20, height: 20)
                .foregroundColor(.black)
              Text("我的ID").foregroundColor(.black)
              Spacer.width(50)
              Text(viewModel.userId).lineLimit(1).foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
              Image(systemName: "chevron.right").resizable().scaledToFit()
                .foregroundColor(.gray).frame(width: 12, height: 12)
            }.padding(.horizontal, 15).padding(.vertical, 15)
          }.buttonStyle(BgClickableButton())
          
          Divider().padding(.leading, 15)
          HStack {
            Image(systemName: "person").renderingMode(.template).resizable().scaledToFit().padding(.all, 2).frame(width: 20, height: 20)
            if editName {
              TextField("", text: $editText)
                .introspect(.textField, on: .iOS(.v15, .v16, .v17), customize: { entity in
                  entity.clearButtonMode = .whileEditing
                })
                .focused($focused)
                .submitLabel(.done)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                  onChangeName()
                }
              Button("change".localized) {
                onChangeName()
              }
              Spacer.width(20)
            } else {
              Text(viewModel.userName).padding(.vertical, 5)
              Spacer()
            }
            if UserItem.source != .Tmp {
              Button {
                withAnimation {
                  editName.toggle()
                  if editName {
                    editText = viewModel.userName
                    focused = true
                  }
                }
              } label: {
                Image(systemName: "square.and.pencil").resizable().scaledToFit()
                  .foregroundColor(Colors.darkSlateGray.swiftColor).frame(width: 18, height: 18)
              }
            }
          }.padding(.horizontal, 15).padding(.vertical, 12)
          Divider()
        }
      }
      
      Button {
        viewModel.logout()
        onDismiss()
      } label: {
        HStack {
          Text("log_out".localized).kerning(2).font(.title3).foregroundColor(.red)
        }.padding(.vertical, 8).frame(maxWidth: .infinity).background(Colors.background.swiftColor).overlay {
          RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 0.5)
        }.cornerRadius(5)
      }.buttonStyle(BgClickableButton()).padding(.bottom, 50).padding(.horizontal, 30)
    }.navigationBarHidden(true)
      .modifier(AlertViewModifier(viewModel: viewModel))
      .onChange(of: viewModel.userLogin) { newValue in
        if !newValue && !viewModel.showFullAlert {
          onDismiss()
        }
      }
  }
}

#Preview {
  UserView()
}
