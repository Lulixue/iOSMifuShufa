//
//  SinglePreviewItem.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/7.
//
import SwiftUI
import SDWebImageSwiftUI


struct SinglePreviewItem: View {
  let single: BeitieSingle
  var bgColor = Color.black.opacity(0.6)
  var onTouchOutside: () -> Void = {}
  @State private var loading = false
  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0
  private let maxZoom = 5.0
  private let minZoom = 0.3
  
  var body: some View {
    ZStack {
      Color.clear
      WebImage(url: single.url.url!) { img in
        img.image?.resizable()
          .scaledToFit()
          .frame(minHeight: 20)
        
      }
      .onSuccess(perform: { image, data, cacheType in
        DispatchQueue.main.async {
          self.loading = false
        }
      })
      .indicator(.activity).frame(alignment: loading ? .center : .topTrailing)
      .clipShape(RoundedRectangle(cornerRadius: 2))
      .scaleEffect(currentZoom + totalZoom)
      .gesture(MagnificationGesture().onChanged({ offset in
        println("offset \(offset)")
        currentZoom = offset - 1
      }).onEnded({ offset in
        totalZoom = max(min(totalZoom + currentZoom, maxZoom), minZoom)
        currentZoom = 0
      })).padding(10)
    }
  }
}

#Preview {
  SinglePreviewItem(single: BeitieDbHelper.shared.getSingles("人").first())
}
