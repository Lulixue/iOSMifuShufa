//
//  ViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//
import SwiftUI
import UIKit

open class BaseObservableObject: ObservableObject {
#if DEBUG
  init() {
    println("\(NSStringFromClass(type(of: self))) init")
  }
  deinit {
    println("\(NSStringFromClass(type(of: self))) deinit")
  }
#endif
}


class AlertViewModel: BaseObservableObject {
  @Published var showToast: Bool = false
  @Published var toastTitle: String = ""
  
  @Published var nextAlert: Bool = false
  @Published var nextTitle: String = ""
  @Published var nextMessage: String = ""
  
  @Published var showFullAlert: Bool = false
  @Published var fullAlertTitle: String = ""
  @Published var fullAlertMsg: String? = nil
  @Published var fullAlertCancelTitle: String? = nil
  @Published var fullAlertOkTitle: String = ""
  @Published var okButtonRole = ButtonRole.destructive
  @Published var cancelButtonRole = ButtonRole.cancel
  
  @Published var fullAlertOk: () -> Void = {}
  @Published var fullAlertCancle: () -> Void = {}
  
  func showFullAlert(_ title: String, _ msg: String? = nil,
                     okTitle: String = "好",
                     okRole: ButtonRole = .cancel,
                     ok: @escaping () -> Void = {},
                     cancelTitle: String? = nil,
                     cancelRole: ButtonRole = .cancel,
                     cancel: @escaping () -> Void = {}) {
    
    fullAlertTitle = title
    fullAlertMsg = msg
    
    fullAlertOkTitle = okTitle
    okButtonRole = okRole
    fullAlertOk = ok
    
    fullAlertCancelTitle = cancelTitle
    cancelButtonRole = cancelRole
    fullAlertCancle = cancel
    
    showFullAlert = true
  }
  
  func showAlertDlg(_ title: String) {
    showFullAlert(title)
  }
  func showAppDialog(_ title: String) {
    showAlertDlg(title)
  }
  func showMessageDialog(_ title: String) {
    showAlertDlg(title)
  }
  
  func showToast(_ title: String) {
    toastTitle = title
    showToast = true
    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      DispatchQueue.main.async {
        self.showToast = false
      }
    }
  }
  
  func showConstraintVip(_ text: String) {
    showFullAlert("功能不可用", text, okTitle: "联系客服".orCht("聯繫客服"), okRole: .destructive, ok: {
      DispatchQueue.main.async {
        UIPasteboard.general.string = "sf_lulixue"
        self.nextTitle = "客服微信号(sf_lulixue)已拷贝到剪贴板".orCht("客服微信號(sf_lulixue)已拷貝到剪貼板")
        self.nextAlert = true
      }
    }, cancelTitle: "取消")
  }
  
  func checkUpdate() {
    showFullAlert(DashboardRow.update.name, "是否前往应用商店检测更新".orCht("是否前往應用商店檢查更新"), okTitle: "前往",
                  okRole: .destructive, ok: {
      Utils.gotoAppStore()
    }, cancelTitle: "cancel".resString)
  }
  
  func rateApp() {
    showFullAlert("rate_app".resString, "tell_us_what_you_think".resString, okTitle: "i_think_good".localized, okRole: .destructive, ok: {
      Utils.gotoAppStore()
    }, cancelTitle: "取消")
  }
  
  func verifySearchText(text: String) -> Boolean {
    if text.isEmpty() {
      showAlertDlg("search_text_is_empty".resString)
      return false
    }
    if !text.containsChineseChar {
      showAlertDlg("no_available_chinese".resString)
      return false
    }
    return true
  }
}
