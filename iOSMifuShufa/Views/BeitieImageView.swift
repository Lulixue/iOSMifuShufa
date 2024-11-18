//
//  BeitieImageView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/10.
//

import SwiftUI
import UIKit

public struct ZoomImages: View {
  let images: [UIImage]
  let parentSize: CGSize
  @Binding var pageIndex: Int
  let bgColor: UIColor
  
  public var body: some View {
    WrappedZoomImageView(images: images, parentSize: parentSize, pageIndex: $pageIndex, bgColor: bgColor)
      .frame(width: parentSize.width, height: parentSize.height)
  }
}

struct WrappedZoomImageView: UIViewControllerRepresentable {
  let images: [UIImage]
  let parentSize: CGSize
  @Binding var pageIndex: Int
  let bgColor: UIColor
  
  func makeUIViewController(context: Context) -> AlbumPageViewController {
    let page = AlbumPageViewController()
    page.parentSize = parentSize
    page.bgColor = bgColor
    page.initPages(images: images, initPage: pageIndex)
    page.scrollToPage(page: pageIndex)
    page.afterScroll = { index in
      if pageIndex != index {
        pageIndex = index
      }
    }
    return page
  }
  
  func updateUIViewController(_ uiViewController: AlbumPageViewController, context: Context) {
    printlnDbg("updateUIViewController \(uiViewController.currentIndex) : \(pageIndex)")
    if uiViewController.currentIndex != pageIndex {
      uiViewController.scrollToPage(page: pageIndex)
    }
  }
  
  typealias UIViewControllerType = AlbumPageViewController
  
}


public struct BeitieGallerView: View {
  let images: [BeitieImage]
  let parentSize: CGSize
  @Binding var pageIndex: Int
  @Binding var galleryScroll: Bool
  
  public var body: some View {
    WrapperImagePagesView(images: images, parentSize: parentSize, pageIndex: $pageIndex, galleryScroll: $galleryScroll)
      .frame(width: parentSize.width, height: parentSize.height)
  }
}
extension UIViewController {
  func embed(_ viewController: UIViewController, inView view: UIView) {
    addChild(viewController)
    viewController.willMove(toParent: self)
    viewController.view.frame = view.bounds
    view.addSubview(viewController.view)
    viewController.didMove(toParent: self)
  }
}

extension UIView {
  func embed(_ viewController: UIViewController) {
    viewController.view.frame = bounds
    addSubview(viewController.view)
  }
}

struct WrapperImagePagesView: UIViewControllerRepresentable {
  let images: [BeitieImage]
  let parentSize: CGSize
  @Binding var pageIndex: Int
  @Binding var galleryScroll: Bool
  
  func makeUIViewController(context: Context) -> AlbumPageViewController {
    let page = AlbumPageViewController()
    page.parentSize = parentSize
    page.initPages(items: images, initPage: pageIndex)
    page.scrollToPage(page: pageIndex)
    page.afterScroll = { index in
      galleryScroll = true
      if pageIndex != index {
        pageIndex = index
      }
    }
    return page
  }
  
  func updateUIViewController(_ uiViewController: AlbumPageViewController, context: Context) {
    printlnDbg("updateUIViewController \(uiViewController.currentIndex) : \(pageIndex)")
    if uiViewController.currentIndex != pageIndex {
      uiViewController.scrollToPage(page: pageIndex)
    }
  }
  
  typealias UIViewControllerType = AlbumPageViewController
  
}

