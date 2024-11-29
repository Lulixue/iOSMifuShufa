//
//  SinglePreviewItem.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/7.
//
import SwiftUI
import SDWebImageSwiftUI
import DeviceKit

class MiGridZoomableViewModel: BaseObservableObject {
  let single: BeitieSingle
  let grid: SingleAnalyzeType
  let centroid: Bool
  @Published var image: UIImage? = nil
  private var imageView: UIImageView? = nil
  
  init(single: BeitieSingle, grid: SingleAnalyzeType, centroid: Bool) {
    self.single = single
    self.grid = grid
    self.centroid = centroid
    super.init()
  }
  
  func loadImage() {
    if self.imageView != nil {
      return
    }
    let imgView = UIImageView(frame: .zero)
    self.imageView = imgView
    debugPrint("download single \(single.fileName)")
    Task {
      await imgView.sd_setImage(with: single.url.url!) { img, _, _, _ in
        if let img {
          DispatchQueue.main.async {
            let result = self.grid.applyAnalyze(img, self.single)
            self.image = result
          }
        }
      }
    }
  }
}

struct MiGridZoomableImageView: View {
   
  @ObservedObject var viewModel: MiGridZoomableViewModel
  var onTouchOutside: () -> Void = {}
  var onClick: () -> Void = {}

  @State private var currentZoom = 0.0
  @State private var totalZoom = Device.current.isPad ? 0.5 : 0.95
  private let maxZoom = 5.0
  private let minZoom = 0.3
  
  var body: some View {
      ZStack {
        ScrollView {
          
        }.onTapGesture {
          onTouchOutside()
        }
        if let image = viewModel.image {
          Image(uiImage: image).renderingMode(.original).resizable()
            .scaledToFit()
            .frame(minHeight: 20)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .scaleEffect(currentZoom + totalZoom)
            .gesture(MagnificationGesture().onChanged({ offset in
              debugPrint("offset \(offset)")
              currentZoom = offset - 1
            }).onEnded({ offset in
              totalZoom = max(min(totalZoom + currentZoom, maxZoom), minZoom)
              currentZoom = 0
            })).onTapGesture {
              onClick()
            }.padding(10)
          
        } else {
          ProgressView().progressViewStyle(.circular)
            .squareFrame(40).tint(.white)
            .onAppear {
              viewModel.loadImage()
            }
        }
      }
  }

}

struct ImageZoomableView: View {
  let image: UIImage
  @State private var currentZoom = 0.0
  @State private var totalZoom = Device.current.isPad ? 0.5 : 0.95
  private let maxZoom = 5.0
  private let minZoom = 0.3
  
  var body: some View {
      ZStack {
        ScrollView {
          
        }
        Image(uiImage: image).resizable()
        .scaledToFit()
        .frame(minHeight: 20)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .scaleEffect(currentZoom + totalZoom)
        .gesture(MagnificationGesture().onChanged({ offset in
          debugPrint("offset \(offset)")
          currentZoom = offset - 1
        }).onEnded({ offset in
          totalZoom = max(min(totalZoom + currentZoom, maxZoom), minZoom)
          currentZoom = 0
        })).padding(10)
      }
  }
}

struct SinglePreviewItem: View {
  let url: String
  var onTouchOutside: () -> Void = {}
  var onClick: () -> Void = {}
  @State private var loading = false
  @State private var currentZoom = 0.0
  @State private var totalZoom = Device.current.isPad ? 0.5 : 0.95
  private let maxZoom = 5.0
  private let minZoom = 0.3
  
  var body: some View {
    ZStack {
      ScrollView {
        
      }.onTapGesture {
        onTouchOutside()
      }
      WebImage(url: url.url!) { img in
        img.image?.resizable()
          .scaledToFit()
          .frame(minHeight: 20)
          .onTapGesture {
            onClick()
          }
      }
      .onSuccess(perform: { image, data, cacheType in
        DispatchQueue.main.async {
          self.loading = false
        }
      })
      .indicator(.activity).tint(.white).frame(alignment: loading ? .center : .topTrailing)
      .clipShape(RoundedRectangle(cornerRadius: 2))
      .scaleEffect(currentZoom + totalZoom)
      .gesture(MagnificationGesture().onChanged({ offset in
        debugPrint("offset \(offset)")
        currentZoom = offset - 1
      }).onEnded({ offset in
        totalZoom = max(min(totalZoom + currentZoom, maxZoom), minZoom)
        currentZoom = 0
      })).padding(10)
    }
  }
}


#Preview {
  MiGridZoomableImageView(viewModel: MiGridZoomableViewModel(single: BeitieDbHelper.shared.getSingles("人").first(), grid: .Original, centroid: false))
}

#Preview {
  SinglePreviewItem(url: BeitieDbHelper.shared.getSingles("人").first().url)
}

#Preview {
  ImageZoomableView(image: UIImage(named: "sample")!)
}
