//
//  JiziView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/12.
//
import SwiftUI


struct JiziView : View {
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          
        }
        Spacer()
        Text("title_jizi".localized).font(.title3)
          .foregroundStyle(Color.colorPrimary)
        Spacer()
        Button {
          
        } label: {
          Image("switches").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE-2)
            .foregroundStyle(Color.colorPrimary)
        }
      }.background(Colors.surfaceVariant.swiftColor)
      Divider()
      HStack {
        Button {
          
        } label: {
          HStack(spacing: 4) {
            
          }
        }
      }
      Spacer()
    }.navigationBarHidden(true)
  }
}


#Preview {
  JiziView()
}
