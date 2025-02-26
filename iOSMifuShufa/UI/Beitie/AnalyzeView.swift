//
//  OpenCVTestView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/25.
//

import SwiftUI
import opencv2
import Foundation
import SDWebImageSwiftUI

typealias Point = Point2i
typealias RectF = CGRect
typealias Bitmap = UIImage
typealias MutableList = Array

enum MiGridType: String ,CaseIterable {
  case GridNone, Grid9GongGe, GridMi, Grid16GoneGe, GridMiCircle, Grid36GoneGe;
}

extension FilterProperty {
  var reachMax: Bool {
    isVipProperty() && !CurrentUser.isVip && ConstraintItem.CentroidAnalyze.readUsageMaxCount()
  }
  
  var reachCountMax: Bool {
    isVipProperty() && !CurrentUser.isVip && ConstraintItem.CentroidMiCount.readUsageMaxCount()
  }
}

class ImageProcessor {
  
  static func drawWHRatio(_ bitmap: Bitmap, ratio: String, leftTop: Point, rightBottom: Point) -> Bitmap {
    let size = bitmap.size
    UIGraphicsBeginImageContextWithOptions(size, true, 0)
    let bgColor = UIColor.gray
    let context = UIGraphicsGetCurrentContext()!
    //图形重绘
    bitmap.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
    //水印文字属性
    let att = [NSAttributedString.Key.foregroundColor: UIColor.yellow, NSAttributedString.Key.font: UIFont.systemFont(ofSize: max(20, size.height/50)), NSAttributedString.Key.backgroundColor: UIColor.clear]
    //水印文字大小
    let text = NSString(string: ratio)
    let s = text.size(withAttributes: att)
    let extraWidth: CGFloat = 20
    let extraHeight: CGFloat = 6
    //绘制文字
    
    let bottom = min(rightBottom.y.int.toCGFloat() + extraHeight/2 + s.height/2, size.height-5-s.height)
    
    let rect = CGRect.init(x: size.width/2-s.width/2-extraWidth/2, y: bottom, width: s.width+extraWidth, height: s.height+extraHeight)
    
    
    context.setFillColor(bgColor.cgColor)
    context.fill(rect)
    //从当前上下文获取图片
    text.draw(at: CGPoint(x: rect.minX + extraWidth/2, y: rect.minY + extraHeight/2), withAttributes: att)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    //关闭上下文
    UIGraphicsEndImageContext()
    return image!
  }
  
  private static let MIN_GRID_WIDTH: CGFloat = 0.3
  private static let MAX_GRID_WIDTH: CGFloat = 1.5
  private static func getMiGridWidth(_ bitmap: Bitmap) -> CGFloat {
    var width = min(bitmap.width, bitmap.height) / 300.0
    width = max(width, MIN_GRID_WIDTH)
    width = min(width, MAX_GRID_WIDTH)
    return width
  }
  
  static func addSingleMiGrid(single: BeitieSingle, bitmap: Bitmap, miGrid: MiGridType, showCentroid: Boolean = AnalyzeHelper.singleCentroidMi) -> Bitmap {
      let folder = single.work.folder
    var centroid: CGPoint? = nil
    var radius: CGFloat? = nil
    let color: UIColor = AnalyzeHelper.getMiGridColor(bitmap: bitmap, folder: folder)
    if (showCentroid) {
      (centroid, radius) = AnalyzeHelper.getCentroidMiGrid(org: bitmap, folder: folder)
    }
    return addMiGrid(bitmap: bitmap, color: color, centroid: centroid, centerRadius: radius, type: miGrid)
  }
  
  static func addMiGrid(bitmap: Bitmap, color: UIColor = UIColor.black, centroid: CGPoint? = nil,
                        centerRadius: CGFloat? = nil, width: CGFloat? = nil,
                        type: MiGridType = MiGridType.GridMiCircle) -> Bitmap {
    if (type == MiGridType.GridNone) {
      return bitmap
    }
    let penWidth = width ?? getMiGridWidth(bitmap)
    
    let size = bitmap.size
    UIGraphicsBeginImageContextWithOptions(size, true, 0)
    let context = UIGraphicsGetCurrentContext()!
     
    let rc = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    bitmap.draw(in: rc)
    let strokeWidth = penWidth
    context.setLineDash(phase: 2, lengths: [4, 5, 6])
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(strokeWidth)
    var miRect = CGRect(x: strokeWidth/2, y: strokeWidth/2, width: size.width-strokeWidth, height: size.height-strokeWidth)
    context.stroke(rc, width: strokeWidth)
    
    // 绘制米字
    if let centroid {
      let centerX = centroid.x
      let centerY = centroid.y
      let radius = (centerRadius! - penWidth)
      
      let left = fixXY(centerX - radius)
      let right = fixXYMinus(centerX + radius)
      let top = fixXY(centerY - radius)
      let bottom = fixXYMinus(centerY + radius)
      let borderRect = CGRect(x: left.toInt(), y: top.toInt(), width: right.toInt()-left.toInt(), height: bottom.toInt() - top.toInt())
      miRect = borderRect
//      context.stroke(borderRect)
    } else {
      context.stroke(miRect)
    }
    
    let path = getMiGridPath(miRect: miRect, type: type)
    
    for p in path {
      context.addPath(p.cgPath)
      context.drawPath(using: .stroke)
      context.closePath()
    }
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    //关闭上下文
    UIGraphicsEndImageContext()
    return image!
  }
  
  
  static func addMiGridSolid(_ bitmap: Bitmap, type: MiGridType, strokeWidth: CGFloat = 2) -> Bitmap {
    let size = bitmap.size
    UIGraphicsBeginImageContextWithOptions(size, true, 0)
    let bgColor = UIColor.white
    let context = UIGraphicsGetCurrentContext()!
    
    let rc = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    bitmap.draw(in: rc)
    
    context.setStrokeColor(bgColor.cgColor)
    context.setLineWidth(strokeWidth)
    let miRect = CGRect(x: strokeWidth/2, y: strokeWidth/2, width: size.width-strokeWidth, height: size.height-strokeWidth)
    context.stroke(rc, width: strokeWidth)
    context.setLineDash(phase: 1.0, lengths: [5])
    // 绘制米字
    let path = getMiGridPath(miRect: miRect, type: type)
    
    for p in path {
      context.addPath(p.cgPath)
      context.drawPath(using: .stroke)
      context.closePath()
    }
  
    let image = UIGraphicsGetImageFromCurrentImageContext()
    //关闭上下文
    UIGraphicsEndImageContext()
    return image!
  }
  
  private static func fixXY(_ value: CGFloat) -> CGFloat {
    return value
  }
  
  private static func fixXYMinus(_ value: CGFloat) -> CGFloat {
    return value
  }
  
  private static func getMiGridPath(miRect: CGRect, type: MiGridType) -> [Path] {
    var path = Path()
    let centerX = fixXY(miRect.centerX())
    let centerY = fixXY(miRect.centerY())
    let radius = min(miRect.width/2, miRect.height/2)
    func drawGrid(_ grid: Int) {
      for i in 1...grid {
        let y = fixXY(miRect.top + (miRect.height() * (i.toCGFloat() / grid.toCGFloat())))
        path.moveTo(miRect.left, y)
        path.lineTo(miRect.right, y)
      }
      for i in 1...grid {
        let x = fixXY(miRect.left + (miRect.width() * (i.toCGFloat() / grid.toCGFloat())))
        path.moveTo(x, miRect.top)
        path.lineTo(x, miRect.bottom)
      }
    }
    switch type {
    case MiGridType.GridMi, MiGridType.GridMiCircle: do {
      path.moveTo(centerX, miRect.top)
      path.lineTo(centerX, miRect.bottom)
      path.moveTo(miRect.left, centerY)
      path.lineTo(miRect.right, centerY)
      
      path.moveTo(miRect.left, miRect.top)
      path.lineTo(miRect.right, miRect.bottom)
      path.moveTo(miRect.right, miRect.top)
      path.lineTo(miRect.left, miRect.bottom)
      if (type != MiGridType.GridMi) {
        var circlePath = Path()
        circlePath.addCircle(centerX, centerY, radius)
        return [path, circlePath]
      }
    }
    case MiGridType.Grid36GoneGe: drawGrid(6)
    case MiGridType.Grid16GoneGe: drawGrid(4)
    case MiGridType.Grid9GongGe: drawGrid(3)
    case MiGridType.GridNone: do {}
    }
    return [path]
  }
}

extension Path {
  mutating func moveTo(_ x: CGFloat, _ y: CGFloat) {
    self.move(to: CGPoint(x: x.toDouble(), y: y.toDouble()))
  }
  mutating func lineTo(_ x: CGFloat, _ y: CGFloat) {
    self.addLine(to: CGPoint(x: x.toDouble(), y: y.toDouble()))
  }
  
  mutating func addCircle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) {
    self.addArc(center: CGPoint(x: x.toDouble(), y: y.toDouble()), radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
  }
}

extension Bitmap {
  var width: CGFloat {
    size.width
  }
  
  var height: CGFloat {
    size.height
  }
}

extension CGRect {
  
  var top: CGFloat {
    minY
  }
  
  var left: CGFloat {
    minX
  }
  
  var bottom: CGFloat {
    maxY
  }
  
  var right: CGFloat {
    maxX
  }
  
  func centerX() -> CGFloat {
    (minX + maxX) / 2
  }
  func centerY() -> CGFloat {
    (minY + maxY) / 2
  }
  
  func width() -> CGFloat {
    width
  }
  
  func height() -> CGFloat {
    height
  }
}

class OpenCvImage {
  private static let VIP_TEXT = "VIP"
  
  static let cannyRange = FilterRange(min: 0, def: 50, max: 100, offset: 0)
  static let sharpenRange = FilterRange(min: 0, def: 10, max: 20)
  static let binaryRange = FilterRange(min: -50, def: 0, max: 50, offset: 100)
  
  private static let MIN_VALIDATE_AREA = 100
  private static let COLOR_MAX = 255.0
  // Scalar( a, b, c ) RGB color such as: Blue = a, Green = b and Red = c
  // RGB normal
  private static let COLOR_GRAY = Scalar(211.0, 211.0,211.0, 255.0)
  private static let COLOR_BLUE = Scalar(0.0, 0.0, COLOR_MAX, 255.0)
  private static let COLOR_RED = Scalar(COLOR_MAX, 0.0, 0.0, 255.0)
  private static let COLOR_GREEN = Scalar(0.0, COLOR_MAX, 0.0, 255.0)
  private static let COLOR_YELLOW = Scalar(COLOR_MAX, COLOR_MAX, 0.0, 255.0)
  private static let COLOR_PURPLE = Scalar(  160.0,32.0, 240.0, 255.0)
  private static let COLOR_WHITE = Scalar(COLOR_MAX, COLOR_MAX, COLOR_MAX, 255.0)
  private static let COLORS = Array.arrayOf(COLOR_BLUE, COLOR_RED, COLOR_GREEN, COLOR_YELLOW, COLOR_PURPLE)
  
  static let CONVEX_PROFILE = 0
  static let CONVEX_CONTOUR = 1
  static let CONVEX_BORDER = 2
  
  static func getOppositeMeanColor(_ bmp: Bitmap) -> UIColor {
    let scalar = getOppositeMeanScalar(bmp)
    let (b, g, r) = (scalar.val[0], scalar.val[1], scalar.val[2])
    
    return UIColor(red: r.intValue, green: g.intValue, blue: b.intValue)
  }
  
  private static func getOppositeMeanScalar(_ bmp: Bitmap) -> Scalar {
    let src = bitmapToMat(bmp)
    let mean = Core.mean(src: src)
    let (b, g, r, a) = (mean.val[0].doubleValue, mean.val[1].doubleValue, mean.val[2].doubleValue, mean.val[3].doubleValue)
    return Scalar(COLOR_MAX-b, COLOR_MAX-g, COLOR_MAX-r, a)
  }
  
  private static func bitmapToMat(_ bmp: Bitmap) -> Mat {
    Mat(uiImage: bmp)
  }
  
  private static func drawEllipse(_ img: Mat, _ pnt: Point, _ color: Scalar, _ thickness: Int) {
    let axe = min(thickness.toDouble(), 3.0)
    let axes = Size(width: axe.int.int32, height: axe.int.int32)
    Imgproc.ellipse(img: img,
                    center: pnt,
                    axes: axes, angle: 0.0,
                    startAngle: 0.0,
                    endAngle: 360.0,
                    color: color,
                    thickness: thickness.int32,
                    lineType: .LINE_AA,
                    shift: 0)
  }
  
  static func addText(_ mat: Mat, _ txt: String = OpenCvImage.VIP_TEXT) {
    let fontScale = 3.0
    let thickness = 10.int32
    let draw = Mat()
    mat.copy(to: draw)
    
    let width = mat.cols().int.toDouble()
    let height = mat.rows().int.toDouble()
    var baseline: Int32 = 0
    let size = Imgproc.getTextSize(text: txt, fontFace: .FONT_HERSHEY_TRIPLEX, fontScale: fontScale, thickness: thickness, baseLine: &baseline)
    
    let startY = min(height/2.0 + baseline.double, (height-10.0))
    let startX = max(width/2.0 - size.width.double/2.0, 0.0)
    
    let roiH = min(size.height.double*2, height-startY)
    let roiW = width
    let x = 0
    let y = max((height/2.0 - roiH/2).toInt(), 0)
    let roi = Rect(x: x.int32, y: y.int32, width: roiW.int.int32, height: roiH.int.int32)
    
    Imgproc.rectangle(img: draw, rec: roi, color: COLOR_GRAY, thickness: -1)
    drawEllipse(draw, Point(x: Int32(width/2.0), y: Int32(height/2.0)), COLOR_RED, 3)
    Imgproc.putText(img: draw, text: txt, org: Point(x: startX.int.int32, y: startY.int.int32),
                    fontFace: .FONT_HERSHEY_TRIPLEX, fontScale: fontScale, color: COLOR_BLUE, thickness: thickness)
    
    let alpha = 0.7
    Core.addWeighted(src1: draw, alpha: alpha, src2: mat, beta: 1 - alpha, gamma: 0.0, dst: mat)
  }
  
  static func matToBitmap(_ mat: Mat) -> UIImage {
    mat.toUIImage()
  }
  
  static func mosaicImage(_ bmp: Bitmap, level: Int = 50) -> UIImage {
    let src = bitmapToMat(bmp)
    let rgbSrc = Mat()
    Imgproc.cvtColor(src: src, dst: rgbSrc, code: .COLOR_BGRA2BGR)
    
    let width = rgbSrc.cols().int
    let height = rgbSrc.rows().int
    
    for i in stride(from: 0, through: width, by: level) {
      for j in stride(from: 0, through: height, by: level) {
        var w = level
        if ((width - i) < level) {
          w = width - i
        }
        var h = level
        if ((height - j) < level) {
          h = height - j
        }
        let rc = Rect(x: i.int32, y: j.int32, width: w.int32, height: h.int32)
        let roi = rgbSrc.submat(roi: rc)
        
        let array = rgbSrc.get(row: i.int32, col: j.int32)
        
        let scalar = Scalar(array[0], array[1], array[2])
        
        let roiCopy = Mat(size: roi.size(), type: CvType.CV_8UC3, scalar: scalar)
        roiCopy.copy(to: roi)
      }
    }
    addText(rgbSrc)
    return matToBitmap(rgbSrc)
  }
  
  private static let MAX_BINARY_VALUE = 255
  
  private static func getBitmapHullOutline(_ bmp: Bitmap) -> MutableList<MatOfPoint>? {
    let src = bitmapToMat(bmp)
    let rows = src.rows()
    let cols = src.cols()
    
    let contours: NSMutableArray = NSMutableArray()
    let hierarchy = Mat()
    
    let mean = Core.mean(src: src)
    let (b, g, r, a) = mean.val.fourDoubles
    
    let cannyOutput = Mat.zeros(src.rows(), cols: src.cols(), type: CvType.CV_8UC1)
    if ((a+b+g+r) > 10.0) {
      let original = bitmapToMat(bmp)
      let srcGray = Mat.zeros(src.rows(), cols: src.cols(), type: src.type())
      let radius = 3
      Imgproc.cvtColor(src: original, dst: original, code: .COLOR_BGRA2BGR) // 变更为CV_8UC3
      Imgproc.bilateralFilter(src: original,
                              dst: src, d: radius.int32, sigmaColor: radius.toDouble() * 2.toDouble(), sigmaSpace: radius.toDouble() / 2.0)
      Imgproc.cvtColor(src: src, dst: srcGray, code: .COLOR_BGR2GRAY)
      Imgproc.threshold(src: srcGray, dst: cannyOutput, thresh: 127.0, maxval: MAX_BINARY_VALUE.toDouble(), type: .THRESH_BINARY)
    } else {
      Imgproc.cvtColor(src: src, dst: cannyOutput, code: .COLOR_BGR2GRAY) // 变更为CV_8UC1
    }
    
    Imgproc.findContours(image: cannyOutput, contours: contours, hierarchy: hierarchy, mode: .RETR_TREE, method: .CHAIN_APPROX_SIMPLE)
    
    
    // CONVEX_PROFILE
    var hullList = ArrayList<MatOfPoint>()
    var allContours = ArrayList<Point2i>()
    for c in contours {
      let contour = MatOfPoint(array: c as! [Point2i])
      let hull = contourToConvexHull(contour)
      hullList.add(hull)
      
      // 过滤破损的小块
      let area = Imgproc.contourArea(contour: contour)
      if (Int(area) > MIN_VALIDATE_AREA && !contourIsOnEdge(contour, cols.int, rows.int)) {
        allContours.addAll(contour.toArray())
      }
    }
    
    if (contours.count > 0 && allContours.count > 0) {
      let hullOutlineInt = IntVector([1])
      let totalContour = MatOfPoint()
      totalContour.fromArray(allContours)
      Imgproc.convexHull(points: totalContour.toArray(), hull: hullOutlineInt)
      var hullOutline: MutableList<MatOfPoint> = ArrayList()
      hullOutline.add(contourToConvexHull(totalContour))
      
      return hullOutline
      
    }
    return nil
  }
  
  private static let MIN_OFFSET = 5
  
  private static func contourIsOnEdge(_ contour: MatOfPoint, _ cols: Int, _ rows: Int) -> Boolean {
    for p in contour.toArray() {
      if (p.x.int <= MIN_OFFSET || p.y.int <= MIN_OFFSET || (cols - p.x.int) <= MIN_OFFSET ||
          (rows - p.y.int) <= MIN_OFFSET) {
        return true
      }
    }
    return false
  }
  
  private static func contourToConvexHull(_ contour: MatOfPoint) -> MatOfPoint {
    let hull = IntVector([1])
    Imgproc.convexHull(points: contour.toArray(), hull: hull)
    let contourArray = contour.toArray()
    var hullPoints = Array<Point>()
    let hullContourIdxList = hull.array
    for i in hullContourIdxList.indices {
      hullPoints.append(contourArray[hullContourIdxList[i].int])
    }
    return MatOfPoint(array: hullPoints)
  }
  
  
  static func getBitmapCentroidRadius(_ bmp: Bitmap) -> (CGPoint?, CGFloat) {
    let hullOutline = getBitmapHullOutline(bmp)
    let rows = bmp.size.width
    let cols = bmp.size.height
    if (hullOutline != nil) {
      // 获取重心centroid
      let moments = Imgproc.moments(array: hullOutline![0])
      let cx = (moments.m10 / moments.m00)
      let cy = (moments.m01 / moments.m00)
      
      return (CGPoint(x: cx, y: cy), abs(CGFloat(min(min(rows-cx, cx), min(cols-cy, cy)))))
    }
    return (nil, CGFloat(-1))
  }
  
  /**
   * Types:
   * Imgproc.THRESH_BINARY,
   * Imgproc.THRESH_BINARY_INV,
   * Imgproc.THRESH_TRUNC,
   * Imgproc.THRESH_TOZERO,
   * Imgproc.THRESH_TOZERO_INV
   */

  static func thresholdImage(_ bmp: Bitmap, _ value: Int, _ type: ThresholdTypes) -> Bitmap {
    let src = bitmapToMat(bmp)
    let dst = Mat.zeros(src.rows(), cols: src.cols(), type: CvType.CV_8UC1)
    let srcGray = Mat.zeros(src.rows(), cols: src.cols(), type: CvType.CV_8UC1)
    debugPrint("thresholdImage depth: \(src.channels())")
    if src.channels() >= 3 {
      Imgproc.cvtColor(src: src, dst: srcGray, code: .COLOR_BGR2GRAY)
      Imgproc.threshold(src: srcGray, dst: dst, thresh: value.toDouble(), maxval: MAX_BINARY_VALUE.toDouble(), type: type)
    }
    return matToBitmap(dst)
  }
  
  static func convexHullBitmap(_ bmp: Bitmap, draw: Bitmap, type: Int) -> Bitmap {
    let src = bitmapToMat(bmp)
    let eventually = bitmapToMat(draw)
    let rows = src.rows()
    let cols = src.cols()
    
    let contours: NSMutableArray = NSMutableArray()
    let hierarchy = Mat()
    
    let mean = Core.mean(src: src)
    let (b, g, r, a) = mean.val.fourDoubles
    
    debugPrint("convexHullBitmap \(src.channels())")
    let cannyOutput = Mat.zeros(src.rows(), cols: src.cols(), type: CvType.CV_8UC1)
    if ((a+b+g+r) > 10.0) {
      let original = bitmapToMat(bmp)
      let srcGray = Mat.zeros(src.rows(), cols: src.cols(), type: src.type())
      let radius = 3
      Imgproc.cvtColor(src: original, dst: original, code: .COLOR_BGRA2BGR) // 变更为CV_8UC3
      Imgproc.bilateralFilter(src: original,
                              dst: src, d: Int32(radius), sigmaColor: Double(radius) * 2.toDouble(), sigmaSpace: Double(radius) / 2.0)
      Imgproc.cvtColor(src: src, dst: srcGray, code: .COLOR_BGR2GRAY)
      Imgproc.threshold(src: srcGray, dst: cannyOutput, thresh: 127.0, maxval: MAX_BINARY_VALUE.toDouble(), type: .THRESH_BINARY)
    } else {
      Imgproc.cvtColor(src: src, dst: cannyOutput, code: .COLOR_BGR2GRAY) // 变更为CV_8UC1
    }
    
    Imgproc.findContours(image: cannyOutput, contours: contours, hierarchy: hierarchy, mode: .RETR_TREE, method: .CHAIN_APPROX_SIMPLE)
    
    let thickness = min((CGFloat(min(rows, cols)) / 100.0 + 1).toInt(), 5)
    // CONVEX_PROFILE
    var hullList = ArrayList<MatOfPoint>()
    var allContours = ArrayList<Point2i>()
    for c in contours {
      let contour = MatOfPoint(array: c as! [Point2i])
      let hull = contourToConvexHull(contour)
      hullList.add(hull)
      // 过滤破损的小块
      if (Int(Imgproc.contourArea(contour: contour)) > MIN_VALIDATE_AREA && !contourIsOnEdge(contour, Int(cols), Int(rows))) {
        allContours.addAll(contour.toArray())
      }
    }
    
    if (contours.isNotEmpty() && allContours.isNotEmpty()) {
      let centroidRadius = min(rows, cols) / 15 + 1
      let hullOutlineInt = IntVector([1])
      let totalContour = MatOfPoint()
      totalContour.fromArray(allContours)
      Imgproc.convexHull(points: totalContour.toArray(), hull: hullOutlineInt)
      var hullOutline: MutableList<MatOfPoint> = ArrayList()
      hullOutline.add(contourToConvexHull(totalContour))
      
      if (type == CONVEX_BORDER) {
        let rightBottom = Point2i(x: 0, y: 0)
        let leftTop = Point2i(x: 2000000, y: 2000000)
        for outline in hullOutline {
          for p in outline.toArray() {
            if (p.x < leftTop.x) {
              leftTop.x = p.x
            }
            if (p.x > rightBottom.x) {
              rightBottom.x = p.x
            }
            if (p.y < leftTop.y) {
              leftTop.y = p.y
            }
            if (p.y > rightBottom.y) {
              rightBottom.y = p.y
            }
          }
        }
        let widthHeightRatio = (rightBottom.x - leftTop.x).double /  (rightBottom.y - leftTop.y).double
        let ratioString = String(format: "宽高比: %.1f".orCht("寬高比: %.1f"), widthHeightRatio)
        Imgproc.rectangle(img: eventually, pt1: leftTop, pt2: rightBottom, color: COLOR_RED, thickness: Int32(thickness))
        
        let bitmap = matToBitmap(eventually)
        return ImageProcessor.drawWHRatio(bitmap, ratio: ratioString, leftTop: leftTop, rightBottom: rightBottom)
      }
      
      // 整个字形边框
      Imgproc.drawContours(image: eventually, contours: hullOutline.map({ $0.toArray() }), contourIdx: 0, color: COLOR_RED, thickness: thickness.int32)
      let layer = Mat()
      eventually.copy(to: layer)
      let alpha = 0.6
      
      // 获取重心centroid
      let moments = Imgproc.moments(array: hullOutline[0])
      let cx = (moments.m10 / moments.m00).toInt()
      let cy = (moments.m01 / moments.m00).toInt()
      drawEllipse(layer, Point2i(x: cx.int32, y: cy.int32), COLOR_BLUE, Int(centroidRadius))
      drawEllipse(layer, Point(x: cx.int32, y: cy.int32), COLOR_YELLOW, max(thickness-2, 1))
      
      Core.addWeighted(src1: layer, alpha: alpha, src2: eventually, beta: 1 - alpha, gamma: 0.0, dst: eventually)
      
    }
    return eventually.toUIImage()
  }
  
  static func sharpenImage(_ bmp: Bitmap, _ weight: Int) -> Bitmap {
    let src = bitmapToMat(bmp)
    let dst = Mat.zeros(src.rows(), cols: src.cols(), type: src.type())
    
    let mask = Mat(rows: 3, cols: 3, type: CvType.CV_16SC1)
    
    let _ = try? mask.put(row: 0, col: 0, data: [0.0, (-weight).toDouble(), 0.0,
                                                 (-weight).toDouble(), (1 + 4 * weight).toDouble(), (-weight).toDouble(), 0.0, (-weight).toDouble(), 0.0])
    
    Imgproc.filter2D(src: src, dst: dst, ddepth: -1, kernel: mask)
    return matToBitmap(dst)
  }
  // Canny
  private static let MAX_LOW_THRESHOLD = 200
  private static let MIN_LOW_THRESHOLD = 0
  private static let RATIO = 3
  private static let KERNEL_SIZE = 3
  
  public static func clamp(_ v: Int, _ min: Int, _ max: Int) -> Int {
    var value = v
    value = Swift.max(min, value)
    value = Swift.min(max, value)
    return value
  }
  
  static func cannyImage(_ bmp: Bitmap, _ threshold: Int) -> Bitmap {
    let src = bitmapToMat(bmp)
    var lowThresh = threshold
    let dst = Mat(size: src.size(), type: CvType.CV_8UC4, scalar: Scalar.all(0.0))
    let detectedEdges = Mat()
    lowThresh = clamp(lowThresh, MIN_LOW_THRESHOLD, MAX_LOW_THRESHOLD)
    
    Imgproc.Canny(image: src, edges: detectedEdges, threshold1: lowThresh.toDouble(), threshold2: lowThresh.toDouble() * RATIO.toDouble(), apertureSize: Int32(KERNEL_SIZE), L2gradient: false)
    src.copy(to: dst, mask: detectedEdges)
    return matToBitmap(dst)
  }
  
  static func invertBitmap(_ bitmap: Bitmap) -> Bitmap {
    let src = bitmapToMat(bitmap)
    let dst = Mat()
    debugPrint("invertBitmap \(src.channels())")
    if src.channels() >= 3 {
      Imgproc.cvtColor(src: src, dst: src, code: .COLOR_BGR2GRAY)
      Core.bitwise_not(src: src, dst: dst)
      return dst.toUIImage()
    } else {
      return src.toUIImage()
    }
  }
  
  /**
   * code: 0: vertical, 1: Horizontal
   */
  static func flipImage(_ bmp: Bitmap, _ code: Int) -> Bitmap {
    let src = bitmapToMat(bmp)
    let dst = Mat.zeros(src.rows(), cols: src.cols(), type: src.type())

    Core.flip(src: src, dst: dst, flipCode: code.int32)
    return matToBitmap(dst)
  }

}

extension Array where Element == NSNumber {
  var fourValues: (NSNumber, NSNumber, NSNumber, NSNumber) {
    (self[0], self[1], self[2], self[3])
  }
  var fourDoubles: (Double, Double, Double, Double) {
    (self[0].doubleValue, self[1].doubleValue, self[2].doubleValue, self[3].doubleValue)
  }
  var threeValues: (NSNumber, NSNumber, NSNumber) {
    (self[0], self[1], self[2])
  }
}

extension NSMutableArray {
  func isNotEmpty() -> Bool {
    count > 0
  }
}

extension Double {
  var int: Int {
    Int(self)
  }
  var int32: Int32 {
    int.int32
  }
}

extension Int32 {
  var int: Int {
    Int(self)
  }
  
  var double: Double {
    Double(self.int)
  }
  
  var cgFloat: CGFloat {
    CGFloat(self)
  }
}

extension Int {
  var int32: Int32 {
    Int32(self)
  }
}
 
public struct Stack<T> {
  fileprivate var array = [T]()
  public var isEmpty: Bool {
    return array.isEmpty
  }
  public var isNotEmpty: Bool {
    !isEmpty
  }
  public var count: Int {
    return array.count
  }
  public mutating func push(_ element: T) {
    array.append(element)
  }
  @discardableResult
  public mutating func pop() -> T? {
    return array.popLast()
  }
  public var top: T? {
    return array.last
  }
  
  mutating func clear() {
    array.clear()
  }
}

class AnalyzeViewModel: AlertViewModel {
  enum MenuOp: CaseIterable {
    case OpenImage, Reset, Save;
    
    var chinese: String {
      switch self {
      case .OpenImage:
        "打开图片".orCht("打開圖片")
      case .Reset:
        "reset".resString
      case .Save:
        "save_image".resString
      }
    }
    
    var icon: DropDownIcon {
      switch self {
      case .OpenImage:
        DropDownIcon(name: "photo.fill", isSystem: true, size: 20, totalSize: 24)
      case .Reset:
        DropDownIcon(name: "arrow.clockwise", isSystem: true, size: 20, totalSize: 24)
      case .Save:
        DropDownIcon(name: "square.and.arrow.down", isSystem: true, size: 20, totalSize: 24)
      }
    }
  }
  
  @Published var history = Stack<UIImage>()
  @Published var originalImage: UIImage? = nil
  @Published var showImage: UIImage? = nil
  @Published var tabIndex = 0
  @Published var filterImages = [ImageFilter: UIImage]()
  @Published var analyzeImages = [ImageAnalyze: UIImage]()
  @Published var selectedFilter: ImageFilter = .Original
  @Published var selectedAnalyze: ImageAnalyze = .OriginalPlus
  @Published var paramValue: CGFloat = 0
  @Published var rangeValue: FilterRange? = nil
  lazy var param: DropDownParam<MenuOp> = {
    let cases: [MenuOp] = [.Reset, .Save]
    return DropDownParam(items: cases, texts: cases.map({ $0.chinese }), images: cases.map({ $0.icon }))
  }()
  
  private var imageView: UIImageView? = nil
  init(_ single: BeitieSingle) {
    super.init()
    let image = UIImageView(frame: .zero)
    self.imageView = image
    image.sd_setImage(with: single.url.url!) { img, _, _, _ in
      DispatchQueue.main.async {
        self.imageView = nil
        if let img {
          self.initFirstImage(img)
        }
      }
    }
  }
  init(_ img: UIImage) {
    super.init()
    self.initFirstImage(img)
  }
  
  var currentImage: UIImage? {
    history.isEmpty ? originalImage : history.top
  }
  
  var currentFilter: FilterProperty {
    tabIndex == 0 ? selectedAnalyze : selectedFilter
  }
  
  func onUndo() {
    history.pop()
    loadResultImages()
  }
  
  func onMenuItem(_ op: MenuOp) {
    switch op {
    case .OpenImage:
      do {
        
      }
    case .Reset:
      do {
        history.clear()
        selectedFilter = .Original
        selectedAnalyze = .OriginalPlus
        loadResultImages()
      }
    case .Save:
      if let currentImage {
        imageSaver.writeToPhotoAlbum(image: currentImage)
      }
    }
  }
  
  private func loadAnalyzeImages(_ baseImage: UIImage) {
    Task {
      var analyze = [ImageAnalyze: UIImage]()
      ImageAnalyze.allCases.forEach { type in
        let image = type.doAnalysis(org: baseImage)
        if type.reachMax {
          analyze[type] = OpenCvImage.mosaicImage(image)
        } else {
          analyze[type] = image
        }
      }
      DispatchQueue.main.async {
        self.analyzeImages = analyze
      }
    }
  }
  
  private func loadFilterImages(_ baseImage: UIImage) {
    Task {
      var analyze = [ImageFilter: UIImage]()
      ImageFilter.allCases.forEach { type in
        let image = type.addFilter(org: baseImage,
                                   param: type.hasParam() ? paramValue.toInt() : nil)
        if type.reachMax {
          analyze[type] = OpenCvImage.mosaicImage(image)
        } else {
          analyze[type] = image
        }
      }
      DispatchQueue.main.async {
        self.filterImages = analyze
      }
    }
  }
  
  func initFirstImage(_ image: UIImage) {
    self.originalImage = image
    self.showImage = image
    loadAnalyzeImages(image)
    loadFilterImages(image)
  }
  
  func applyImage(_ newImage: UIImage) {
    history.push(newImage)
    loadResultImages()
  }
  
  func updateShowImage(_ newShow: UIImage) {
    showImage = newShow
    let reachMax: Bool
    if tabIndex == 0 {
      rangeValue = nil
      if selectedAnalyze.isVipProperty() {
        ConstraintItem.CentroidAnalyze.increaseUsage()
      }
      reachMax = selectedAnalyze.reachMax
    } else {
      paramValue = selectedFilter.range?.def.toCGFloat() ?? 0
      rangeValue = selectedFilter.range
      if selectedFilter.isVipProperty() {
        ConstraintItem.CentroidAnalyze.increaseUsage()
      }
      reachMax = selectedFilter.reachMax
    }
    if reachMax {
      if let origin = originalImage {
        loadAnalyzeImages(origin)
      }
      if let current = currentImage {
        loadFilterImages(current)
      }
    }
  }
  
  func updateParam(_ param: CGFloat) {
    guard let currentImage else { return }
    let p = param.toInt()
    Task {
      let image = selectedFilter.addFilter(org: currentImage, param: p)
      DispatchQueue.main.async {
        self.showImage = image
      }
    }
  }
  
  func loadResultImages() {
    showImage = currentImage
    guard let base = currentImage else { return }
    loadFilterImages(base)
  }
  
  func syncImage() {
    if tabIndex == 0 {
      showImage = analyzeImages[selectedAnalyze] ?? currentImage
    } else {
      showImage = filterImages[selectedFilter] ?? currentImage
    }
  }
}

struct CustomRoundedCorners: Shape {
  //Provide variables to control the radius and which corners to round.
  var radius: CGFloat
  var corners: UIRectCorner
  
  //Implement the path(in:) method required for the Shape protocol.
  func path(in rect: CGRect) -> Path {
    //Create a UIBezierPath to represent the custom rounded rectangle path.
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    
    //Convert the UIBezierPath to a SwiftUI Path and return it.
    return Path(path.cgPath)
  }
}


struct AnalyzeView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel: AnalyzeViewModel
  
  var tabIndex: Int {
    viewModel.tabIndex
  }
  
  var naviBar: some View {
    NaviView {
      BackButtonView {
        presentationMode.wrappedValue.dismiss()
      }
      Spacer()
      NaviTitle(text: "单字分析".orCht("單字分析"))
      Spacer()
      let canUndo = viewModel.history.isNotEmpty
      Button {
        viewModel.onUndo()
      } label: {
        Image(systemName: "arrow.backward").square(size: CUSTOM_NAVI_ICON_SIZE-2)
          .foregroundStyle(canUndo ? .colorPrimary : .gray.opacity(0.75))
      }.buttonStyle(.plain).disabled(!canUndo)
      
      Button {
        showMenu = true
      } label: {
        Image(systemName: "ellipsis.circle").square(size: CUSTOM_NAVI_ICON_SIZE-2)
          .foregroundStyle(.colorPrimary)
      }.padding(.leading, 5).buttonStyle(.plain)
    }
  }
  private let viewPadding: CGFloat = 15
  var filterView: some View {
    LazyHStack(spacing: 0) {
      5.HSpacer()
      let values = viewModel.filterImages
      ForEach(ImageFilter.allCases, id: \.self) { type in
        let selected = type == viewModel.selectedFilter
        if let image = values[type] {
          Button {
            if type.isVipProperty() && type.reachMax {
              viewModel.showConstraintVip(ConstraintItem.CentroidAnalyze.topMostConstraintMessage)
            } else {
              viewModel.selectedFilter = type
              viewModel.updateShowImage(image)
            }
          } label: {
            let color: Color = selected ? .blue : .white.opacity(0.75)
            HStack(alignment: .top, spacing: 0) {
              HStack(spacing: 0) {
                Image(uiImage: image).resizable().scaledToFit()
                  .contentShape(RoundedRectangle(cornerRadius: 3))
                  .clipped()
              }.padding(4).background(color)
                .clipShape(CustomRoundedCorners(radius: 3, corners: [.topLeft, .bottomLeft, .bottomRight]))
              Text(type.chinese.verticalChars)
                .lineSpacing(0)
                .padding(.leading, 2)
                .padding(.trailing, 2)
                .padding(.vertical, 2)
                .font(.system(size: 11))
                .foregroundStyle(selected ? .white : .searchHeader)
                .background(color)
                .clipShape(CustomRoundedCorners(radius: 3, corners: [.topRight, .bottomRight]))
            }
          }.padding(.horizontal, 6).buttonStyle(.plain)
        }
      }
      5.HSpacer()
    }
  }
  
  var analyzeView: some View {
    LazyHStack(spacing: 0) {
      5.HSpacer()
      let values = viewModel.analyzeImages
      ForEach(ImageAnalyze.allCases, id: \.self) { type in
        let selected = type == viewModel.selectedAnalyze
        if let image = values[type] {
          Button {
            if type.isVipProperty() && type.reachMax {
              viewModel.showConstraintVip(ConstraintItem.CentroidAnalyze.topMostConstraintMessage)
            } else {
              viewModel.selectedAnalyze = type
              viewModel.updateShowImage(image)
            }
          } label: {
            let color: Color = selected ? .red : .white.opacity(0.85)
            HStack(alignment: .top, spacing: 0) {
              HStack(spacing :0) {
                Image(uiImage: image).resizable().scaledToFit()
                  .contentShape(RoundedRectangle(cornerRadius: 3))
                  .clipped()
                
              }.padding(4).background(color)
                .clipShape(CustomRoundedCorners(radius: 3, corners: [.topLeft, .bottomLeft, .bottomRight]))
              Text(type.chinese.verticalChars)
                .lineSpacing(0)
                .padding(.leading, 2)
                .padding(.trailing, 2)
                .padding(.vertical, 2)
                .font(.system(size: 11))
                .foregroundStyle(selected ? .white : .searchHeader)
                .background(color)
                .clipShape(CustomRoundedCorners(radius: 3, corners: [.topRight, .bottomRight]))
            }
          }.padding(.horizontal, 5).buttonStyle(.plain)
        }
      }
      5.HSpacer()
    }
  }
  
  var content: some View {
    ZStack {
      Color.black
      if let image = viewModel.showImage {
        ImageZoomableView(image: image)
          .padding(20)
      }
    }
  }
  var bottomView: some View {
    VStack(spacing: 0) {
      Divider()
      HStack {
        if let range = viewModel.rangeValue {
          Slider(value: $viewModel.paramValue, in:
                  range.min.toCGFloat()...range.max.toCGFloat())
          .onChange(of: viewModel.paramValue) { newValue in
            viewModel.updateParam(newValue)
          }
        } else {
          Spacer()
        }
        Button {
          if let showImage = viewModel.showImage {
            viewModel.applyImage(showImage)
          }
        } label: {
          Image(systemName: "checkmark").square(size: 18)
            .fontWeight(.regular)
            .foregroundStyle(.colorPrimary)
        }.padding(.leading, 10).buttonStyle(.plain)
      }.padding(.horizontal, 15).frame(minHeight: 40)
      Divider()
      VStack {
        if tabIndex == 0 {
          ScrollView([.horizontal]) {
            analyzeView.padding(.vertical, viewPadding)
          }
        } else {
          ScrollView([.horizontal]) {
            filterView.padding(.vertical, viewPadding)
          }
        }
      }.frame(height: 110).background(.singlePreviewBackground)
      HStack {
        Button {
          viewModel.tabIndex = 0
        } label: {
          let selected = tabIndex == 0
          HStack(spacing: 4) {
            Spacer()
            let color: Color = selected ? .blue : .gray
            Image("analyze").renderingMode(.template).square(size: 20)
              .foregroundStyle(color)
            Text("分析").font(selected ? .title3 : .body).foregroundStyle(color).bold()
            Spacer()
          }.background(.white)
        }.buttonStyle(.plain)
        Button {
          viewModel.tabIndex = 1
        } label: {
          let selected = tabIndex == 1
          HStack(spacing: 4) {
            Spacer()
            let color: Color = selected ? .blue : .gray
            Image("filter").renderingMode(.template).square(size: 20)
              .foregroundStyle(color)
            Text("滤镜".orCht("濾鏡")).font(selected ? .title3 : .body).foregroundStyle(color).bold()
            Spacer()
          }.background(.white)
        }.buttonStyle(.plain)
      }.padding(.vertical, 10)
        .onChange(of: tabIndex) { newValue in
          viewModel.syncImage()
        }
    }
  }
  
  @State private var showMenu = false
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ZStack(alignment: .topTrailing) {
          VStack(spacing: 0) {
            naviBar
            Divider()
            content
            bottomView
          }
          if showMenu {
            DropDownOptionsView(param: viewModel.param) { op in
              viewModel.onMenuItem(op)
            }.offset(x: -10, y: (CUSTOM_NAVIGATION_HEIGHT + CUSTOM_NAVI_ICON_SIZE) / 2 + 5)
          }
        }
      }.navigationBarHidden(true)
        .modifier(TapDismissModifier(show: $showMenu))
        .modifier(DragDismissModifier(show: $showMenu))
        .modifier(AlertViewModifier(viewModel: viewModel))
    }.navigationDestination(isPresented: $viewModel.gotoVip) {
      VipPackagesView()
    }
  }
}

#Preview("analyze") {
  AnalyzeView(viewModel: AnalyzeViewModel(UIImage(named: "sample")!))
}


extension String {
  var verticalChars: String {
    var sb = StringBuilder()
    for c in self {
      sb.append(c)
      sb.append("\n")
    }
    return sb.dropLast().toString()
  }
}
