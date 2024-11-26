//
//  OpenCVTestView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/25.
//

import SwiftUI
import opencv2
import Foundation

typealias Point = Point2i
typealias Bitmap = UIImage
typealias MutableList = Array
//typealias MatOfPoint = [Point2i]

class ImageProcessor {
  
  static func drawWHRatio(_ bitmap: Bitmap, ratio: String, leftTop: Point, rightBottom: Point, thickness: CGFloat) -> Bitmap {
    let size = bitmap.size
    UIGraphicsBeginImageContextWithOptions(size, true, 0)
    let bgColor = UIColor.gray
    let context = UIGraphicsGetCurrentContext()!
      //图形重绘
    bitmap.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
      //水印文字属性
    let att = [NSAttributedString.Key.foregroundColor: UIColor.yellow, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20), NSAttributedString.Key.backgroundColor: UIColor.clear]
    
//    context.setStrokeColor(UIColor.red.cgColor)
//    context.stroke(CGRect(x: leftTop.x.int.toCGFloat(), y: leftTop.y.int.toCGFloat(), width: (rightBottom.x - leftTop.x).int.toCGFloat(), height: (rightBottom.y - leftTop.y).int.toCGFloat()), width: thickness)
    
      //水印文字大小
    let text = NSString(string: ratio)
    let s = text.size(withAttributes: att)
    let extraWidth: CGFloat = 20
    let extraHeight: CGFloat = 6
      //绘制文字
    
    let rect = CGRect.init(x: size.width/2-s.width/2-extraWidth/2, y: rightBottom.y.int.toCGFloat() + extraHeight/2 + s.height/2, width: s.width+extraWidth, height: s.height+extraHeight)
    
    context.setFillColor(bgColor.cgColor)
    context.fill(rect)
      //从当前上下文获取图片
    text.draw(at: CGPoint(x: rect.minX + extraWidth/2, y: rect.minY + extraHeight/2), withAttributes: att)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
      //关闭上下文
    UIGraphicsEndImageContext()
    return image!
  }
}

class OpenCvImage {
  private static let VIP_TEXT = "VIP"
  
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
  
  static func mosaicImage(_ src: Mat, level: Int = 50) -> UIImage {
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
      let contour = c as! MatOfPoint
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
  
  
  static func getBitmapCentroidRadius(_ bmp: Bitmap, _ centroid: Point2d) -> Float {
    let hullOutline = getBitmapHullOutline(bmp)
    let rows = bmp.size.width
    let cols = bmp.size.height
    if (hullOutline != nil) {
      // 获取重心centroid
      let moments = Imgproc.moments(array: hullOutline![0])
      let cx = (moments.m10 / moments.m00)
      let cy = (moments.m01 / moments.m00)
      centroid.x = cx
      centroid.y = cy
      
      return Float(min(min(rows-cx, cx), min(cols-cy, cy)));
    }
    return Float(-1)
  }
  
  
  static func convexHullBitmap(_ bmp: Bitmap, draw: Bitmap, type: Int) -> Bitmap? {
    let src = bitmapToMat(bmp)
    let eventually = bitmapToMat(draw)
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
                              dst: src, d: Int32(radius), sigmaColor: Double(radius) * 2.toDouble(), sigmaSpace: Double(radius) / 2.0)
      Imgproc.cvtColor(src: src, dst: srcGray, code: .COLOR_BGR2GRAY)
      Imgproc.threshold(src: srcGray, dst: cannyOutput, thresh: 127.0, maxval: MAX_BINARY_VALUE.toDouble(), type: .THRESH_BINARY)
    } else {
      Imgproc.cvtColor(src: src, dst: cannyOutput, code: .COLOR_BGR2GRAY) // 变更为CV_8UC1
    }
    
    Imgproc.findContours(image: cannyOutput, contours: contours, hierarchy: hierarchy, mode: .RETR_TREE, method: .CHAIN_APPROX_SIMPLE)
    
    println("type: \(src.type()), depth: \(src.depth()), \(src.channels())")
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
        return ImageProcessor.drawWHRatio(bitmap, ratio: ratioString, leftTop: leftTop, rightBottom: rightBottom, thickness: thickness.int32.int.toCGFloat())
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
  
  static func sharpenImage(_ src: Mat, _ weight: Int) -> Bitmap? {
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

  static func cannyImage(_ src: Mat, _ threshold: Int) -> Bitmap? {
    var lowThresh = threshold
    let dst = Mat(size: src.size(), type: CvType.CV_8UC4, scalar: Scalar.all(0.0))
    let detectedEdges = Mat()
    lowThresh = clamp(lowThresh, MIN_LOW_THRESHOLD, MAX_LOW_THRESHOLD)
    
    Imgproc.Canny(image: src, edges: detectedEdges, threshold1: lowThresh.toDouble(), threshold2: lowThresh.toDouble() * RATIO.toDouble(), apertureSize: Int32(KERNEL_SIZE), L2gradient: false)
    src.copy(to: dst, mask: detectedEdges)
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

struct OpenCVTestView: View {
  @State var image: UIImage? = nil
  let src = Mat(uiImage: UIImage(named: "sample")!)
  
  
  var body: some View {
    VStack {
      VStack {
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
        } else {
          Spacer()
        }
      }
      HStack(spacing: 20) {
        Button {
          image = src.toUIImage()
        } label: {
          Text("origin")
        }
        Button {
//          let dst = Mat()
//          Imgproc.cvtColor(src: src, dst: dst, code: .COLOR_BGR2GRAY)
//          image = dst.toUIImage()
          let img = src.toUIImage()
          image = OpenCvImage.convexHullBitmap(src.toUIImage(), draw: img, type: OpenCvImage.CONVEX_PROFILE)
        } label: {
          Text("2gray")
        }
        Button {
//          let dst = Mat()
//          Imgproc.cvtColor(src: src, dst: dst, code: .COLOR_BGR2GRAY)
//          image = dst.toUIImage()
          let img = src.toUIImage()
          image = OpenCvImage.convexHullBitmap(src.toUIImage(), draw: img, type: OpenCvImage.CONVEX_BORDER)
        } label: {
          Text("border")
        }
        Button {
          image = OpenCvImage.mosaicImage(src)
        } label: {
          Text("addTExt")
        }
      }
    }.onAppear {
      image = src.toUIImage()
    }
  }
}


#Preview {
  OpenCVTestView()
}
