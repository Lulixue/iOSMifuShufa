//
//  PrivacyView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/21.
//
import Foundation
import SwiftUI
import UIKit


private var privacyAString: AttributedString? {
  if let file = Bundle.main.url(forResource: "privacy.txt", withExtension: nil) {
    if let data = try? Data(contentsOf: file) {
      let json = data.utf8String
      guard let html = json.toHtmlString(font: UIFont.preferredFont(forTextStyle: .body)) else { return nil }
      return try? AttributedString(html, including: \.uiKit)
    }
  }
  return nil
}

private var thirdPartyAString: AttributedString? {
  if let file = Bundle.main.url(forResource: "third_party_sdk.txt", withExtension: nil) {
    if let data = try? Data(contentsOf: file) {
      let json = data.utf8String
      guard let html = json.toHtmlString(font: UIFont.preferredFont(forTextStyle: .body)) else { return nil }
      return try? AttributedString(html, including: \.uiKit)
    }
  }
  return nil
}

struct ThirdPartyView: View {
  @Environment(\.presentationMode) var presentationMode
  let astr = thirdPartyAString
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "third_party_sdk".resString)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }.background(Colors.surfaceContainer.swiftColor)
      Divider()
      ScrollView {
        if let astr {
          Text(astr).textSelection(.enabled).padding()
        }
      }
    }.navigationBarHidden(true)
  }
}

struct PrivacyView: View {
  @Environment(\.presentationMode) var presentationMode
  let astr = privacyAString
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "privacy".resString)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }.background(Colors.surfaceContainer.swiftColor)
      Divider()
      ScrollView {
        if let astr {
          Text(astr).textSelection(.enabled).padding()
        }
      }
      Divider()
      NavigationLink {
        ThirdPartyView()
      } label: {
        HStack {
          Spacer()
          Text("third_party_sdk".resString).font(.callout)
            .foregroundStyle(.blue)
          Spacer()
        }.padding(.vertical, 8).background(Colors.surfaceContainer.swiftColor)
      }.buttonStyle(BgClickableButton())
    }.navigationBarHidden(true)
  }
}

#Preview {
  PrivacyView()
}

#Preview("third_party") {
  ThirdPartyView()
}
