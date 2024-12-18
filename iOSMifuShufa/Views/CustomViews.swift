//
//  CustomViews.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/28.
//

import SwiftUI

struct CalligrapherView: View {
  var body: some View {
    HStack(spacing: 0) {
      Image("mi").renderingMode(.template).resizable().frame(width: 21.5, height: 21.5)
        .foregroundStyle(Color.searchHeader)
        .rotationEffect(.degrees(5))
      3.HSpacer()
      Image("fu").renderingMode(.template).resizable().scaledToFill().frame(width: 20, height: 20).rotationEffect(.degrees(0))
        .foregroundStyle(Color.searchHeader)
    }
  }
}

struct SplashHeaderView: View {
  var body: some View {
    Image("tizi")
      .resizable()
      .scaledToFit()
  }
}

#Preview {
  CalligrapherView()
}

#Preview(body: {
  SplashHeaderView()
})
