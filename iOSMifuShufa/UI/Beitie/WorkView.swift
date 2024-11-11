//
//  Untitled.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//

import SwiftUI
import SDWebImageSwiftUI
//import Agrume

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

struct WorkView: View {
  @StateObject var viewModel: WorkViewModel
  @StateObject var managerVM: ImageManager = ImageManager()
  @Environment(\.presentationMode) var presentationmode
  @State var showImageViewer: Bool = true
  
  @State var tabIndex = 0
  @State var sliderProgress: CGFloat = 0.0
   
  
  var work: BeitieWork {
    viewModel.work
  }
  
  var images: [BeitieImage] {
    viewModel.images
  }
  
  @State private var scrollProxy: ScrollViewProxy? = nil
  
  var previewBottom: some View {
    ScrollView(.horizontal) {
      ScrollViewReader { proxy in
        LazyHStack(spacing: 6) {
          ForEach(0..<images.size, id: \.self) { i in
            let image = images[i]
            let selected = i == viewModel.pageIndex
            ZStack {
              Button {
                viewModel.pageIndex = i
              } label: {
                WebImage(url: image.url(.JpgCompressedThumbnail).url!) { img in
                  img.image?.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 80)
                }.onSuccess(perform: { _, _, _ in
                  
                }).clipShape(RoundedRectangle(cornerRadius: 2))
                  .padding(0.5)
                  .background {
                    RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .white, lineWidth: selected ? 4 : 1)
                  }.padding(.horizontal, selected ? 0 : 0.5)
              }
              if selected {
                Text((i+1).toString()).font(.footnote).bold().foregroundStyle(.white).padding(6).background(Circle().fill(.red))
              }
            }.id(i)
          }
        }.padding(.vertical, 10).padding(.horizontal, 15).frame(height: 80)
          .onAppear {
            scrollProxy = proxy
              //              if viewModel.pageIndex > 0 {
              //                Task {
              //                  sleep(1)
              //                  DispatchQueue.main.async {
              //                    proxy.scrollTo(max(self.viewModel.pageIndex-1, 0), anchor: .leading)
              //                  }
              //                }
              //              }
          }.onChange(of: viewModel.pageIndex) { newValue in
            tabIndex = newValue
          }
      }
    }.frame(height: 80)
      .environment(\.layoutDirection, .rightToLeft)
  }
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
        Button {
          
        } label: {
          Image("images").square(size: CUSTOM_NAVI_ICON_SIZE)
            .foregroundStyle(Color.colorPrimary)
        }
        Button {
          
        } label: {
          Image("collect").square(size: CUSTOM_NAVI_ICON_SIZE+1)
            .foregroundStyle(Color.colorPrimary)
        }
      }
      Divider()
      ZStack(alignment: .topTrailing) {
        TabView(selection: $tabIndex) {
          ForEach(0..<images.size, id: \.self) { i in
            let image = images[i]
            let status = managerVM.getImageStatus(image)
            ZStack {
              switch status {
              case .Loading:
                VStack {
                  ProgressView().progressViewStyle(.circular).tint(.white)
                    .scaleEffect(1.5)
                }
              case .Downloaded:
                Text("下载完成，正在加载图片...".orCht("下載完成，正在加載圖片...")).foregroundStyle(Color.souyun)
              case .Loaded:
                if let path = managerVM.imagePath[image] {
                  BeitieImageView(path: path, isPresenting: .constant(true))
                }
              case .Failed:
                Button {
                  managerVM.loadBeitieImage(image)
                } label: {
                  Text("download_error_click_retry".localized).font(.title3).foregroundStyle(.red)
                }
              }
            }.tag(i).id(i.toString() + status.rawValue)
          }
        }.tabViewStyle(.page(indexDisplayMode: .never))
          .environment(\.layoutDirection, .rightToLeft)
      }.background(.black)
      Divider()
      HStack(spacing: 12) {
        Button {
          
        } label: {
          HStack(spacing: 5) {
            Text("image_text".localized).font(.callout)
            Image(systemName: "triangle.fill").square(size: 7)
              .rotationEffect(.degrees(180))
          }.foregroundStyle(Color.colorPrimary)
        }
        Slider(value: $sliderProgress, in: CGFloat(1)...CGFloat(viewModel.images.size)) {
          
        }.rotationEffect(.degrees(180))
        Text("\(viewModel.pageIndex+1)/\(viewModel.images.size)\("页".orCht("頁"))")
          .foregroundStyle(Color.colorPrimary)
      }.padding(.horizontal, 10).frame(height: 40)
      if images.size > 1 && viewModel.showBottomBar {
        Divider()
        previewBottom
      }
    }.navigationBarHidden(true)
      .onChange(of: tabIndex) { newValue in
        viewModel.pageIndex = newValue
        scrollProxy?.scrollTo(max(newValue-1, 0), anchor: .leading)
      }
  }
}

#Preview {
  WorkView(viewModel: WorkViewModel(work: BeitieDbHelper.shared.works[97], pageIndex: 0))
}
