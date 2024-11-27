//
//  SinglesView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/8.
//

import SwiftUI
import Foundation
import SDWebImageSwiftUI
import DeviceKit

class SingleViewModel: AlertViewModel {
  @Published var drawViewModel = DrawViewModel()
  let singles: List<BeitieSingle>
  @Published var showDrawPanel = false
  @Published var currentIndex: Int = 0
  @Published var orientation = UIDeviceOrientation.unknown
  var uiImage: UIImageView? = nil
  init(singles: List<BeitieSingle>, selected: Int = 0) {
    self.singles = singles
    self.currentIndex = selected
    super.init()
    drawViewModel.onCloseDraw = { [weak self] in
      self?.showDrawPanel = false
    }
  }
  
  
  func toggleDrawPanel() {
    showDrawPanel.toggle()
    if !showDrawPanel {
      drawViewModel.onReset()
    }
  }
  
  func saveSingle(single: BeitieSingle) {
    let uiImage = UIImageView(frame: .zero)
    uiImage.sd_setImage(with: single.url.url!) { image, error, t, _ in
      if let image {
        self.imageSaver.writeToPhotoAlbum(image: image)
      }
      self.uiImage = nil
    }
    self.uiImage = uiImage
  }
}

struct ToastView: View {
  let title: String
  var body: some View {
    HStack {
      Text(title)
        .foregroundStyle(.white)
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
    }.background(Color.darkSlateGray)
      .clipShape(RoundedRectangle(cornerRadius: 25))
  }
}

#Preview("toast") {
  ToastView(title: "hello")
}

struct SinglesView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel: SingleViewModel
  @StateObject var naviVM = NavigationViewModel()
  @StateObject var collectVM = CollectionViewModel.shared
  @State var scrollProxy: ScrollViewProxy? = nil
  @State var pageIndex = 0
  var singles: List<BeitieSingle> {
    viewModel.singles
  }
  var currentSingle: BeitieSingle {
    singles[viewModel.currentIndex]
  }
  private let bottomBarHeight: CGFloat = 80
  var naviView: some View {
    NaviView {
      let collected = collectVM.itemCollected(currentSingle)
      let title = {
        let s = currentSingle
        var t = AttributedString(s.showChars)
        var sub = AttributedString(" \(viewModel.currentIndex+1)/\(singles.size)")
        t.font = .title3
        sub.font = .footnote.bold()
        return t + sub
      }()
      BackButtonView {
        presentationMode.wrappedValue.dismiss()
      }
      Spacer()
      Text(title).foregroundStyle(.colorPrimary)
      Spacer()
      Button {
        let c = collected
        collectVM.toggleItem(currentSingle)
        viewModel.showToast(c ? "已取消收藏" : "已加入收藏")
        Task {
          try? await Task.sleep(nanoseconds: 2_000_000_000)
          DispatchQueue.main.async {
            viewModel.showToast = false
          }
        }
      } label: {
        Image(collected ? "collect_fill" : "collect").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE+1)
          .foregroundStyle(Color.colorPrimary)
      }
      Button {
        if currentSingle.work.matchVip {
          naviVM.gotoWork(work: currentSingle.work, index: (currentSingle.image?.index ?? 1) - 1)
        } else {
          viewModel.showConstraintVip("当前操作不支持，请联系客服".orCht("當前操作不支持，請聯繫客服"))
        }
      } label: {
        Image("big_image").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE)
          .foregroundStyle(Color.colorPrimary)
      }
      Button {
        viewModel.saveSingle(single: currentSingle)
      } label: {
        Image("download").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE)
          .foregroundStyle(Color.colorPrimary)
      }
    }
  }
  @State private var scrollFixed = false
  @ScrollState private var scrollState
  
  func syncScroll(_ index: Int) {
    let pageTo = index == singles.lastIndex ? index : (index - 1)
    self.scrollProxy?.scrollTo(max(pageTo, 0), anchor: .leading)
  }
  
  var body: some View {
    ZStack {
      content
    }.navigationBarHidden(true)
      .modifier(WorkDestinationModifier(naviVM: naviVM))
      .modifier(AlertViewModifier(viewModel: viewModel))
  }
  
  var rotation: Double {
    switch viewModel.orientation {
    case .portrait:
      0
    case .portraitUpsideDown:
      180
    case .landscapeLeft:
      90
    case .landscapeRight:
      270
    case .faceUp:
      0
    case .faceDown:
      0
    default:
      0
    }
  }
  var content: some View {
    VStack(spacing: 0) {
      naviView
      Divider()
      ZStack {
        TabView(selection: $pageIndex) {
          ForEach(0..<singles.size, id: \.self) { i in
            let single = singles[i]
            ZStack(alignment: .bottom) {
              Image("background").resizable().scaledToFill()
              SinglePreviewItem(single: single)
                .padding(40)
                .rotationEffect(.degrees(rotation))
              Text(single.work.workNameAttrStr(.system(size: 15))).foregroundStyle(.white)
                .padding(.bottom, 14)
            }.id(i)
          }
        }.tabViewStyle(.page(indexDisplayMode: .never))
        if viewModel.showDrawPanel {
          DrawPanel().environmentObject(viewModel.drawViewModel)
        }
        if viewModel.showToast {
          ToastView(title: viewModel.toastTitle)
        }
      }
      Divider()
      HStack(spacing: 0) {
        let single = currentSingle
        if single.repeat {
          Text("重复符号".orCht("重複符號")).font(.footnote).foregroundStyle(Color.colorPrimary)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background {
              RoundedRectangle(cornerRadius: 5).stroke(Color.colorPrimary, lineWidth: 0.5)
            }
        } else {
          
          Text("radical".localized).font(.footnote).foregroundStyle(Color.colorPrimary)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background {
              RoundedRectangle(cornerRadius: 5).stroke(Color.colorPrimary, lineWidth: 0.5)
            }
          Text(single.radical ?? UNKNOWN).padding(.leading, 5)
          8.HSpacer()
          Text("structure".localized).font(.footnote).foregroundStyle(Color.blue)
            .padding(.horizontal, 3).padding(.vertical, 1)
            .background {
              RoundedRectangle(cornerRadius: 5).stroke(Color.colorPrimary, lineWidth: 0.5)
            }
          Text(single.structure ?? UNKNOWN).padding(.leading, 5)
        }
        Spacer()
        NavigationLink {
          AnalyzeView(viewModel: AnalyzeViewModel(single))
        } label: {
          Image("analyze").renderingMode(.template).square(size: 23).foregroundStyle(.blue)
        }
        
        0.5.VDivideer(color: .gray).frame(height: 15)
          .padding(.horizontal, 10)
        Button {
          viewModel.toggleDrawPanel()
        } label: {
          Image("handwriting").square(size: 16).foregroundStyle(.blue)
        }
      }.padding(.horizontal, 10).padding(.vertical, 8).background(.white)
      Divider()
      ScrollView([.horizontal]) {
        ScrollViewReader { proxy in
          LazyHStack(spacing: 0) {
            ForEach(0..<singles.size, id: \.self) { i in
              let single = singles[i]
              let selected = i == viewModel.currentIndex
              HStack{
                Button {
                  scrollFixed = true
                  viewModel.currentIndex = i
                } label: {
                  WebImage(url: single.thumbnailUrl.url!) { img in
                    img.image?.resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(minWidth: 20, minHeight: bottomBarHeight - 20)
                      .clipShape(RoundedRectangle(cornerRadius: 2))
                      .padding(0.5)
                      .background {
                        RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .white, lineWidth: selected ? 4 : 0.5)
                      }.padding(.horizontal, 5)
                  }
                  .onSuccess(perform: { _, _, _ in
                    if !scrollFixed {
                      DispatchQueue.main.async {
                        syncScroll(pageIndex)
                      }
                    }
                  })
                  .indicator(.activity).tint(.white)
                  .onAppear {
                    if !scrollFixed {
                      DispatchQueue.main.async {
                        syncScroll(pageIndex)
                      }
                    }
                  }
                }
              }.id(i)
            }
          }.padding(.top, 10).padding(.bottom, Device.hasTopNotch ? 0 : 10).padding(.horizontal, 15).frame(height: bottomBarHeight)
            .onAppear {
              scrollProxy = proxy
            }
        }
      }
        .frame(height: bottomBarHeight)
        .scrollViewStyle(.defaultStyle($scrollState))
        .background(Color.singlePreviewBackground)
        .onChange(of: scrollState.isDragging, perform: { newValue in
          if newValue {
            self.scrollFixed = true
          }
        })
        .onChange(of: viewModel.currentIndex) { newValue in
          pageIndex = newValue
        }
        .onAppear {
          pageIndex = viewModel.currentIndex
        }
        .onChange(of: pageIndex) { newValue in
          if viewModel.currentIndex != newValue {
            scrollFixed = false
            viewModel.currentIndex = pageIndex
            syncScroll(newValue)
          }
        }.modifier(DeviceRotationViewModifier(action: { orientation in
          if !Device.current.isPad && AnalyzeHelper.shared.singleRotate {
            viewModel.orientation = orientation
          } else {
            viewModel.orientation = .unknown
          }
        }))
    }
  }
}

struct WorkDestinationModifier: ViewModifier {
  @StateObject var naviVM: NavigationViewModel
  func body(content: Content) -> some View {
    content.navigationDestination(isPresented: $naviVM.gotoWorkView) {
      if naviVM.gotoWorkView {
        WorkView(viewModel: naviVM.workVM!)
      }
    }
  }
}

struct SingleDestinationModifier: ViewModifier {
  @StateObject var naviVM: NavigationViewModel
  func body(content: Content) -> some View {
    content.navigationDestination(isPresented: $naviVM.gotoSingleView) {
      if naviVM.gotoSingleView {
        SinglesView(viewModel: naviVM.singleViewModel!)
      }
    }
  }
}

struct WorkIntroDestinationModifier: ViewModifier {
  @StateObject var naviVM: NavigationViewModel
  func body(content: Content) -> some View {
    content.navigationDestination(isPresented: $naviVM.gotoWorkIntroView) {
      if naviVM.gotoWorkIntroView {
        WorkIntroView(viewModel: naviVM.introWorkVM!)
      }
    }
  }
}

#Preview {
  let singles = BeitieDbHelper.shared.getSingles("人")
  return SinglesView(viewModel: SingleViewModel(singles: singles, selected: 10))
}
