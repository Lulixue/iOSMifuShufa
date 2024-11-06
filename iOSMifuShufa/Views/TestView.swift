//
//  TestView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/6.
//

import SwiftUI

struct TestView: View {
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Text(".").frame(width: 80, height: 80)
      Text("v").font(.footnote) 
    }.padding(0).frame(width: 80, height: 80).background(Color.secondary)
  }
}

#Preview {
  TestView()
}
