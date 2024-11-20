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

class WorkViewModel: AlertViewModel {
  let work: BeitieWork
  let images: [BeitieImage]
  @Published var showBottomBar = WorkViewModel.showThumbnailBar {
    didSet {
      WorkViewModel.showThumbnailBar = showBottomBar
    }
  }
  @Published var pageIndex = 0
  
  init(work: BeitieWork, pageIndex: Int = 0) {
    self.images = BeitieDbHelper.shared.getWorkImages(work.id)
    self.work = work
    self.pageIndex = pageIndex
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

struct WorkView: View {
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
                })
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
    printlnDbg("syncScroll \(index)")
    scrollProxy?.scrollTo(scrollIndex, anchor: index == images.lastIndex ? .trailing : .leading)
  }
  
  @State private var imageSize: CGSize = .zero

  var body: some View {
    VStack(spacing: 0) {
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
            Task {
              let singles = BeitieDbHelper.shared.getSinglesByImageId(currentImage.id)
              DispatchQueue.main.async {
                self.naviVM.gotoSingles(singles: singles)
              }
            }
          } label: {
            Image("singles").square(size: CUSTOM_NAVI_ICON_SIZE-1)
              .foregroundStyle(Color.colorPrimary)
          }
        }
        let collected = collectVM.itemCollected(currentImage)
        Button {
          let c = collected
          collectVM.toggleItem(currentImage)
          viewModel.showToast(c ? "已取消收藏" : "已加入收藏")
          Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            DispatchQueue.main.async {
              viewModel.showToast = false
            }
          }
        }  label: {
          Image(collected ? "collect_fill" : "collect").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE+1)
            .foregroundStyle(Color.colorPrimary)
        }
      }
      Divider()
      ZStack(alignment: .bottom) {
        Color.black
        if imageSize.width > 0 {
          BeitieGallerView(images: images, parentSize: imageSize, pageIndex: $tabIndex, galleryScroll: $galleryScroll)
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
      }.background(.black)
        .background(SizeReaderView(binding: $imageSize))
      Divider()
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
      if images.size > 1 && viewModel.showBottomBar {
        Divider()
        previewBottom
      }
    }.navigationBarHidden(true)
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
      }.navigationDestination(isPresented: $naviVM.gotoSingleView) {
        SinglesView(viewModel: naviVM.singleViewModel!)
      }
  }
  
  private let scrollBarHeight: CGFloat = 44
}

#Preview {
  WorkView(viewModel: WorkViewModel(work: BeitieDbHelper.shared.works[97], pageIndex: 0))
}
