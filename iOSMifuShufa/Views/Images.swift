  //
  //  Images.swift
  //  iOSMifuShufa
  //
  //  Created by lulixue on 2024/11/20.
  //
import SwiftUI
import UIKit
import Foundation

extension UIImage {
  func addWaterMark(_ title: String) -> UIImage {
      //开启图片上下文
    UIGraphicsBeginImageContextWithOptions(self.size, true, 0)
    let bgColor = UIColor.gray
    let context = UIGraphicsGetCurrentContext()!
      //图形重绘
    self.draw(in: CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height))
      //水印文字属性
    let att = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 40), NSAttributedString.Key.backgroundColor: UIColor.clear]
      //水印文字大小
    let text = NSString(string: title)
    let size =  text.size(withAttributes: att)
    let extraWidth: CGFloat = 20
    let extraHeight: CGFloat = 6
      //绘制文字
    
    let rect = CGRect.init(x: self.size.width-size.width-15-extraWidth/2, y: self.size.height-size.height-15-extraHeight/2, width: size.width+extraWidth, height: size.height+extraHeight)
    
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .init(x: rect.minX-extraWidth/2, y: rect.minY-extraHeight/2), size: rect.size))
      //从当前上下文获取图片
    text.draw(in: rect, withAttributes: att)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
      //关闭上下文
    UIGraphicsEndImageContext()
    
    return image!
    
  }
}
