  //
  //  AlbumPageViewController.swift
  //  OuyangxunDict
  //
  //  Created by Lulixue on 2020/2/8.
  //  Copyright © 2020 Lulixue. All rights reserved.
  //

import UIKit

protocol AlbumImageDelegate {
  func scrollToPage(_ page: Int)
}

class AlbumPageViewController: UIPageViewController , UIPageViewControllerDelegate, UIPageViewControllerDataSource {
  
  var albumDelegate: AlbumImageDelegate?
  var pages: [UIViewController] = []
  var parentSize: CGSize = .zero
  var afterScroll: (Int) -> Void = { _ in }
  
  override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey : Any]? = nil) {
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
      // Do any additional setup after loading the view.
    self.dataSource = self
    self.delegate = self
    view.backgroundColor = .black
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    
    if pages.count <= 1 {
      return nil
    }
    
    guard let viewControllerIndex = pages.firstIndex(of: viewController as! AlbumImageViewController) else {
      return nil
    }
    let previousIndex = viewControllerIndex - 1
    
      // User is on the first view controller and swiped left to loop to
      // the last view controller.
    guard previousIndex >= 0 else {
        //               return pages.last
        // Uncommment the line below, remove the line above if you don't want the page control to loop.
      return nil
    }
    
    guard pages.count > previousIndex else {
      return nil
    }
    
    let vc = pages[previousIndex]
      //         albumDelegate?.scrollToPage(previousIndex)
    return vc
  }
  func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    if let pendingIndex = pages.firstIndex(of: pendingViewControllers.first!) {
      albumDelegate?.scrollToPage(pendingIndex)
    }
  }
  var currentIndex = 0
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if (completed) {
      currentIndex = pageViewController.viewControllers?.first?.view.tag ?? 0
      printlnDbg("didFinishAnimating \(currentIndex)")
      afterScroll(currentIndex)
    }
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    
    if pages.count <= 1 {
      return nil
    }
    guard let viewControllerIndex = pages.firstIndex(of: viewController as! AlbumImageViewController) else {
      return nil
    }
    
    let nextIndex = viewControllerIndex + 1
    let orderedViewControllersCount = pages.count
    
      // User is on the last view controller and swiped right to loop to
      // the first view controller.
    guard orderedViewControllersCount != nextIndex else {
        //               return pages.first
        // Uncommment the line below, remove the line above if you don't want the page control to loop.
      return nil
    }
    
    guard orderedViewControllersCount > nextIndex else {
      return nil
    }
    
    let vc = pages[nextIndex]
    return vc
  }
  
  func getImage(index: Int) -> UIImage? {
    let vc = pages[index] as? AlbumImageViewController
    return vc?.albumImage.image
  }
  
  func scrollToPage(page: Int) {
    let firstViewController = pages[page]
    printlnDbg("scrollToPage \(page)")
    setViewControllers([firstViewController],
                       direction: currentIndex < page ? .reverse : .forward,
                       animated: true) { finished in
      if (finished) {
        self.currentIndex = page
        self.albumDelegate?.scrollToPage(page)
      }
    }
  }
  
  func initPages(items: [BeitieImage], initPage: Int = 0) {
    
    pages.removeAll()
    for i in 0..<items.count {
      let item = items[i]
      let aivc = AlbumImageViewController()
      aivc.view.tag = i
      aivc.initAlbumImage(item, parentSize)
      pages.append(aivc)
    }
  }
  
}
