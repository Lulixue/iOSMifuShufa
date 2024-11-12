//
//  ImagePreviewItem.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/8.
//

import SwiftUI
import SDWebImageSwiftUI


struct ImagePreviewItem: View {
  let image: BeitieImage
  var onTouchOutside: () -> Void = {}
  var onClick: () -> Void = {}
  @State private var loading = false
  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0
  private let maxZoom = 5.0
  private let minZoom = 0.3
  @State private var offsetX: CGFloat = 0
  @State private var offsetY: CGFloat = 0
  
  var body: some View {
    ZStack {
      ScrollView {
        VStack {
          Text("offsetX: \(offsetX)")
          Text("offsetY: \(offsetY)")
        }.foregroundStyle(.red)
      }.onTapGesture {
        onTouchOutside()
      }
      WebImage(url: image.url(.JpgCompressedThumbnail).url!) { img in
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
      .indicator(.activity).frame(alignment: loading ? .center : .topTrailing)
      .clipShape(RoundedRectangle(cornerRadius: 2))
      .scaleEffect(currentZoom + totalZoom)
      .gesture(MagnificationGesture().onChanged({ offset in
        currentZoom = offset - 1
      }).onEnded({ offset in
        totalZoom = max(min(totalZoom + currentZoom, maxZoom), minZoom)
        currentZoom = 0
      }))
      .gesture(DragGesture().onChanged({ val in
        println("offset \(val.translation)")
        offsetX = val.translation.width
        offsetY = val.translation.height
      }))
      .offset(x: offsetX, y: offsetY)
      .padding(10)
    }
  }
}

#Preview {
  ImagePreviewItem(image: BeitieDbHelper.shared.getWorkImages(2).first())
}
