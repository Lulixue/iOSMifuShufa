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
  @Published var webUrl: URL!
  @Published var webTitle: String = ""
  
  func gotoPuzzle(_ items: [JiziItem]) {
    puzzleVM = PuzzleViewModel(items: items)
    gotoPuzzleView = true
  }
  
  func gotoWeb(_ article: Article) {
    webUrl = article.url.url!
    webTitle = article.title
    gotoWebView = true
  }
  
  func gotoJizi(_ text: String, after: @escaping () -> Void) {
    Task {
      let items = JiziViewModel.search(text: text)
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
