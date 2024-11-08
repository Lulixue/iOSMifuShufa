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
  @Published var work: BeitieWork! = nil
  @Published var imageIndex = 0
   
  
  func gotoSingles(singles: [BeitieSingle], index: Int = 0) {
    singleViewModel = SingleViewModel(singles: singles, selected: index)
    gotoSingleView = true
  }
}
