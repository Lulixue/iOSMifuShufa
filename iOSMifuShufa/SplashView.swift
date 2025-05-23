//
//  Splash.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/3.
//

import SwiftUI
import UIKit
import BUAdSDK
import MMKVCore
import MMKV
import Combine

class AdViewController: UIViewController, BUSplashAdDelegate, BUSplashCardDelegate,
                        BUSplashZoomOutDelegate {
  
  var finishAd: () -> Void = {}
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupBUAdSDK()
  }
  
  private var splashAd: BUSplashAd! = nil
  
  func addSplashAD() {
    let frame = view.frame
    let splashAd = BUSplashAd.init(slotID: CSJ_SPLASH_AD_ID, adSize: frame.size)
    splashAd.supportCardView = true
    splashAd.supportZoomOutView = true
    splashAd.delegate = self
    splashAd.cardDelegate = self
    splashAd.zoomOutDelegate = self
    splashAd.tolerateTimeout = 6
    self.splashAd = splashAd
    self.splashAd.loadData()
  }
  
  func setupBUAdSDK() {
    let configuration = BUAdSDKConfiguration.init()
    
    configuration.appID = CSJ_AD_ID
    BUAdSDKManager.start( asyncCompletionHandler: { success, error in
      if (success) {
        DispatchQueue.main.async {
          self.addSplashAD()
        }
      } else {
        self.finishAd()
      }
    })
  }
  
  func splashAdLoadSuccess(_ splashAd: BUSplashAd) {
    print("splashAdLoadSuccess")
    showAd(splashAd)
  }
  
  func splashAdLoadFail(_ splashAd: BUSplashAd, error: BUAdError?) {
    print("error: \(String(describing: error?.description))")
    self.finishAd()
  }
  
  func showAd(_ splashAd: BUSplashAd) {
    splashAd.showSplashView(inRootViewController: self)
  }
  
  func splashAdRenderSuccess(_ splashAd: BUSplashAd) {
    print("splashAdRenderSuccess")
  }
  
  func splashAdRenderFail(_ splashAd: BUSplashAd, error: BUAdError?) {
    print("splashAdRenderFail")
  }
  
  func splashAdWillShow(_ splashAd: BUSplashAd) {
    print("splashAdWillShow")
  }
  
  func splashAdDidShow(_ splashAd: BUSplashAd) {
    print("splashAdDidShow")
  }
  
  func splashAdDidClick(_ splashAd: BUSplashAd) {
    print("splashAdDidClick")
  }
  
  func splashAdDidClose(_ splashAd: BUSplashAd, closeType: BUSplashAdCloseType) {
    print("splashAdDidClose")
  }
  
  func splashAdViewControllerDidClose(_ splashAd: BUSplashAd) {
    print("splashAdViewControllerDidClose")
    finishAd()
  }
  
  func splashDidCloseOtherController(_ splashAd: BUSplashAd, interactionType: BUInteractionType) {
    print("splashDidCloseOtherController")
  }
  
  func splashVideoAdDidPlayFinish(_ splashAd: BUSplashAd, didFailWithError error: Error?) {
    print("splashVideoAdDidPlayFinish")
  }
  
  func splashCardReady(toShow splashAd: BUSplashAd) {
    print("splashCardReady")
    showAd(splashAd)
  }
  
  func splashCardViewDidClick(_ splashAd: BUSplashAd) {
    print("splashCardViewDidClick")
  }
  
  func splashCardViewDidClose(_ splashAd: BUSplashAd) {
    print("splashCardViewDidClose")
  }
  
  func splashZoomOutReady(toShow splashAd: BUSplashAd) {
    print("splashZoomOutReady")
    showAd(splashAd)
  }
  
  func splashZoomOutViewDidClick(_ splashAd: BUSplashAd) {
    print("splashZoomOutViewDidClick")
  }
  
  func splashZoomOutViewDidClose(_ splashAd: BUSplashAd) {
    print("splashZoomOutViewDidClose")
  }
}

struct AdView: UIViewControllerRepresentable {
  typealias UIViewControllerType = AdViewController
  var finishAd: () -> Void = {}
  
  func makeUIViewController(context: Context) -> AdViewController {
      // Return MyViewController instance
    let vc = AdViewController()
    vc.finishAd = finishAd
    
    return vc
  }
  
  func updateUIViewController(_ uiViewController: AdViewController, context: Context) {
      // Updates the state of the specified view controller with new information from SwiftUI.
  }
}

class SplashViewModel: AlertViewModel {
  @Published var progress = 0.1
  @Published var status = "loading_data".localized
  @Published var showAd = Settings.showAdiOS
  @Published var adReady = false
  @Published var resourceReady = false
  @Published var gotoMain = false
  
  private func onErrorQuit() {
    DispatchQueue.main.async {
      self.showAlertDlg("app_resource_fail".localized)
    }
  }
  
  func finishResource() {
    debugPrint("finishResource")
    resourceReady = true
    if (adReady) {
      gotoMain = true
    }
  }
  
  func finishAd() {
    debugPrint("finishAd")
    adReady = true
    if (resourceReady) {
      gotoMain = true
    }
  }
  
  init(preview: Bool = false) {
    super.init()
    if (preview) {
      finishAd()
      return
    }
    let _ = Settings.mmkv
    #if DEBUG
    finishAd()
    #else
    if !showAd || CurrentUser.isVip {
      finishAd()
    }
    #endif
    Task {
      if ResourceHelper.hasResourceUpdate() {
        DispatchQueue.main.async {
          self.status = "updating_data".localized
          self.progress = 0.2
        }
        if (!ResourceHelper.extractDefaultResources()) {
          onErrorQuit()
          return
        }
      }
      ResourceHelper.installCustomFonts()
      DispatchQueue.main.async {
        self.progress = 0.7
        self.finishResource()
      }
    }
  }
  
}

struct SplashView: View {
  @StateObject var viewModel: SplashViewModel = SplashViewModel()
  @Environment(\.presentationMode) var presentationMode
  
  func onFinishAd() {
    DispatchQueue.main.async {
      withAnimation {
        viewModel.showAd = false
      }
      viewModel.finishAd()
    }
  }
  var splashView: some View {
    ZStack {
      Color.background
      VStack {
        SplashHeaderView()
        ProgressView(value: viewModel.progress)
        Text(viewModel.status)
          .foregroundStyle(Color.searchHeader)
          .onTapGesture {
#if DEBUG
            viewModel.gotoMain = true
#endif
          }
        (UIScreen.currentHeight*0.1).VSpacer()
      }.frame(width: 200)
      
      if !CurrentUser.isVip && viewModel.showAd {
        VStack {
          AdView(finishAd: onFinishAd)
          20.VSpacer()
          HStack {
            Image(uiImage: Bundle.main.icon!).resizable()
              .scaledToFit()
              .frame(width: 35, height: 35)
              .clipShape(Circle())
            Text("app_name".resString)
              .foregroundStyle(.black.opacity(0.75))
          }.overlay(
            Rectangle().fill(Colors.defaultText.swiftColor.opacity(0.55)).padding(.horizontal, 0).frame(height: 0.3).offset(y: 5), alignment: .bottom).padding(.vertical, 5)
          Text("广告勿轻信，勿随意点击".orCht("廣告勿輕信，勿隨意點擊"))
            .font(.footnote)
            .foregroundStyle(.souyun)
          40.VSpacer()
        }.background(Color.background)
      }
    }.ignoresSafeArea()
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .modifier(AlertViewModifier(viewModel: viewModel))
  }
  
  var body: some View {
    NavigationStack {
      if viewModel.gotoMain {
        ContentView()
      } else {
        splashView
      }
    }
    .navigationViewStyle(.stack)
  }
}

#Preview {
  SplashView(viewModel: SplashViewModel(preview: true))
}
