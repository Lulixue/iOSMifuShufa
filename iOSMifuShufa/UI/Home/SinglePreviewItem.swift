//
//  SinglePreviewItem.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/7.
//
import SwiftUI
import SDWebImageSwiftUI
import DeviceKit


struct SinglePreviewItem: View {
  let single: BeitieSingle
  var onTouchOutside: () -> Void = {}
  var onClick: () -> Void = {}
  @State private var loading = false
  @State private var currentZoom = 0.0
  @State private var totalZoom = Device.current.isPad ? 0.5 : 0.95
  private let maxZoom = 5.0
  private let minZoom = 0.3
  
  var body: some View {
    ZStack {
      ScrollView {
        
      }.onTapGesture {
        onTouchOutside()
      }
      WebImage(url: single.url.url!) { img in
        img.image?.resizable()
          .scaledToFit()
          .frame(minHeight: 20)
          .onTapGesture {
            onClick()
          }
      }
      .onSuccess(perform: { image, data, cacheType in
        DispatchQueue.main.async {
          self.loading = false
        }
      })
      .indicator(.activity).tint(.white).frame(alignment: loading ? .center : .topTrailing)
      .clipShape(RoundedRectangle(cornerRadius: 2))
      .scaleEffect(currentZoom + totalZoom)
      .gesture(MagnificationGesture().onChanged({ offset in
        debugPrint("offset \(offset)")
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
