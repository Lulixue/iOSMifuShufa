//
//  Untitled.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//

import SwiftUI
import SDWebImageSwiftUI
 
extension CGFloat {
  static let KB: CGFloat = 1024
  static let MB: CGFloat = KB * 1024
  static let GB: CGFloat = MB * 1024
  
  var size: String {
    if self > Self.GB {
      String(format: "%.2fG", self / Self.GB)
    } else if self > Self.MB {
      String(format: "%.2fM", self / Self.MB)
    } else {
      String(format: "%dK", Int(self / Self.KB))
    }
  }
}

enum WorkSettingsItem: String, CaseIterable {
  case Save, Fullscreen, Thumnail, Info, Draw;
    
  var enableString: String {
    switch self {
    case .Save:
      "save_image".resString
    case .Fullscreen:
      "exit_fullscreen".resString
    case .Thumnail:
      "隐藏缩略图".orCht("隱藏縮略圖")
    case .Info:
      "查看详情".orCht("查看詳情")
    case .Draw:
      "handwriting_off".localized
    }
  }
  
  var disableString: String {
    switch self {
    case .Save:
      "save_image".resString
    case .Fullscreen:
      "enter_fullscreen".resString
    case .Thumnail:
      "显示缩略图".orCht("顯示縮略圖")
    case .Info:
      "查看详情".orCht("查看詳情")
    case .Draw:
      "handwriting_on".localized
    }
  }
  
  var disableIcon: String {
    switch self {
    case .Save:
      "download"
    case .Fullscreen:
      "fullscreen"
    case .Thumnail:
      "show_thumb_bar"
    case .Info:
      "about"
    case .Draw:
      "handwriting"
    }
  }
  var enableIcon: String {
    switch self {
    case .Save:
      "download"
    case .Fullscreen:
      "exit_fullscreen"
    case .Thumnail:
      "hide_thumb_bar"
    case .Info:
      "about"
    case .Draw:
      "handwriting"
    }
  }
}

class WorkViewModel: AlertViewModel {
  let work: BeitieWork
  let images: [BeitieImage]
  @Published var showBars = false
  @Published var drawVM = DrawViewModel()
  @Published var showBottomBar = WorkViewModel.showThumbnailBar {
    didSet {
      WorkViewModel.showThumbnailBar = showBottomBar
      self.refreshMenu()
    }
  }
  @Published var enterFullscreen = false {
    didSet {
      if !enterFullscreen {
        showBars = false
      }
      self.refreshMenu()
    }
  }
  @Published var showDrawPanel = false {
    didSet {
      self.refreshMenu()
    }
  }
  @Published var pageIndex = 0
  
  @Published var showOverflowMenu = false
  @Published var dropdownParam: DropDownParam<WorkSettingsItem>!
  
  func toggleDrawPanel() {
    drawVM.onReset()
    showToast(showDrawPanel ? "handwriting_off".localized : "handwriting_on".localized)
    showDrawPanel.toggle()
  }
  
  private lazy var imageSaver = ImageSaver {
    self.showAlertDlg("图片已保存".orCht("圖片已保存"))
  }
  private let menuItems: [WorkSettingsItem]
  
  init(work: BeitieWork, pageIndex: Int = 0) {
    self.images = BeitieDbHelper.shared.getWorkImages(work.id)
    self.work = work
    self.pageIndex = pageIndex
    self.menuItems = images.size == 1 ? WorkSettingsItem.allCases.filter { $0 != .Thumnail } : WorkSettingsItem.allCases
    super.init()
    drawVM.onCloseDraw = { [weak self] in
      self?.toggleDrawPanel()
    }
    refreshMenu()
  }
  
  private func getItemEnabled(_ item: WorkSettingsItem) -> Bool {
    switch item {
    case .Save:
      true
    case .Fullscreen:
      self.enterFullscreen
    case .Thumnail:
      self.showBottomBar
    case .Info:
      true
    case .Draw:
      self.showDrawPanel
    }
  }
  
  func refreshMenu() {
    let texts = menuItems.map { item in
      getItemEnabled(item) ? item.enableString : item.disableString
    }
    let icons = menuItems.map {
      item in
      getItemEnabled(item) ? item.enableIcon : item.disableIcon
    }.map { DropDownIcon(name: $0, isSystem: false, size: 20, totalSize: 22) }
    
    dropdownParam = DropDownParam(items: menuItems, texts: texts, colors: Colors.ICON_COLORS, images: icons, padding: DropDownPadding(itemVertical: 12, extraTop: 2, extraBottom: 4), bgColor: .white)
  }
  
  private var uiImage: UIImageView? = nil
  
  func saveImage(image: BeitieImage) {
    let uiImage = UIImageView(frame: .zero)
    uiImage.sd_setImage(with: image.url(.JpgCompressed).url!) { image, error, t, _ in
      if let image {
        Task {
          let saveImage = if CurrentUser.isVip {
            image
          } else {
            image.addWaterMark("app_name".resString)
          }
          self.imageSaver.writeToPhotoAlbum(image: saveImage)
        }
      }
      self.uiImage = nil
    }
    self.uiImage = uiImage
  }
}

extension WorkViewModel {
  private static let KEY_SHOW_THUMBNAIL = "showThumbnailBar"
  
  static var showThumbnailBar: Bool {
    get {
      Settings.getBoolean(KEY_SHOW_THUMBNAIL, true)
    }
    set {
      Settings.putBoolean(KEY_SHOW_THUMBNAIL, newValue)
    }
  }
}

struct TappableSlider: View {
  var value: Binding<CGFloat>
  var range: ClosedRange<CGFloat>
  
  var body: some View {
    GeometryReader { geometry in
      Slider(value: self.value, in: self.range)
        .gesture(DragGesture(minimumDistance: 0).onEnded { value in
          let percent = min(max(0, Float(value.location.x / geometry.size.width * 1)), 1)
          let newValue = self.range.lowerBound + round(CGFloat(percent) * (self.range.upperBound - self.range.lowerBound))
          self.value.wrappedValue = newValue
        })
    }
  }
}

struct WorkView: View, SinglePreviewDelegate {
  func onImageTapped(_ item: Any?) {
    if viewModel.enterFullscreen {
      withAnimation(.linear(duration: 0.3)) {
        viewModel.showBars.toggle()
      }
    }
  }
  
  func onImageOutsideTapped() {
    if viewModel.enterFullscreen {
      withAnimation(.linear(duration: 0.3)) {
        viewModel.enterFullscreen = false
      }
    }
  }
  
  @StateObject var viewModel: WorkViewModel
  @StateObject var managerVM: ImageManager = ImageManager()
  @StateObject var naviVM = NavigationViewModel()
  @StateObject var collectVM = CollectionViewModel.shared
  @Environment(\.presentationMode) var presentationmode
  @State var showImageViewer: Bool = true
  
  @State var tabIndex = 0
  @State var sliderProgress: CGFloat = 0
  @State var galleryScroll = false
  @State var showImageText = false
  
  var work: BeitieWork {
    viewModel.work
  }
  
  var images: [BeitieImage] {
    viewModel.images
  }
  
  var currentImage: BeitieImage {
    images[viewModel.pageIndex]
  }
  
  var currentImageText: String {
    currentImage.chineseText()?.emptyNull ?? ""
  }
  
  var hasImageText: Bool {
    currentImageText.isNotEmpty()
  }
  
  @State private var scrollProxy: ScrollViewProxy? = nil
  @ScrollState private var previewScrollState
  
  var previewBottom: some View {
    ScrollView(.horizontal) {
      ScrollViewReader { proxy in
        LazyHStack(spacing: 6) {
          ForEach(0..<images.size, id: \.self) { i in
            let image = images[i]
            let selected = i == viewModel.pageIndex
            ZStack {
              Button {
                galleryScroll = false
                viewModel.pageIndex = i
              } label: {
                WebImage(url: image.url(.JpgCompressedThumbnail).url!) { img in
                  img.image?.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 80).clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(0.5)
                    .background {
                      RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .white, lineWidth: selected ? 4 : 1)
                    }
                }.onSuccess(perform: { _, _, _ in
                  if galleryScroll {
                    DispatchQueue.main.async {
                      syncScroll(tabIndex)
                    }
                  }
                }).onAppear {
                  if galleryScroll {
                    DispatchQueue.main.async {
                      syncScroll(tabIndex)
                    }
                  }
                }
              }
              if selected {
                Text((i+1).toString()).font(.footnote).bold().foregroundStyle(.white).padding(6).background(Circle().fill(.red))
              }
            }.id(i)
          }
        }.padding(.vertical, 10).padding(.horizontal, 15).frame(height: 80)
          .onAppear {
            scrollProxy = proxy
          }
      }
    }.environment(\.layoutDirection, .rightToLeft)
      .onChange(of: previewScrollState.isDragging) { newValue in
        if previewScrollState.isDragging {
          galleryScroll = false
        }
      }
  }
  
  private func syncScroll(_ index: Int) {
    let scrollIndex = min(index+1, images.size-1)
    debugPrint("syncScroll \(index)")
    scrollProxy?.scrollTo(scrollIndex, anchor: index == images.lastIndex ? .trailing : .leading)
  }
  
  @State private var imageSize: CGSize = .zero
  @State private var menuPosition: CGRect = .zero

  var naviBar: some View {
    NaviView {
      BackButtonView {
        presentationmode.wrappedValue.dismiss()
      }
      Spacer()
      Text(work.workNameAttrStr(.body, smallerFont: .footnote, curves: false))
        .foregroundStyle(work.btType.nameColor(baseColor: Color.colorPrimary))
      Spacer()
      if currentImage.singleCount > 0 {
        Button {
          if work.notMatchVip {
            viewModel.showConstraintVip(
              "当前操作不支持，请联系客服"
                .orCht("當前操作不支持，請聯繫客服"))
          } else {
            Task {
              let singles = BeitieDbHelper.shared.getSinglesByImageId(currentImage.id)
              DispatchQueue.main.async {
                self.naviVM.gotoSingles(singles: singles)
              }
            }
          }
        } label: {
          Image("singles").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE-1)
            .foregroundStyle(Color.colorPrimary)
        }
      }
      let collected = collectVM.itemCollected(currentImage)
      Button {
        let c = collected
        collectVM.toggleItem(currentImage)
        viewModel.showToast(c ? "已取消收藏" : "已加入收藏")
      }  label: {
        Image(collected ? "collect_fill" : "collect").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE+1)
          .foregroundStyle(Color.colorPrimary)
      }
      Button {
        viewModel.showOverflowMenu.toggle()
      } label: {
        Image(systemName: "ellipsis.circle").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE-2)
          .foregroundStyle(Color.colorPrimary)
      }.background(PositionReaderView(binding: $menuPosition))
    }
  }
  var imageGallery: some View {
    ZStack(alignment: .bottom) {
      Color.black
      if imageSize.width > 0 {
        BeitieGallerView(images: images, parentSize: imageSize, pageIndex: $tabIndex, galleryScroll: $galleryScroll, tapDelegate: self)
          .environment(\.layoutDirection, .rightToLeft)
      }
      if showImageText && currentImageText.isNotEmpty() {
        ZStack {
          TextField("", text: .constant(currentImageText), axis: .vertical)
            .multilineTextAlignment(.leading)
            .font(.callout)
            .padding(10)
            .foregroundStyle(.white)
        }.background(.black.opacity(0.55))
      }
      if viewModel.showToast {
        ZStack {
          VStack {
            Spacer()
            ToastView(title: viewModel.toastTitle)
            Spacer()
          }
        }
      }
      if viewModel.showDrawPanel {
        DrawPanel().environmentObject(viewModel.drawVM)
      }
    }.background(.black)
      .background(SizeReaderView(binding: $imageSize))
  }
  
  var scrollBar: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .center) {
        HStack(spacing: 12) {
          Button {
            showImageText.toggle()
          } label: {
            HStack(spacing: 5) {
              Text("image_text".localized).font(.callout)
              Image(systemName: "triangle.fill").square(size: 7)
                .rotationEffect(.degrees(showImageText ? 0 : 180))
            }.foregroundStyle(hasImageText ? Color.colorPrimary : .gray)
          }.disabled(!hasImageText)
          ZStack {
            Slider(value: $sliderProgress, in: 1...(CGFloat(viewModel.images.size))) .rotationEffect(.degrees(180))
          }
          Text("\(viewModel.pageIndex+1)/\(viewModel.images.size)\("页".orCht("頁"))")
            .foregroundStyle(Color.colorPrimary)
        }
      }.frame(height: scrollBarHeight)
    }.padding(.horizontal, 10).frame(height: scrollBarHeight)
  }
  
  var showBars: Bool {
    !viewModel.enterFullscreen || viewModel.showBars
  }
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(spacing: 0) {
        if showBars {
          naviBar
          Divider()
        }
        imageGallery
        if showBars {
          Divider()
          scrollBar
          if images.size > 1 && viewModel.showBottomBar {
            Divider()
            previewBottom
          }
        }
      }.modifier(DragDismissModifier(show: $viewModel.showOverflowMenu))
        .modifier(TapDismissModifier(show: $viewModel.showOverflowMenu))
      if viewModel.showOverflowMenu {
        DropDownOptionsView(param: viewModel.dropdownParam!) { item in
          switch item {
          case .Save:
            if work.notMatchVip {
              viewModel.showConstraintVip(
                "当前碑帖不支持下载，请联系客服"
                  .orCht("當前碑帖不支持下載，請聯繫客服"))
            } else {
              viewModel.saveImage(image: currentImage)
            }
          case .Fullscreen:
            withAnimation(.linear(duration: 0.3)) {
              viewModel.enterFullscreen.toggle()
            }
          case .Thumnail:
            viewModel.showBottomBar.toggle()
          case .Info:
            naviVM.gotoWorkIntro(work: work)
          case .Draw:
            viewModel.toggleDrawPanel()
          }
          viewModel.showOverflowMenu = false
        }.offset(x: -5, y: (CUSTOM_NAVIGATION_HEIGHT - menuPosition.height) / 2  + menuPosition.height + 5)
      }
    }.navigationBarHidden(true)
      .modifier(AlertViewModifier(viewModel: viewModel))
      .onChange(of: tabIndex) { newValue in
        if viewModel.pageIndex != newValue {
          viewModel.pageIndex = newValue
          if galleryScroll {
            syncScroll(newValue)
          }
        }
      }
      .onChange(of: viewModel.pageIndex) { newValue in
        if tabIndex != viewModel.pageIndex {
          tabIndex = viewModel.pageIndex
        }
        sliderProgress = (newValue + 1).toCGFloat()
      }
      .onChange(of: sliderProgress) { newValue in
        let newIndex = Int(newValue) - 1
        if (newIndex != tabIndex) {
          tabIndex = newIndex
          galleryScroll = true
          syncScroll(newIndex)
        }
      }.modifier(SingleDestinationModifier(naviVM: naviVM))
      .modifier(WorkIntroDestinationModifier(naviVM: naviVM))
        .ignoresSafeArea(edges: showBars ? [] : [.top, .bottom])
  }
  
  private let scrollBarHeight: CGFloat = 44
}

#Preview {
  WorkView(viewModel: WorkViewModel(work: BeitieDbHelper.shared.works[97], pageIndex: 0))
}
