//
//  WebView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/15.
//

import Foundation
import UIKit
import SwiftUI

class WebViewModel: BaseObservableObject {
  let title: String
  let url: URL
  
  init(title: String, url: String) {
    self.title = title
    self.url = url.url!
  }
  
  init(article: Article) {
    self.title = article.title
    self.url = article.url.url!
  }
}

struct WebSwiftView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel: WebViewModel
  @StateObject var webViewStore = WebViewStore()
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: webViewStore.title ?? viewModel.title)
        Spacer()
        Button(action: goBack) {
          Image(systemName: "arrow.left")
            .square(size: 20)
            .foregroundStyle(webViewStore.canGoBack ? Color.colorPrimary : .gray)
        }.disabled(!webViewStore.canGoBack).buttonStyle(.plain)
        Button(action: goSafari) {
          Image(systemName: "safari")
            .square(size: 20)
            .foregroundStyle(Color.colorPrimary)
        }.buttonStyle(.plain)
      }.background(Colors.surfaceVariant.swiftColor)
      Divider()
      WebView(webView: webViewStore.webView).onAppear {
        self.webViewStore.webView.load(URLRequest(url: viewModel.url))
      }
    }.navigationBarHidden(true)
      .ignoresSafeArea(edges: [.bottom])
  }
  
  func goBack() {
    webViewStore.webView.goBack()
  }
  
  func goSafari() {
    UIApplication.shared.open(viewModel.url)
  }
}

#Preview {
  WebSwiftView(viewModel: WebViewModel(title: "", url: "https://apple.com"))
}
