  //
  //  PuzzleLayout.swift
  //  OuyangxunDict
  //
  //  Created by Lulixue on 2020/2/14.
  //  Copyright © 2020 Lulixue. All rights reserved.
  //

import Foundation
import UIKit
import SwiftUI

extension CGFloat {
  func coerceIn(minValue: CGFloat, maxValue: CGFloat) -> CGFloat {
    Swift.max(Swift.min(self, maxValue), minValue)
  }
}

class UnitData {
  private static let MAX: CGFloat = 100000
  var MaxWidth: CGFloat = 0
  var MinWidth: CGFloat = MAX
  var MaxHeight: CGFloat = 0
  var MinHeight: CGFloat = MAX
  var AverageWidth: CGFloat = 0
  var AverageHeight: CGFloat = 0
  var TotalWidth: CGFloat = 0
  var TotalHeight: CGFloat = 0
  var count: Int = 0
  var useWidth: Bool = false
  var bitmaps: [UIImage] = []
  
  func getBitmapDrawSize(_ bitmap: UIImage) -> (CGFloat, CGFloat) {
    if useWidth {
      let height = bitmap.getHeight() * AverageWidth / bitmap.getWidth()
      return (AverageWidth, height)
    } else {
      let width = bitmap.getWidth() * AverageHeight / bitmap.getHeight()
      return (width, AverageHeight)
    }
  }
}


class PuzzleLayout {
  
  static let MIN_AVG_WIDTH: CGFloat = 60
  static let MAX_AVG_WIDTH: CGFloat = 1000
  static let MIN_AVG_HEIGHT: CGFloat = 60
  static let MAX_AVG_HEIGHT: CGFloat = 1000
  
  static func getUnitData(_ images: [UIImage], _ start: Int,_ size: Int, _ type: PuzzleType) -> UnitData {
    let ud = UnitData()
    for i in 0..<images.size {
      if i >= images.count {
        break
      }
      let image = images[i]
      ud.TotalWidth += image.getWidth()
      ud.TotalHeight += image.getHeight()
    }
    
    ud.AverageHeight = (ud.TotalHeight / CGFloat(images.size)).coerceIn(minValue: MIN_AVG_HEIGHT, maxValue: MAX_AVG_HEIGHT)
    ud.AverageWidth = (ud.TotalWidth / CGFloat(images.size)).coerceIn(minValue: MIN_AVG_WIDTH, maxValue: MAX_AVG_WIDTH)
    let useWidth = {
      switch type {
      case .Doufang:
        jinMode
      case .Duilian:
        !jinMode
      case .Multi:
        !jinMode
      case .SingleRow:
        false
      case .SingleColumn:
        true
      }
    }()
    ud.useWidth = useWidth
    var totalWidth: CGFloat = 0
    var totalHeight: CGFloat = 0
    for i in start..<(start+size) {
      if i >= images.count {
        break
      }
      let image = images[i]
      ud.bitmaps.append(image)
      let size = {
        if useWidth {
          let width = image.getWidth()
          let height = image.getHeight() * ud.AverageWidth / width
          return CGSize(width: ud.AverageWidth, height: height)
        } else {
          let height = image.getHeight()
          let width = image.getWidth() * ud.AverageHeight / height
          return CGSize(width: width, height: ud.AverageHeight)
        }
      }()
      let width = size.width
      let height = size.height
      
      totalWidth += width
      totalHeight += height
      
      if (width > ud.MaxWidth) {
        ud.MaxWidth = width
      }
      if (width < ud.MinWidth) {
        ud.MinWidth = width
      }
      if (height > ud.MaxHeight) {
        ud.MaxHeight = height
      }
      if (height < ud.MinWidth) {
        ud.MinHeight = height
      }
    }
    ud.count = ud.bitmaps.count
    ud.TotalHeight = totalHeight
    ud.TotalWidth = totalWidth
    return ud
  }
  
  static var SingleGap: CGFloat {
    PuzzleSettingsItem.SingleGap.intValue.toCGFloat()
  }
  static let DuilianGap: CGFloat = 30
  static var InsetGap: CGFloat {
    PuzzleSettingsItem.InsetGap.intValue.toCGFloat()
  }
  
  static var jinMode: Bool {
    PuzzleSettingsItem.JinMode.boolValue
  }
  
  static var rowsPerCol: Int {
    PuzzleSettingsItem.CharPerColumnRow.intValue
  }
  
  static func drawMultiColumnsJin(bitmaps: [UIImage], bgColor: UIColor) -> UIImage {
    let SingleGap = SingleGap
    let InsetGap = InsetGap
    let rowsPerCol = rowsPerCol
    let gap = SingleGap
    let count = bitmaps.count
    var columns = count / rowsPerCol
    if (count % rowsPerCol > 0) {
      columns += 1
    }
    
    var totalWidth: CGFloat = 0
    var totalHeight: CGFloat = 0
    
    for bmp in bitmaps {
      totalWidth += bmp.getWidth()
      totalHeight += bmp.getHeight()
    }
    var destWidth: CGFloat = 0
    var destHeight: CGFloat = 0
    
    var unitDatas: [UnitData] = []
    
    for i in (0..<columns) {
      let ud = getUnitData(bitmaps, i * rowsPerCol, rowsPerCol, .Multi)
      if (ud.TotalWidth > destWidth) {
        destWidth = ud.TotalWidth
      }
      destHeight += ud.MaxHeight
      unitDatas.append(ud)
    }
    
    destWidth += CGFloat(columns - 1)  * gap
    destHeight += CGFloat(rowsPerCol - 1) * gap
    
      // 添加边框宽度
    destWidth += 2 * InsetGap
    destHeight += 2 * InsetGap
    
    var dstBmpDrawY: CGFloat = 0.0
    var offsetX: CGFloat = 0.0
    var offsetY: CGFloat = 0.0
    
    
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    for i in 0..<unitDatas.count {
      let ud = unitDatas[i]
      
      dstBmpDrawY = InsetGap
      for j in 0..<i {
        dstBmpDrawY += unitDatas[j].MaxHeight + gap
      }
      
      offsetX = InsetGap
      
      for srcBitmap in ud.bitmaps {
        let (drawWidth, drawHeight) = ud.getBitmapDrawSize(srcBitmap)
        offsetY = (ud.MaxHeight - drawHeight) / 2
        offsetY += dstBmpDrawY
        
        srcBitmap.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
        offsetX += drawWidth + gap
      }
    }
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
  
  static func drawMultiColumns(bitmaps: [UIImage], bgColor: UIColor) -> UIImage {
    if jinMode {
      return drawMultiColumnsJin(bitmaps: bitmaps, bgColor: bgColor)
    }
    let SingleGap = SingleGap
    let InsetGap = InsetGap
    let rowsPerCol = rowsPerCol
    let gap = SingleGap
    let count = bitmaps.count
    var columns = count / rowsPerCol
    if (count % rowsPerCol > 0) {
      columns += 1
    }
    
    var totalWidth: CGFloat = 0
    var totalHeight: CGFloat = 0
    
    for bmp in bitmaps {
      totalWidth += bmp.getWidth()
      totalHeight += bmp.getHeight()
    }
    var destWidth: CGFloat = 0
    var destHeight: CGFloat = 0
    
    var unitDatas: [UnitData] = []
    
    for i in (0..<columns).reversed() {
      let ud = getUnitData(bitmaps, i * rowsPerCol, rowsPerCol, .Multi)
      if (ud.TotalHeight > destHeight) {
        destHeight = ud.TotalHeight
      }
      destWidth += ud.MaxWidth
      unitDatas.append(ud)
    }
    
    destWidth += CGFloat(columns - 1)  * gap
    destHeight += CGFloat(rowsPerCol - 1) * gap
     
      // 添加边框宽度
    destWidth += 2 * InsetGap
    destHeight += 2 * InsetGap
    
    var dstBmpDrawX: CGFloat = 0.0
    var offsetX: CGFloat = 0.0
    var offsetY: CGFloat = 0.0
    
    
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    for i in 0..<unitDatas.count {
      let ud = unitDatas[i]
      
      dstBmpDrawX = InsetGap
      for j in 0..<i {
        dstBmpDrawX += unitDatas[j].MaxWidth + gap
      }
      
      offsetY = InsetGap
      
      for srcBitmap in ud.bitmaps {
        let (drawWidth, drawHeight) = ud.getBitmapDrawSize(srcBitmap)
        offsetX = (ud.MaxWidth - drawWidth) / 2
        offsetX += dstBmpDrawX
        
        srcBitmap.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
        offsetY += drawHeight + gap
      }
    }
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
  static func drawDuilianJin(bitmaps: [UIImage], bgColor: UIColor) -> UIImage {
    let SingleGap = SingleGap
    let InsetGap = InsetGap
    let gap = SingleGap
    let count = bitmaps.count
    let rows = count/2
    let udLeft =  getUnitData(bitmaps, 0, rows, .Duilian)
    let udRight = getUnitData(bitmaps, rows, 2*rows, .Duilian)
    
    let maxWidth = Utils.getMore(udLeft.TotalWidth, udRight.TotalWidth)
    let destWidth = maxWidth + DuilianGap + 2 * InsetGap
    let destHeight = udLeft.MaxHeight + udRight.MaxHeight + DuilianGap + 2 * InsetGap
    
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    var offsetY = InsetGap
    var offsetX: CGFloat = InsetGap + (maxWidth - udLeft.TotalWidth) / 2
    
    for bmp in udLeft.bitmaps {
      let (drawWidth, drawHeight) = udLeft.getBitmapDrawSize(bmp)
      offsetY = InsetGap + (udLeft.MaxHeight - drawHeight) / 2
      
      bmp.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
      offsetX += gap + drawWidth
    }
    
    offsetX = InsetGap + (maxWidth - udRight.TotalWidth) / 2
    for bmp in udRight.bitmaps {
      let (drawWidth, drawHeight) = udLeft.getBitmapDrawSize(bmp)
      offsetY = InsetGap + (udRight.MaxHeight - drawHeight) / 2 + DuilianGap + udLeft.MaxHeight
      bmp.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
      offsetX += gap + drawWidth
    }
    
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
  static func drawDuilian(bitmaps: [UIImage], bgColor: UIColor) -> UIImage {
    
    if bitmaps.count % 2 != 0 {
      fatalError()
    }
    if jinMode {
      return drawDuilianJin(bitmaps: bitmaps, bgColor: bgColor)
    }
    let SingleGap = SingleGap
    let InsetGap = InsetGap
    let gap = SingleGap
    let count = bitmaps.count
    let rows = count/2
    let udLeft =  getUnitData(bitmaps, rows, rows, .Duilian)
    let udRight = getUnitData(bitmaps, 0, rows, .Duilian)
    
    let maxHeight = Utils.getMore(udLeft.TotalHeight, udRight.TotalHeight)
    let destWidth = udRight.MaxWidth + udLeft.MaxWidth + DuilianGap + 2 * InsetGap
    let destHeight = maxHeight + (CGFloat(rows - 1) * gap) + 2 * InsetGap
    
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    var offsetY = (maxHeight - udLeft.TotalHeight) / 2 + InsetGap
    var offsetX: CGFloat
    
    for bmp in udLeft.bitmaps {
      let (drawWidth, drawHeight) = udLeft.getBitmapDrawSize(bmp)
      offsetX = InsetGap + (udLeft.MaxWidth - drawWidth) / 2
      
      bmp.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
      offsetY += gap + drawHeight
    }
    
    offsetY = (maxHeight - udRight.TotalHeight) / 2 + InsetGap
    for bmp in udRight.bitmaps {
      let (drawWidth, drawHeight) = udLeft.getBitmapDrawSize(bmp)
      offsetX = udLeft.MaxWidth + DuilianGap + InsetGap + (udRight.MaxWidth - drawWidth) / 2
      bmp.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
      offsetY += gap + drawHeight
    }
    
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
  
  static func drawVertical(bitmaps: [UIImage], bgColor: UIColor) -> UIImage {
    let count = CGFloat(bitmaps.count)
    let ud = getUnitData(bitmaps, 0, bitmaps.count, .SingleColumn)
    
    let gap = SingleGap
    let destHeight = ud.TotalHeight + (count - 1) * gap + 2 * InsetGap
    let destWidth = ud.MaxWidth + 2 * InsetGap
    
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    var offsetY: CGFloat = InsetGap
    var offsetX: CGFloat = 0
    for i in 0..<(bitmaps.count) {
      let bmp = bitmaps[i]
      let (drawWidth, drawHeight) = ud.getBitmapDrawSize(bmp)
      offsetX = InsetGap + (ud.MaxWidth - drawWidth) / 2
    
      bmp.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
      
      offsetY += gap + drawHeight
    }
    
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
  static func charImage(c: Char) -> UIImage {
    let destWidth: CGFloat = 60
    let destHeight: CGFloat = 60
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(UIColor.black.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    let font = UIFont.systemFont(ofSize: 20)
    let string = NSAttributedString(string: c.toString(), attributes: [NSAttributedString.Key.font: font])
    string.draw(in: CGRect(x: 0, y: 0, width: destWidth, height: destHeight))
    
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
  static func drawHorizontal(bitmaps: [UIImage], bgColor: UIColor) -> UIImage {
    let count = CGFloat(bitmaps.count)
    let drawBitmaps = jinMode ? bitmaps : bitmaps.reversed()
    let SingleGap = SingleGap
    let InsetGap = InsetGap
    let ud = getUnitData(drawBitmaps, 0, bitmaps.count, .SingleRow)
    let gap: CGFloat = SingleGap
    
    let destWidth = ud.TotalWidth + (count - 1) * gap + 2 * InsetGap
    let destHeight = ud.MaxHeight + 2 * InsetGap
    
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
    var offsetY: CGFloat = 0
    var offsetX: CGFloat = InsetGap
    for i in (0..<(drawBitmaps.count)) {
      let bmp = drawBitmaps[i]
      let (drawWidth, drawHeight) = ud.getBitmapDrawSize(bmp)
      offsetY = InsetGap + (ud.MaxHeight - drawHeight) / 2
      
      bmp.draw(in: CGRect(x: offsetX, y: offsetY, width: drawWidth, height: drawHeight))
      
      offsetX += gap + drawWidth
    }
    
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
  private static func doufanDrawSize(_ bmp: UIImage, _ size: CGFloat) -> (CGFloat, CGFloat) {
    let bmpRatio = bmp.getWidth() / bmp.getHeight()
    if bmpRatio < 1 {
      return (bmp.getWidth() * size / bmp.getHeight(), size)
    } else {
      return (size, bmp.getHeight() * size / bmp.getWidth())
    }
  }
  
  static func drawDoufang(bitmaps: [UIImage], bgColor: UIColor) -> UIImage {
    if bitmaps.count != 4 {
      fatalError()
    }
    let InsetGap = InsetGap
    let jinMode = jinMode
    let bmpTop = jinMode ? [bitmaps[0], bitmaps[1]] : [bitmaps[2], bitmaps[0]]
    let bmpBottom = jinMode ? [bitmaps[2], bitmaps[3]] : [bitmaps[3], bitmaps[1]]
    let gap: CGFloat = SingleGap
    
    let itemSize = {
      var totalWidth: CGFloat = 0
      var totalHeight: CGFloat = 0
      for bmp in bitmaps {
        totalWidth += bmp.getWidth()
        totalHeight += bmp.getHeight()
      }
      return min(max(totalWidth/4, max(totalHeight/4, MIN_AVG_WIDTH)), MAX_AVG_WIDTH)
    }()
     
    let destWidth = itemSize * 2 + gap + 2 * InsetGap
    let destHeight = itemSize * 2 + gap + 2 * InsetGap
    
    let size = CGSize(width: destWidth, height: destHeight)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    context.setFillColor(bgColor.cgColor)
    context.fill(CGRect(origin: .zero, size: size))
    
      // 左上
    var bmp = bmpTop[0]
    var (drawWidth, drawHeight) = doufanDrawSize(bmp, itemSize)
    var offsetY = InsetGap
    var offsetX = InsetGap
    bmp.draw(in: CGRect(x: offsetX + abs(drawWidth - itemSize) / 2, y: offsetY + abs(drawHeight - itemSize) / 2, width: drawWidth, height: drawHeight))
    
      // 右上
    bmp = bmpTop[1]
    (drawWidth, drawHeight) = doufanDrawSize(bmp, itemSize)
    offsetY = InsetGap
    offsetX = itemSize + InsetGap + gap
    bmp.draw(in: CGRect(x: offsetX + abs(drawWidth - itemSize) / 2, y: offsetY + abs(drawHeight - itemSize) / 2, width: drawWidth, height: drawHeight))
    
    
      // 左下
    bmp = bmpBottom[0]
    (drawWidth, drawHeight) = doufanDrawSize(bmp, itemSize)
    offsetY = InsetGap
    offsetY += itemSize + gap
    offsetX = InsetGap
    bmp.draw(in: CGRect(x: offsetX + abs(drawWidth - itemSize) / 2, y: offsetY + abs(drawHeight - itemSize) / 2, width: drawWidth, height: drawHeight))
    
      // 右下
    bmp = bmpBottom[1]
    (drawWidth, drawHeight) = doufanDrawSize(bmp, itemSize)
    offsetY = gap
    offsetY += itemSize + InsetGap
    offsetX = gap
    offsetX += itemSize + InsetGap
    bmp.draw(in: CGRect(x: offsetX + abs(drawWidth - itemSize) / 2, y: offsetY + abs(drawHeight - itemSize) / 2, width: drawWidth, height: drawHeight))
    
    let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
  }
  
}

extension UIImage {
  func getHeight() -> CGFloat {
    return self.size.height
  }
  func getWidth() -> CGFloat {
    return self.size.width
  }
}
