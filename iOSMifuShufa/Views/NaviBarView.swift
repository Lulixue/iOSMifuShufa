//
//  NaviBarView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/8.
//

import SwiftUI

@ViewBuilder func BackButtonView(onBack: @escaping () -> Void) -> some View {
  Button {
    onBack()
  } label: {
    Image(systemName: "chevron.left").square(size: CUSTOM_NAVI_BACK_SIZE)
      .foregroundStyle(Color.colorPrimary)
  }.buttonStyle(.plain)
}

@ViewBuilder func NaviContents(title: Any, @ViewBuilder leading: @escaping () -> some View, @ViewBuilder trailing: @escaping () -> some View) -> some View {
  ZStack {
    HStack {
      leading()
      Spacer()
    }
    HStack {
      Spacer()
      NaviTitle(text: title)
      Spacer()
    }
    HStack {
      Spacer()
      trailing()
    }
  }
}

@ViewBuilder func NaviView(@ViewBuilder content: @escaping () -> some View) -> some View {
  HStack(spacing: 12) {
    content()
  }.padding(.horizontal, 10).frame(height: CUSTOM_NAVIGATION_HEIGHT)
}


@ViewBuilder func NaviTitle(text: Any) -> some View {
  if let title = text as? String {
    Text(title).font(.system(size: 18)).bold().foregroundStyle(.darkSlateGray)
  } else {
    Text(text as! AttributedString).foregroundStyle(.black)
  }
}
