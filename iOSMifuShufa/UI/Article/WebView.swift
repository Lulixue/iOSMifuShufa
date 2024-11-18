//
//  WebView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/15.
//

import Foundation
import UIKit
import SwiftUI

struct WebSwiftView: View {
  var title: String = ""
  var url: URL = "https://apple.com".url!
  @StateObject var webViewStore = WebViewStore()
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          goBack()
        }
        Spacer()
        NaviTitle(text: webViewStore.title ?? title)
        Spacer()
        Button(action: goBack) {
          Image(systemName: "arrow.left")
            .square(size: 20)
            .foregroundStyle(webViewStore.canGoBack ? Color.colorPrimary : .gray)
        }.disabled(!webViewStore.canGoBack)
        Button(action: goSafari) {
          Image(systemName: "safari")
            .square(size: 20)
            .foregroundStyle(Color.colorPrimary)
        }
      }.background(Colors.surfaceVariant.swiftColor)
      Divider()
      WebView(webView: webViewStore.webView).onAppear {
        self.webViewStore.webView.load(URLRequest(url: url))
      }
    }.navigationBarHidden(true)
  }
  
  func goBack() {
    webViewStore.webView.goBack()
  }
  
  func goSafari() {
    UIApplication.shared.open(url)
  }
}

#Preview {
  WebSwiftView()
}
