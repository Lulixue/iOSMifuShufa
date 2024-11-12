//
//  Untitled.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/5.
//

import SwiftUI
import SDWebImageSwiftUI
//import Agrume
 
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
    HStack {
      Spacer()
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
            }
        }
      }.frame(height: 80)
        .environment(\.layoutDirection, .rightToLeft)
      Spacer()
    }
  }
  
  @State var imageSize: CGSize = .zero
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
      ZStack(alignment: .bottom) {
        Color.black
        if imageSize.width > 0 {
          BeitieGallerView(images: images, parentSize: imageSize, pageIndex: $tabIndex)
            .environment(\.layoutDirection, .rightToLeft)
        }
      }.background(.black)
        .background(SizeReaderView(binding: $imageSize))
      Divider()
      ScrollView {
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
        }.frame(height: 40)
      }.padding(.horizontal, 10).frame(height: 40)
      if images.size > 1 && viewModel.showBottomBar {
        Divider()
        previewBottom
      }
    }.navigationBarHidden(true)
      .onChange(of: tabIndex) { newValue in
        if viewModel.pageIndex != newValue {
          viewModel.pageIndex = newValue
          scrollProxy?.scrollTo(newValue, anchor: .leading)
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
        }
      }
  }
}

#Preview {
  WorkView(viewModel: WorkViewModel(work: BeitieDbHelper.shared.works[97], pageIndex: 0))
}
