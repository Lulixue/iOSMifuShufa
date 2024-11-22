  // ZoomImageView.swift
  //
  // Copyright (c) 2016 muukii
  //
  // Permission is hereby granted, free of charge, to any person obtaining a copy
  // of this software and associated documentation files (the "Software"), to deal
  // in the Software without restriction, including without limitation the rights
  // to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  // copies of the Software, and to permit persons to whom the Software is
  // furnished to do so, subject to the following conditions:
  //
  // The above copyright notice and this permission notice shall be included in
  // all copies or substantial portions of the Software.
  //
  // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  // IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  // FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  // AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  // LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  // OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  // THE SOFTWARE.

import UIKit
import SDWebImage

public enum SingleMiGrid {
  case noGrid
  case miGrid
  case miGridCircle
  
  func toNext() -> SingleMiGrid {
    switch (self) {
    case .noGrid: return SingleMiGrid.miGrid
    case .miGrid: return SingleMiGrid.noGrid
    case .miGridCircle: return SingleMiGrid.noGrid
    }
  }
}

protocol SinglePreviewDelegate {
  func onImageTapped(_ item: Any?)
  func onImageOutsideTapped()
}


protocol SDImageDelegate {
  func downloadComplete()
  func downloadProgress(_ downloaded: Int, _ total: Int)
}

open class ZoomImageView : UIScrollView, UIScrollViewDelegate {
  
  public enum ZoomMode {
    case fit
    case fill
    
  }
  public enum ImageType {
    case single
    case image
    case puzzle
  }
  enum ZoomScale {
    case auto
    case min
    case medium
    case max
    
    func toNext() -> ZoomScale {
      switch (self) {
      case .min: return .auto
      case .auto: return .medium
      case .medium: return .max
      case .max: return .min
      }
    }
  }
  var parentSize: CGSize!
  
  class ImageScale {
    private static let ALBUM_MIN_SIZE_PERCENT: CGFloat = 0.5
    private static let ALBUM_MAX_SIZE_PERCENT: CGFloat = 5
    private static let ALBUM_AUTO_SIZE_PERCENT: CGFloat = 0.90
    private static let ALBUM_MEDIUM_SIZE_SCALE: CGFloat = 1
    static let MIN_SIZE_PERCENT: CGFloat = 0.3
    static let MAX_SIZE_PERCENT: CGFloat = 1.5
    static let AUTO_SIZE_PERCENT: CGFloat = 0.8
    static let MEDIUM_SIZE_SCALE: CGFloat = 1
    
    static let PUZZLE_MIN_SIZE_PERCENT: CGFloat = 0.8
    static let PUZZLE_MAX_SIZE_PERCENT: CGFloat = 2.0
    static let PUZZLE_AUTO_SIZE_PERCENT: CGFloat = 0.95
    static let PUZZLE_MEDIUM_SIZE_SCALE: CGFloat = 1
    
    var auto: CGFloat = 1.8
    var min: CGFloat = 0.5
    var medium: CGFloat = 1.75
    var max: CGFloat = 3.0
    
    func getScale(_ scale: ZoomScale) -> CGFloat {
      switch scale {
      case .auto:
        auto
      case .min:
        min
      case .medium:
        medium
      case .max:
        max
      }
    }
    
    func calculateAutoScale(ImageSize imgSize: CGSize, ParentViewSize parSize: CGSize, _ type: ImageType = .single) {
      let dHeight = imgSize.height
      let dWidth = imgSize.width
      let pWidth = parSize.width
      let pHeight = parSize.height - 6
      
      var min = ImageScale.MIN_SIZE_PERCENT
      var max = ImageScale.MAX_SIZE_PERCENT
      var auto = ImageScale.AUTO_SIZE_PERCENT
      var medium = ImageScale.MEDIUM_SIZE_SCALE
      if type == .image {
        min = ImageScale.ALBUM_MIN_SIZE_PERCENT
        max = ImageScale.ALBUM_MAX_SIZE_PERCENT
        auto = ImageScale.ALBUM_AUTO_SIZE_PERCENT
        medium = ImageScale.ALBUM_MEDIUM_SIZE_SCALE
      } else if type == .puzzle {
        
        min = ImageScale.PUZZLE_MIN_SIZE_PERCENT
        max = ImageScale.PUZZLE_MAX_SIZE_PERCENT
        auto = ImageScale.PUZZLE_AUTO_SIZE_PERCENT
        medium = ImageScale.PUZZLE_MEDIUM_SIZE_SCALE
      }
      
      
      let minScaleW = (pWidth * min) / dWidth
      let minScaleH = (pHeight * min) / dHeight
      
      let maxScaleW = (dWidth * max) / pWidth
      let maxScaleH = (dHeight * max) / pHeight
      var maxScale = Utils.getMore(maxScaleH, maxScaleW)
      var minScale = Utils.getLess(minScaleH, minScaleW)
      
      if type == .single || type == .puzzle {
        minScale = Utils.getLess(minScale, Utils.PHOTOVIEW_SCALE_MIN-0.05)
        maxScale = Utils.getLess(maxScale, Utils.PHOTOVIEW_SCALE_MAX)
      }
      
      let destScaleW = (pWidth * auto) / dWidth
      let destScaleH = (pHeight * auto) / dHeight
      var destScale = Utils.getLess(destScaleH, destScaleW)
      
      destScale = Utils.getMore(destScale, minScale)
      
      if type == .puzzle {
        destScale = Utils.getLess(destScale, medium)
      }
      
      self.auto = destScale
      self.min = minScale // Swift.max(minScale, Self.ALBUM_MIN_SIZE_PERCENT)
      self.max = maxScale // Swift.min(maxScale, Self.ALBUM_MAX_SIZE_PERCENT)
      self.medium = medium
      
      debugPrint("image Size: \(imgSize), parent Size: \(parSize)")
      debugPrint("min: \(self.min), max: \(self.max), medium: \(self.medium), auto: \(self.auto)")
    }
  }
  var imageDefaultScale = ImageScale()
    // MARK: - Properties
  
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.allowsEdgeAntialiasing = true
    return imageView
  }()
  
  public var zoomMode: ZoomMode = .fit {
    didSet {
      updateImageView()
      scrollToCenter()
    }
  }
  var imageType: ImageType = .image
  var imageScale: CGFloat = 1.0 {
    didSet {
      updateImageView()
      scrollToCenter()
    }
  }
  
  var zoomScaleEnum: ZoomScale = .auto {
    didSet {
      switch(zoomScaleEnum) {
      case .auto: imageScale = imageDefaultScale.auto
      case .min: imageScale = imageDefaultScale.min
      case .medium: imageScale = imageDefaultScale.medium
      case .max: imageScale = imageDefaultScale.max
      }
    }
  }
  open var image: UIImage? {
    get {
      return imageView.image
    }
    set {
      let oldImage = imageView.image
      imageView.image = newValue
      
      if oldImage?.size != newValue?.size {
        oldSize = nil
        updateImageView()
      }
      scrollToCenter()
    }
  }
  
  func setupImage(_ image: UIImage) {
    self.image = image
    setup()
  }
  
  open override var intrinsicContentSize: CGSize {
    return imageView.intrinsicContentSize
  }
  
  private var oldSize: CGSize?
  public var drawBlackBorder: Bool = false
  
    // MARK: - Initializers
  
  
  public init(image: UIImage, parentSize: CGSize) {
    super.init(frame: CGRect(x: 0, y: 0, width: parentSize.width, height: parentSize.height))
    self.parentSize = parentSize
    self.image = image
    setup()
  }
  
  var sdDelegate: SDImageDelegate?
  var tapDelegate: SinglePreviewDelegate!
  var tapObj: Any?
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  func setShowedImageUrl(_ url: String) {
    let singleImage = UIImageView()
    let url = url.url!
    
    
    singleImage.sd_setImage(with: url, placeholderImage: nil, options: [.highPriority],
                            progress: { (downloaded, total, url) in
      if downloaded > 0 {
        if (downloaded != total) {
          self.sdDelegate?.downloadProgress(downloaded, total)
        }
      }
    }, completed:  { (image, error, cacheType, url) in
      if let image = singleImage.image {
        self.image = image
        self.setup()
        self.sdDelegate?.downloadComplete()
      }
    })
    
  }
  
  func setImageUrl(_ url: String) {
    setShowedImageUrl(url)
  }
    // MARK: - Functions
  
  open func scrollToCenter() {
    
    let centerOffset = CGPoint(
      x: contentSize.width > bounds.width ? (contentSize.width / 2) - (bounds.width / 2) : 0,
      y: contentSize.height > bounds.height ? (contentSize.height / 2) - (bounds.height / 2) : 0
    )
    contentOffset = centerOffset
  }
  
  open func setup() {
    
#if swift(>=3.2)
    if #available(iOS 11, *) {
      contentInsetAdjustmentBehavior = .never
    }
#endif
     
    backgroundColor = UIColor.clear
    delegate = self
    imageView.contentMode = .scaleAspectFill
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    addSubview(imageView)
    
    imageView.backgroundColor = .clear
    imageView.layer.borderWidth = drawBlackBorder ? 1 : 0
    
    zoomScale = 1
    
    imageDefaultScale.calculateAutoScale(ImageSize: image!.size , ParentViewSize: parentSize, imageType)

    imageScale = imageDefaultScale.auto
    maximumZoomScale = imageDefaultScale.max
    minimumZoomScale = imageDefaultScale.min
    
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    addGestureRecognizer(doubleTapGesture)
   
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
    singleTapGesture.numberOfTapsRequired = 1
    singleTapGesture.numberOfTouchesRequired = 1
    addGestureRecognizer(singleTapGesture)
  }
  
  open override func didMoveToSuperview() {
    super.didMoveToSuperview()
  }
  
  open override func layoutSubviews() {
    
    super.layoutSubviews()
    
    if imageView.image != nil && oldSize != bounds.size {
      
      updateImageView()
      oldSize = bounds.size
    }
    
    if imageView.frame.width <= bounds.width {
      imageView.center.x = bounds.width * 0.5
    }
    
    if imageView.frame.height <= bounds.height {
      imageView.center.y = bounds.height * 0.5
    }
  }
  
  open override func updateConstraints() {
    super.updateConstraints()
    updateImageView()
  }
  
  private func updateImageView() {
    
    func fitSize(aspectRatio: CGSize, boundingSize: CGSize) -> CGSize {
      
      let widthRatio = (boundingSize.width / aspectRatio.width)
      let heightRatio = (boundingSize.height / aspectRatio.height)
      
      var boundingSize = boundingSize
      
      if widthRatio < heightRatio {
        boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height
      }
      else if (heightRatio < widthRatio) {
        boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width
      }
      return CGSize(width: ceil(boundingSize.width), height: ceil(boundingSize.height))
    }
    
    func fillSize(aspectRatio: CGSize, minimumSize: CGSize) -> CGSize {
      let widthRatio = (minimumSize.width / aspectRatio.width)
      let heightRatio = (minimumSize.height / aspectRatio.height)
      
      var minimumSize = minimumSize
      
      if widthRatio > heightRatio {
        minimumSize.height = minimumSize.width / aspectRatio.width * aspectRatio.height
      }
      else if (heightRatio > widthRatio) {
        minimumSize.width = minimumSize.height / aspectRatio.height * aspectRatio.width
      }
      return CGSize(width: ceil(minimumSize.width), height: ceil(minimumSize.height))
    }
    
    guard let image = imageView.image else { return }
    
    var size: CGSize
    
    switch zoomMode {
    case .fit:
      size = fitSize(aspectRatio: image.size, boundingSize: bounds.size)
    case .fill:
      size = fillSize(aspectRatio: image.size, minimumSize: bounds.size)
    }
    
    
    size.height = imageView.image!.size.height
    size.width = imageView.image!.size.width
    
    contentSize = CGSize(width: size.width * imageScale, height: size.height * imageScale)
    imageView.bounds.size = contentSize
      //    print("Content Size: \(contentSize)")
    imageView.center = ZoomImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
  }
  
  var enableDoubleTap: Bool = false
  var enableSingleTap: Bool = true
  @objc private func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
    if !enableDoubleTap {
      return
    }
    zoomScaleEnum = zoomScaleEnum.toNext()
  }
  
  @objc private func handleSingleTap(_ gestureRecognizer: UITapGestureRecognizer) {
    if !enableSingleTap {
      return
    }
    let touchPoint = gestureRecognizer.location(in: imageView)
      //        print("singelTap: \(touchPoint)")
    if !imageView.bounds.contains(touchPoint) {
        // outside image
      tapDelegate?.onImageOutsideTapped()
    } else {
        // inside image
      tapDelegate?.onImageTapped(tapObj)
    }
  }
  
    // This function is borrowed from: https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll
  private func zoomRectFor(scale: CGFloat, with center: CGPoint) -> CGRect {
    let center = imageView.convert(center, from: self)
    
    var zoomRect = CGRect()
    zoomRect.size.height = bounds.height / scale
    zoomRect.size.width = bounds.width / scale
    zoomRect.origin.x = center.x - zoomRect.width / 2.0
    zoomRect.origin.y = center.y - zoomRect.height / 2.0
    
    return zoomRect
  }
  
  var oldZoomScale: CGFloat = 1.0
    // MARK: - UIScrollViewDelegate
  @objc dynamic public func scrollViewDidZoom(_ scrollView: UIScrollView) {
    
    let diff = zoomScale - oldZoomScale

//    debugPrint("zoomScale: \(oldZoomScale) -> \(zoomScale)")
//    debugPrint("imageScale: \(imageScale) + \(diff) ")
    oldZoomScale = zoomScale
    let newImageScale = imageScale + diff
     
    if (newImageScale > imageDefaultScale.max) ||
        (newImageScale < imageDefaultScale.min) {
      return
    }
    
    imageView.center = ZoomImageView.contentCenter(forBoundingSize: bounds.size, contentSize: contentSize)
  }
  
  @objc dynamic public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    
  }
  
  @objc dynamic public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    
  }
  
  @objc dynamic public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  @inline(__always)
  private static func contentCenter(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGPoint {
    
      /// When the zoom scale changes i.e. the image is zoomed in or out, the hypothetical center
      /// of content view changes too. But the default Apple implementation is keeping the last center
      /// value which doesn't make much sense. If the image ratio is not matching the screen
      /// ratio, there will be some empty space horizontaly or verticaly. This needs to be calculated
      /// so that we can get the correct new center value. When these are added, edges of contentView
      /// are aligned in realtime and always aligned with corners of scrollview.
    let horizontalOffest = (boundingSize.width > contentSize.width) ? ((boundingSize.width - contentSize.width) * 0.5): 0.0
    let verticalOffset = (boundingSize.height > contentSize.height) ? ((boundingSize.height - contentSize.height) * 0.5): 0.0
    
    return CGPoint(x: contentSize.width * 0.5 + horizontalOffest,  y: contentSize.height * 0.5 + verticalOffset)
  }
}
