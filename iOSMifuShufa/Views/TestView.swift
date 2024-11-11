//
//  TestView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/6.
//

import SwiftUI

struct TestView: View {
  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0
  private let maxZoom = 5.0
  private let minZoom = 0.3
  @State private var offsetX = 0.0
  @State private var offsetY = 0.0
  
  init() {
    let maxWidth = UIScreen.currentWidth - 20
    if maxWidth < imageSize.width {
      self.totalZoom = imageSize.width / maxWidth
    }
  }
  
  let imageSize = {
    let img = UIImage(named: "background")!
    let size = img.size
    return size
  }()
  @State var enabled = false
  var body: some View {
    ZStack {
      Color.white
      ProgressView().progressViewStyle(.circular).tint(.red)
        .font(.title)
        .scaleEffect(2)
    }
  }
  
  var stackView: some View {
    NavigationStack {
      ZStack(alignment: .topTrailing) {
        VStack {
          NavigationLink(isActive: $enabled) {
            Text("call")
          } label: {
            Image("background")
              .resizable()
              .scaleEffect(currentZoom + totalZoom)
              .scaledToFit()
              .padding(10)
              .gesture(MagnificationGesture().onChanged({ offset in
                println("offset \(offset)")
                currentZoom = offset - 1
              }).onEnded({ offset in
                totalZoom = max(min(totalZoom + currentZoom, maxZoom), minZoom)
                currentZoom = 0
              }))
            
            
              //            .gesture(DragGesture().onChanged({ drag in
              //              let offsetX = drag.translation.width
              //              let offsetY = drag.translation.height
              //              printlnDbg("offset: \(offsetX) \(offsetY)")
              //            }).onEnded({ drag in
              //
              //            }))
              //            .onAppear {
              //
              //            }
          }
        }.padding(10)
      }
    }
  }
}

#Preview {
  TestView()
}
