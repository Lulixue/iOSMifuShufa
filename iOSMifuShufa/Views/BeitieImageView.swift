//
//  BeitieImageView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/10.
//

import SwiftUI
import UIKit
//import Agrume

@available(iOS 14.0, *)
public struct BeitieImageView: View {
  private let path: String
  @Binding private var binding: Bool
  @Namespace var namespace
  
  public init(path: String, isPresenting: Binding<Bool>) {
    self.path = path
    self._binding = isPresenting
  }
  
  public var body: some View {
    WrapperBeitieImageView(images: [path], isPresenting: $binding)
      .matchedGeometryEffect(id: "AgrumeView", in: namespace, properties: .frame, isSource: binding)
      .ignoresSafeArea()
  }
}

@available(iOS 13.0, *)
struct WrapperBeitieImageView: UIViewControllerRepresentable {
  
  private let images: [String]
  @Binding private var binding: Bool
  
  public init(images: [String], isPresenting: Binding<Bool>) {
    self.images = images
    self._binding = isPresenting
  }
  
  public func makeUIViewController(context: UIViewControllerRepresentableContext<WrapperBeitieImageView>) -> UIViewController {
    let agrume = Agrume(images: images.map({ path in
      UIImage(contentsOfFile: path)!
    }))
    agrume.view.backgroundColor = .clear
    agrume.addSubviews()
//    agrume.addOverlayView()
    agrume.willDismiss = {
      withAnimation {
        binding = false
      }
    }
    return agrume
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController,
                                     context: UIViewControllerRepresentableContext<WrapperBeitieImageView>) {
  }
}
