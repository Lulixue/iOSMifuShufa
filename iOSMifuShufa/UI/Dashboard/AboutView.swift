//
//  AboutView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/16.
//

import SwiftUI
import Foundation
 
extension Bundle {
  var icon: UIImage? {
    if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
       let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let files = primary["CFBundleIconFiles"] as? [String],
       let icon = files.last
    {
      return UIImage(named: icon)
    }
    return nil
  }
  var appVersion: String {
    self.infoDictionary?["CFBundleShortVersionString"] as! String
  }
}

var ABOUT_ATTR_STR: AttributedString {
  let html = ABOUT_TEXT.toHtmlString(font: UIFont.preferredFont(forTextStyle: .body))!
  return try! AttributedString(html, including: \.uiKit)
}

struct AboutView: View {
  @Environment(\.presentationMode) var presentationMode
  
  
  @State private var attrStr: AttributedString! = nil
  
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "about_Mifu".resString)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }.background(Colors.background.swiftColor)
      Divider()
      contents
    }.navigationBarHidden(true)
      .onAppear {
        attrStr = ABOUT_ATTR_STR
      }
  }
  
  var contents: some View {
    ScrollView {
      VStack(spacing: 0) {
        Image(uiImage: Bundle.main.icon!).resizable()
          .scaledToFit()
          .frame(width: 50, height: 50)
          .padding(.top, 45)
        Spacer.height(12)
        Text("app_name".localized).font(.system(size: 17))
          .foregroundColor(Colors.colorPrimary.swiftColor)
          .kerning(1)
        Spacer.height(2)
        Text("v\(Bundle.main.appVersion)")
          .foregroundColor(.gray)
        Spacer.height(25)
        VStack(alignment: .leading) {
          if let attrStr {
            Text(attrStr)
              .padding(.horizontal, 15)
          }
        }.frame(maxWidth: .infinity)
      }.frame(maxWidth: .infinity)
    }
  }
}

#Preview {
  AboutView()
}
