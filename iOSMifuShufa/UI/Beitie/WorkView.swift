//
//  Untitled.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//

import SwiftUI
import SDWebImageSwiftUI

import MijickPopupView
 
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
  case Save, Fullscreen, Thumnail, Info, Draw, Report;
  
  static var REPORT_ERROR: String {
    "错误上报".orCht("錯誤上報")
  }
  
  var padding: CGFloat {
    switch self {
    case .Draw:
      1
    case .Report:
      1
    default:
      0
    }
  }
  
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
    case .Report:
      Self.REPORT_ERROR
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
    case .Report:
      Self.REPORT_ERROR
    }
  }
  
  var disableIcon: String {
    switch self {
    case .Report:
      "questionmark.circle"
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
  
  var systemIcon: Bool {
    switch self {
    case .Report:
      true
    default:
      false
    }
  }
  
  var enableIcon: String {
    switch self {
    case .Report:
      "questionmark.circle"
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
  @Published var thumbnailImages = [BeitieImage: UIImage]()
  @Published var thumbnailImageViews = [BeitieImage: UIImageView]()
  
  func toggleDrawPanel() {
    drawVM.onReset()
    showToast(showDrawPanel ? "handwriting_off".localized : "handwriting_on".localized)
    showDrawPanel.toggle()
  }
  
  
  func loadThumbnailImage(image: BeitieImage) {
    if thumbnailImageViews[image] != nil {
      return
    }
    let imgView = UIImageView(frame: .zero)
    thumbnailImageViews[image] = imgView
    debugPrint("download thumbnail \(image.fileName)")
    Task {
      await imgView.sd_setImage(with: image.url(.JpgCompressedThumbnail).url!) { img, _, _, _ in
        if let img {
          DispatchQueue.main.async {
            self.thumbnailImages[image] = img
          }
        }
      }
    }
  }
  
  private let menuItems: [WorkSettingsItem]
  
  init(work: BeitieWork, pageIndex: Int = 0) {
    self.images = BeitieDbHelper.shared.getWorkImages(work.id)
    self.work = work
    self.pageIndex = pageIndex != 0 ? pageIndex : work.lastIndex.coerced(0, images.size-1)
    self.menuItems = images.size == 1 ? WorkSettingsItem.allCases.filter { $0 != .Thumnail } : WorkSettingsItem.allCases
    super.init()
    drawVM.onCloseDraw = { [weak self] in
      self?.toggleDrawPanel()
    }
    refreshMenu()
  }
  
  private func getItemEnabled(_ item: WorkSettingsItem) -> Bool {
    switch item {
    case .Save, .Report:
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
      let icon = getItemEnabled(item) ? item.enableIcon : item.disableIcon
      return DropDownIcon(name: icon, isSystem: item.systemIcon, size: 20-item.padding, totalSize: 22)
    }
    
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

extension BeitieWork {
  
  var lastIndexKey: String {
    "\(id)LastIndex"
  }
  
  var lastIndex: Int {
    get {
      Settings.getInt(lastIndexKey, 0)
    }
    set {
      Settings.putInt(lastIndexKey, newValue)
    }
  }

}

extension Int {
  func coerced(_ min: Int, _ max: Int) -> Int {
    return Swift.min(Swift.max(min, self), max)
  }
}


struct ToastView: View {
  let title: String
  var body: some View {
    HStack {
      Text(title)
        .foregroundStyle(.white)
        .padding(.horizontal, 25)
        .padding(.vertical, 16)
    }.background(Color.darkSlateGray)
      .clipShape(RoundedRectangle(cornerRadius: 25))
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
                if let image = viewModel.thumbnailImages[image] {
                  Image(uiImage: image).resizable()
                    .scaledToFill()
                    .frame(maxWidth: 40)
                    .frame(height: 59)
                    .contentShape(RoundedRectangle(cornerRadius: 2))
                    .clipped()
                    .padding(0.5)
                    .background {
                      RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .gray, lineWidth: selected ? 4 : 0.5)
                    }.onAppear {
                      if galleryScroll {
                        DispatchQueue.main.async {
                          syncScroll(tabIndex)
                        }
                      }
                    }
                } else {
                    HStack {
                      Color.darkSlateGray
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5)).padding(0.5).background{
                      RoundedRectangle(cornerRadius: 5).stroke(.white, lineWidth: 0.5)
                    }.frame(width: 25, height: 60)
                      .onAppear {
                        viewModel.loadThumbnailImage(image: image)
                      }
                }
              }.buttonStyle(.plain)
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
      HStack(spacing: 5) {
        let color = work.btType.nameColor(baseColor: Color.colorPrimary)
        if work.vip {
          Image("vip_border")
            .renderingMode(.template)
            .square(size: 16)
            .foregroundStyle(color)
        }
        Text(work.workNameAttrStr(.title3, smallerFont: .footnote, curves: false))
          .foregroundStyle(color)
      }
      Spacer()
      if currentImage.singleCount > 0 {
        Button {
          if work.notMatchVip {
            viewModel.showConstraintVip(
              "当前操作不支持，是否开通VIP继续？"
                .orCht("當前操作不支持，是否開通VIP繼續？"))
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
        }.buttonStyle(.plain)
      }
      let collected = collectVM.itemCollected(currentImage)
      Button {
        let c = collected
        collectVM.toggleItem(currentImage)
        viewModel.showToast(c ? "已取消收藏" : "已加入收藏")
      }  label: {
        Image(collected ? "collect_fill" : "collect").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE+1)
          .foregroundStyle(Color.colorPrimary)
      }.buttonStyle(.plain)
      Button {
        viewModel.showOverflowMenu.toggle()
      } label: {
        Image(systemName: "ellipsis.circle").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE-2)
          .foregroundStyle(Color.colorPrimary)
      }.buttonStyle(.plain).background(PositionReaderView(binding: $menuPosition))
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
      if viewModel.showDrawPanel {
        DrawPanel().environmentObject(viewModel.drawVM)
      }
    }.background(.black)
      .background(SizeReaderView(binding: $imageSize))
  }
  
  var scrollBar: some View {
    HStack {
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
          }.disabled(!hasImageText).buttonStyle(.plain)
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
    NavigationStack {
      content
        .implementPopupView()
        .onChange(of: viewModel.showFeedback) { newValue in
          FeedbackPopup(initText: "\(viewModel.work.chineseFolder())-\(viewModel.pageIndex+1)\("页".orCht("頁"))\n").showAndStack()
        }
    }.modifier(VipViewModifier(viewModel: viewModel))
      .modifier(SingleDestinationModifier(naviVM: naviVM))
      .modifier(WorkIntroDestinationModifier(naviVM: naviVM))
  }
  var content: some View {
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
      
      if viewModel.showToast {
        ZStack {
          Color.clear
          ToastView(title: viewModel.toastTitle)
        }
      }
      if viewModel.showOverflowMenu {
        DropDownOptionsView(param: viewModel.dropdownParam!) { item in
          switch item {
          case .Report:
            viewModel.showFeedback = true
          case .Save:
            if work.notMatchVip {
              viewModel.showConstraintVip(
                "当前碑帖不支持下载，是否开通VIP继续？"
                  .orCht("當前碑帖不支持下載，是否開通VIP繼續？"))
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
      }
        .ignoresSafeArea(edges: showBars ? [] : [.top, .bottom])
        .onDisappear {
          work.lastIndex = tabIndex
        }
        .onAppear {
          if tabIndex != viewModel.pageIndex {
            tabIndex = viewModel.pageIndex
            sliderProgress = (tabIndex + 1).toCGFloat()
          }
        }
  }
  
  private let scrollBarHeight: CGFloat = 44
}

#Preview {
  WorkView(viewModel: WorkViewModel(work: BeitieDbHelper.shared.works[0], pageIndex: 0))
}


struct FeedbackPopup: BottomPopup {
  let initText: String
  let bottomHeight: CGFloat
  init(initText: String, bottomHeight: CGFloat = 0) {
    self.initText = "[\("勘误".orCht("勘誤"))]" + initText
    self.bottomHeight = bottomHeight
  }
  func createContent() -> some View {
    feedbackView
      .padding(.bottom, bottomHeight)
  }
  func configurePopup(popup: BottomPopupConfig) -> BottomPopupConfig {
    popup
      .cornerRadius(0)
      .contentIgnoresSafeArea(true)
  }
  enum FocusField {
    case text, contact
  }
  
  private let height = UIHelper.screenHeight * 0.4
  @State var text: String = ""
  @State var contact: String = ""
  @State var showAlert: Bool = false
  @State var alertMessage: String = ""
  @FocusState var textFocused: FocusField?
  var feedbackView: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark").resizable().scaledToFit()
            .foregroundColor(Colors.colorPrimary.swiftColor)
            .frame(width: 13, height: 13)
        }.buttonStyle(.plain)
        Text(WorkSettingsItem.REPORT_ERROR).font(.title3)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
        
        Button {
          if initText.trim() == text.trim() {
            let noKanwu = "检测到具体错误未填写，请填写后再提交！".orCht("檢測到具體錯誤未填寫，請填寫後再提交！")
            self.alertMessage = noKanwu
            self.showAlert = true
            return
          }
          NetworkHelper.submitFeedback(feedback: text, contact: contact) { error in
            if error == nil {
              self.alertMessage = "反馈已经收到，感谢你的反馈!".orCht("反饋已經收到，感謝你的反饋!")
            } else {
              self.alertMessage = "发送反馈失败，请稍后重试!".orCht("發送反饋失敗，請稍後重試!")
            }
            self.showAlert = true
          }
        } label : {
          Text("提交").font(.body).foregroundColor(.blue)
        }.buttonStyle(.plain)
      }.padding(.horizontal, 15)
        .padding(.vertical, 5)
      Divider()
      VStack {
        TextEditor(text: $text)
          .padding(.all, 5)
          .focused($textFocused, equals: .text)
          .background(Color.white)
          .colorMultiply(Colors.background.swiftColor)
          .shadow(radius: 0)
      }
      .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
        .stroke(Color.gray, lineWidth: 0.5))
      .cornerRadius(5)
      .shadow(radius: textFocused == .text ? 5 : 0)
      .padding(.horizontal, 15)
      .padding(.top, 15)
      .padding(.bottom, 15)
      Spacer.height(25)
    }
    .alert(isPresented: $showAlert, content: {
      Alert(title: Text(WorkSettingsItem.REPORT_ERROR), message: Text(alertMessage), dismissButton:
          .default(Text("好"), action: {
            self.dismiss()
          }))
    })
    .frame(minHeight: height, maxHeight: height)
    .task {
      text = initText
    }
    .onDisappear {
      dismissAll()
    }
  }
}
