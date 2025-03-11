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

extension BeitieSingle {
  var miGridViewModel: MiGridZoomableViewModel {
    let grid = MiGridViewModel.shared.singleType
    let centroid = MiGridViewModel.shared.centroidMi
    let matchVip = self.work.matchVip
    return MiGridZoomableViewModel(single: self, grid: matchVip ? grid : .Original, centroid: matchVip && centroid)
  }
}

class SingleViewModel: AlertViewModel {
  @Published var drawViewModel = DrawViewModel()
  let singles: List<BeitieSingle>
  @Published var gotoAnalyze = false
  @Published var showDrawPanel = false
  @Published var currentIndex: Int = 0
  @Published var orientation = UIDeviceOrientation.unknown
  @Published var singleViewModels = [BeitieSingle: MiGridZoomableViewModel]()
  @Published var singleThumbnailImages = [BeitieSingle: UIImage]()
  private var singleThumbnailViews = [BeitieSingle: UIImageView]()
  var uiImage: UIImageView? = nil
  init(singles: List<BeitieSingle>, selected: Int = 0) {
    self.singles = singles
    self.currentIndex = selected
    super.init()
    drawViewModel.onCloseDraw = { [weak self] in
      self?.showDrawPanel = false
    }
    syncViewModels()
  }
  
  func loadThumbnailImage(single: BeitieSingle) {
    if singleThumbnailViews[single] != nil {
      return
    }
    let imgView = UIImageView(frame: .zero)
    singleThumbnailViews[single] = imgView
    debugPrint("download thumbnail \(single.fileName)")
    Task {
      await imgView.sd_setImage(with: single.thumbnailUrl.url!) { img, _, _, _ in
        if let img {
          DispatchQueue.main.async {
            self.singleThumbnailImages[single] = img
          }
        }
      }
    }
  }
  

  func syncViewModels() {
    var map = [BeitieSingle: MiGridZoomableViewModel]()
    singles.forEach { single in
      map[single] = single.miGridViewModel
    }
    DispatchQueue.main.async {
      self.singleViewModels = map
      
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
 
struct SingleMiGridView: View {
  @ObservedObject var miViewModel = MiGridViewModel.shared
  
  var body: some View {
    ScrollView([.horizontal]) {
      LazyHStack(spacing: 0) {
        10.HSpacer()
        HStack(spacing: 0) {
          Text("重心\n米字格").font(.system(size: 12))
            .foregroundStyle(.white)
          Toggle(isOn: miViewModel.centroidBinding) {
          }.scaleEffect(CGSize(width: 0.7, height: 0.7))
            .colorScheme(.dark)
        }.padding(.horizontal, 6).padding(.vertical, 4)
          .padding(1)
          .background{
            RoundedRectangle(cornerRadius: 5).stroke(.white, lineWidth: 1)
          }.background(.black.opacity(0.65)).clipShape(RoundedRectangle(cornerRadius: 5))
        10.HSpacer()
        ForEach(SingleAnalyzeType.allCases, id: \.self) { t in
          let selected = t == miViewModel.singleType
          if let image = miViewModel.demoImages[t] {
            Button {
              if t.reachCountMax {
                miViewModel.showConstraintVip(ConstraintItem.CentroidMiCount.topMostConstraintMessage)
              } else {
                miViewModel.singleType = t
              }
            } label: {
              Image(uiImage: image).renderingMode(.original)
                .resizable().scaledToFit()
                .contentShape(RoundedRectangle(cornerRadius: 5))
                .clipped()
                .padding(selected ? 2.5 : 1)
                .background(selected ? .red : .white)
                .contentShape(RoundedRectangle(cornerRadius: 5))
                .clipped()
                .padding(.trailing, 10)
            }.buttonStyle(.plain)
          }
        }
        10.HSpacer()
      }.padding(.vertical, 8)
    }.background(.singlePreviewBackground).frame(height: 56)
      .modifier(AlertViewModifier(viewModel: miViewModel))
  }
}

extension BeitieSingle {
  var vipBeitie: String {
    "【\(work.chineseFolder())】\("为VIP碑帖，是否开通VIP继续？".orCht("為VIP碑帖，是否開通VIP繼續？"))"
  }
}

struct SinglesView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel: SingleViewModel
  @StateObject var naviVM = NavigationViewModel()
  @StateObject var collectVM = CollectionViewModel.shared
  @StateObject var miViewModel = MiGridViewModel.shared
  @State var scrollProxy: ScrollViewProxy? = nil
  @State var pageIndex = 0
  @State var showMiGrid = false
  var singles: List<BeitieSingle> {
    viewModel.singles
  }
  var currentSingle: BeitieSingle {
    singles[viewModel.currentIndex]
  }
  private let bottomBarHeight: CGFloat = 80
  
  var vipBeitie: String {
    currentSingle.vipBeitie
  }
  
  
  func syncVipToast(single: BeitieSingle) {
    if miViewModel.onlyVipSupported && single.work.notMatchVip {
      viewModel.showToast("碑帖「\(single.work.chineseFolder())」不支持当前米字格".orCht("碑帖「\(single.work.chineseFolder())」不支持當前米字格"))
    }
  }
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
      }.buttonStyle(.plain)
      Button {
        if currentSingle.work.matchVip {
          naviVM.gotoWork(work: currentSingle.work, index: (currentSingle.image?.index ?? 1) - 1)
        } else {
          viewModel.showConstraintVip(vipBeitie)
        }
      } label: {
        Image("big_image").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE)
          .foregroundStyle(Color.colorPrimary)
      }.buttonStyle(.plain)
      Button {
        if currentSingle.work.notMatchVip {
          viewModel.showConstraintVip(vipBeitie)
        } else {
          if let image = viewModel.singleViewModels[currentSingle]?.image {
            viewModel.imageSaver.writeToPhotoAlbum(image: image)
          }
        }
      } label: {
        Image("download").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE)
          .foregroundStyle(Color.colorPrimary)
      }.buttonStyle(.plain)
    }
  }
  @State private var scrollFixed = false
  @ScrollState private var scrollState
  
  func syncScroll(_ index: Int) {
    let pageTo = index == singles.lastIndex ? index : (index - 1)
    self.scrollProxy?.scrollTo(max(pageTo, 0), anchor: .leading)
  }
  var vDivider: some View {
    0.5.VDivideer(color: .pullerBar).frame(height: 15)
      .padding(.horizontal, 10)
  }
  
  var body: some View {
    NavigationStack {
      ZStack {
        content
        if viewModel.showToast {
          ToastView(title: viewModel.toastTitle)
        }
      }.navigationBarHidden(true)
        .modifier(WorkDestinationModifier(naviVM: naviVM))
        .modifier(AlertViewModifier(viewModel: viewModel))
        .onDisappear {
          miViewModel.reset()
        }
    }.navigationDestination(isPresented: $viewModel.gotoVip) {
      VipPackagesView()
    }.navigationDestination(isPresented: $viewModel.gotoAnalyze) {
      if (viewModel.gotoAnalyze) {
        AnalyzeView(viewModel: AnalyzeViewModel(currentSingle))
      }
    }
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
              if let vm = viewModel.singleViewModels[single] {
                MiGridZoomableImageView(viewModel: vm, onGotoVip: {
                  viewModel.gotoVip = true
                })
                  .padding(40)
                  .rotationEffect(.degrees(rotation))
              } else {
                Spacer()
              }
              VStack {
                if (single.notMatchVip) {
                  VipHdSingle(viewModel: viewModel)
                }
                Text(single.work.workNameAttrStr(.system(size: 15))).foregroundStyle(.white)
                  .padding(.bottom, 14)
              }
            }.tag(i)
          }
        }.tabViewStyle(.page(indexDisplayMode: .never))
          .id(miViewModel.singleType.toString() + miViewModel.centroidMi.description.toString())
        if viewModel.showDrawPanel {
          DrawPanel().environmentObject(viewModel.drawViewModel)
        }
      }.onChange(of: miViewModel.singleType) { newValue in
        viewModel.syncViewModels()
        syncVipToast(single: currentSingle)
      }.onChange(of: miViewModel.centroidMi) { newValue in
        viewModel.syncViewModels()
        syncVipToast(single: currentSingle)
      }.onChange(of: viewModel.currentIndex) { _ in
        syncVipToast(single: currentSingle)
      }
      Divider()
      if showMiGrid {
        SingleMiGridView(miViewModel: miViewModel)
        Divider()
      }
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
        Button {
          if single.matchVip {
            viewModel.gotoAnalyze = true
          } else {
            viewModel.showConstraintVip(vipBeitie)
          }
        } label: {
          Image("analyze").renderingMode(.template).square(size: 23).foregroundStyle(.blue)
        }.buttonStyle(.plain)
        vDivider
        Button {
          withAnimation(.linear(duration: 0.2)) {
            showMiGrid.toggle()
          }
        } label: {
          Image("mi_mi").renderingMode(.template).square(size: 23).foregroundStyle(.blue)
            .opacity(showMiGrid ? 0.5 : 1)
        }.buttonStyle(.plain)
        vDivider
        Button {
          viewModel.toggleDrawPanel()
        } label: {
          Image("handwriting").square(size: 16).foregroundStyle(.blue)
        }.buttonStyle(.plain)
      }.padding(.horizontal, 10).padding(.vertical, 8).background(.white)
      Divider()
      ScrollView([.horizontal]) {
        ScrollViewReader { proxy in
          LazyHStack(spacing: 0) {
            ForEach(0..<singles.size, id: \.self) { i in
              let single = singles[i]
              Button {
                scrollFixed = true
                viewModel.currentIndex = i
              } label: {
                if let thumbnail = viewModel.singleThumbnailImages[single] {
                  let selected = i == viewModel.currentIndex
                  Image(uiImage: thumbnail).resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minWidth: 20, minHeight: bottomBarHeight - 20)
                    .contentShape(RoundedRectangle(cornerRadius: 2))
                    .clipped()
                    .padding(0.5)
                    .background {
                      RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .white, lineWidth: selected ? 4 : 0.5)
                    }.padding(.horizontal, 5)
                    .onAppear {
                        if !scrollFixed {
                          DispatchQueue.main.async {
                            syncScroll(pageIndex)
                          }
                        }
                    }
                } else {
                  HStack {
                    Color.darkSlateGray
                  }
                  .clipShape(RoundedRectangle(cornerRadius: 5)).padding(0.5).background{
                    RoundedRectangle(cornerRadius: 5).stroke(.white, lineWidth: 0.5)
                  }.frame(width: 30, height: bottomBarHeight - 20)
                    .onAppear {
                      viewModel.loadThumbnailImage(single: single)
                    }.padding(.horizontal, 5)
                }
              }.buttonStyle(.plain).tag(i)
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
          if !Device.current.isPad && AnalyzeHelper.singleRotate {
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
