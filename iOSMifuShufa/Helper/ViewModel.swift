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
  
  func showToast(_ title: String) {
    toastTitle = title
    showToast = true
  }
  
  func showConstraintVip(_ text: String) {
    showFullAlert("VIP功能", text, okTitle: "开通VIP".orCht("開通VIP"), okRole: .destructive, ok: {
      
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
