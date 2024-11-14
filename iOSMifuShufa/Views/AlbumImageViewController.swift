  //
  //  AlbumImageViewController.swift
  //  OuyangxunDict
  //
  //  Created by Lulixue on 2020/2/8.
  //  Copyright © 2020 Lulixue. All rights reserved.
  //

import UIKit

class AlbumImageViewController: UIViewController, SDImageDelegate {
  func downloadProgress(_ downloaded: Int, _ total: Int) {
    let dnlded = ByteCountFormatter.string(fromByteCount: Int64(downloaded), countStyle: .decimal)
    let total = ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .decimal)
    
    DispatchQueue.main.async {
      self.progressLabel.text = "正在下载：".orCht("正在下載：") + dnlded + " / " + total
    }
  }
  
  func downloadComplete() {
    DispatchQueue.main.async {
      self.loadingIndicator.stopAnimating()
      self.loadingIndicator.isHidden = true
      self.progressLabel.isHidden = true
    }
  }
  
  @IBOutlet weak var progressLabel: UILabel!
  private var parentSize: CGSize = .zero
  private var image: UIImage? = nil
  override func viewDidLoad() {
    super.viewDidLoad()
    
    albumImage.sdDelegate = self
    loadingIndicator.startAnimating()
    
  }
  override func viewWillAppear(_ animated: Bool) {
    albumImage.imageType = .image
    albumImage.enableDoubleTap = true
      //        Utils.printViewSize(parent!.view)
    albumImage.parentSize = parentSize
    if let url = imageUrl {
      albumImage.setImageUrl(url)
    } else {
      albumImage.image = self.image!
      albumImage.setup()
      albumImage.sdDelegate?.downloadComplete()
    }
    albumImage.zoomMode = .fit
  }
  
  func initAlbumImage(_ item: BeitieImage, _ parentSize: CGSize) {
    imageUrl = item.url(.JpgCompressed)
    self.parentSize = parentSize
  }
  
  func initAlbumImage(_ image: UIImage, _ parentSize: CGSize) {
    self.image = image
    self.parentSize = parentSize
  }
  
  var text: String?
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  var imageUrl: String?
  var compressImageUrl: String?
  @IBOutlet weak var albumImage: ZoomImageView!
  
  
  
}
