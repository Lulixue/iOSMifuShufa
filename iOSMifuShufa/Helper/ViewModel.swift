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
  @Published var showAlert: Bool = false
  @Published var alertTitle: String = ""
  func showAlertDlg(_ title: String) {
    alertTitle = title
    showAlert = true
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
