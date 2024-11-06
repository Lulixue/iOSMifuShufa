//
//  Untitled.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//

import SwiftUI
import ImageViewerRemote

struct WorkView: View {
  @State var showImageViewer: Bool = true
  @State var imgURL: String = "https://fastly.picsum.photos/id/12/200/200.jpg"
  
  var attributeStr = {
    var astr = AttributedString("hello world")
    return astr
  }()
  
  var body: some View {
    VStack {
      Text(attributeStr).foregroundStyle(.red).font(.title)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
//    .overlay(ImageViewerRemote(imageURL: self.$imgURL, viewerShown: self.$showImageViewer))
  }
}

#Preview {
  WorkView()
}
