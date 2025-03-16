//
//  NavigationViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/8.
//
import SwiftUI

class NavigationViewModel : BaseObservableObject {
  @Published var gotoSingleView = false
  @Published var singleViewModel: SingleViewModel!
  
  @Published var gotoWorkView = false
  @Published var workVM: WorkViewModel!
  
  @Published var gotoWorkIntroView = false
  @Published var introWorkVM: WorkViewModel!
  
  @Published var gotoJiziView = false
  @Published var jiziVM: JiziViewModel!
  
  @Published var gotoPuzzleView = false
  @Published var puzzleVM: PuzzleViewModel!
  
  @Published var gotoWebView = false
  @Published var webViewModel: WebViewModel!
  
  @Published var gotoPdfView = false
  @Published var pdfViewModel: PdfViewModel!
  
  func gotoPuzzle(_ items: [JiziItem]) {
    puzzleVM = PuzzleViewModel(items: items)
    gotoPuzzleView = true
  }
  
  func gotoWeb(_ article: Article) {
    if article.url.contains(".pdf") {
      pdfViewModel = PdfViewModel(article: article)
      gotoPdfView = true
    } else {
      webViewModel = WebViewModel(article: article)
      gotoWebView = true
    }
  }
  
  func gotoCollectionSingles(_ collections: [CollectionItem], _ selected: Int) {
    Task {
      let singles = collections.map { BeitieDbHelper.shared.getSingleById(Int($0.collectionId)) }.filter { $0 != nil }
        .map { $0! }
      let viewModel = SingleViewModel(singles: singles, selected: selected)
      DispatchQueue.main.async {
        self.singleViewModel = viewModel
        self.gotoSingleView = true
      }
    }
  }
  
  func gotoCollectionWork(_ imageId: Int) {
    guard let image = BeitieDbHelper.shared.getImageById(imageId) else { return }
    gotoWork(work: image.work, index: image.index-1)
  }
  
  func gotoJizi(_ text: String, _ puzzles: [PuzzleItem]?, after: @escaping () -> Void) {
    Task {
      let items = JiziViewModel.search(text: text, newLog: false)
      DispatchQueue.main.async {
        if let puzzles {
          for i in 0..<items.size {
            items[i].syncWithPuzzleItem(puzzles[i])
          }
        }
        let vm = JiziViewModel(text: text, items: items)
        self.jiziVM = vm
        after()
        self.gotoJiziView = true
      }
    }
  }
  
  func gotoJizi(_ text: String, after: @escaping () -> Void) {
    Task {
      let items = JiziViewModel.search(text: text, newLog: true)
      DispatchQueue.main.async {
        let vm = JiziViewModel(text: text, items: items)
        self.jiziVM = vm
        after()
        self.gotoJiziView = true
      }
    }
  }
  
  func gotoSingles(singles: [BeitieSingle], index: Int = 0) {
    singleViewModel = SingleViewModel(singles: singles, selected: index)
    gotoSingleView = true
  }
  
  func gotoWork(work: BeitieWork, index: Int = 0) {
    workVM = WorkViewModel(work: work, pageIndex: index)
    gotoWorkView = true
  }
  
  func gotoWorkIntro(work: BeitieWork) {
    introWorkVM = WorkViewModel(work: work)
    gotoWorkIntroView = true
  }
  
}
