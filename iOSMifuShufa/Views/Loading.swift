//
//  Loading.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/4.
//
import SwiftUI

struct LoadingView: View {
  @Binding var title: String
  var bgColor = Color.clear
  var body: some View {
    VStack(alignment: .center) {
      Spacer()
      VStack(alignment: .center) {
        ProgressView()
          .scaledToFill()
          .scaleEffect(x: 2, y: 2, anchor: .center)
          .progressViewStyle(.circular)
          .frame(width: 40, height: 40)
          .fixedSize()
        Spacer.height(10)
        Text(title).font(.body).foregroundColor(Colors.colorPrimary.swiftColor)
      }.padding(.horizontal, 30)
        .padding(.vertical, 30).background(.white)
        .cornerRadius(10)
        .shadow(radius: 1)
        .frame(maxWidth: .infinity)
      Spacer()
    }.background(bgColor).frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
