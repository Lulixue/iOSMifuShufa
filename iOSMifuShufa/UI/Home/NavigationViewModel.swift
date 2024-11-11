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
  
  @Published var gotoWork = false
  @Published var workVM: WorkViewModel!
  
  func gotoSingles(singles: [BeitieSingle], index: Int = 0) {
    singleViewModel = SingleViewModel(singles: singles, selected: index)
    gotoSingleView = true
  }
  
  func gotoWork(work: BeitieWork, index: Int = 0) {
    workVM = WorkViewModel(work: work, pageIndex: index)
    gotoWork = true
  }
}
