//
//  WritingPanel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/7.
//

import SwiftUI
import DeviceKit

typealias DrawPoint = CGPoint


class DrawViewModel: BaseObservableObject {
  var onCloseDraw: () -> Void = {}
  @Published var drawIndex = DrawViewModel.drawWidthIndex {
    didSet {
      DrawViewModel.drawWidthIndex = drawIndex
    }
  }
  @Published var colorIndex = DrawViewModel.colorIndex {
    didSet {
      DrawViewModel.colorIndex = colorIndex
    }
  }
  @Published var lines = Array<List<DrawPoint>>()
  @Published var current = Array<DrawPoint>()
  var canUndo: Bool {
    lines.isNotEmpty()
  }
  
  func onClose() {
    onCloseDraw()
    onReset()
  }
  
  func onUndo() {
    current.clear()
    if (lines.isNotEmpty()) {
      lines.remove(at: lines.lastIndex)
    }
  }
  
  func onReset() {
    lines.clear()
    current.clear()
  }
}

extension DrawViewModel {
  private static let COLOR_KEY = "drawColor"
  private static let WIDTH_KEY = "drawWidth"
  static let DRAW_WIDTHS: [CGFloat] = [3, 6, 9]
  static let DRAW_COLORS: [Color] = Array.listOf(Colors.orange_red.swiftColor, Color.blue, Color.yellow, Color.green)
  static let DRAW_BG_COLORS = Array.listOf(Color.white, Color.white, Color.black, Color.black)
  static var colorIndex: Int {
    get { Settings.getInt(COLOR_KEY, 0) }
    set(value) {
      Settings.putInt(COLOR_KEY, value)
    }
  }
  static var drawWidthIndex: Int {
    get { Settings.getInt(WIDTH_KEY, 0) }
    set(value) {
      Settings.putInt(WIDTH_KEY, value)
    }
  }
}

struct DrawPanel : View {
  @EnvironmentObject var viewModel: DrawViewModel
  let rows = (0..<DrawViewModel.DRAW_COLORS.size).map { _ in
    GridItem(.flexible())
  }
  @State private var counter = 0
  
  var current: [DrawPoint] {
    viewModel.current
  }
  
  var divider: some View {
    Divider.overlayColor(.white.opacity(0.5)).frame(width: 1, height: 15)
  }
  
  var color: Color {
    DrawViewModel.DRAW_COLORS[viewModel.colorIndex]
  }
  var lineWidth: CGFloat {
    DrawViewModel.DRAW_WIDTHS[viewModel.drawIndex % DrawViewModel.DRAW_WIDTHS.size]
  }
  var body: some View {
    VStack {
      ZStack(alignment: .topLeading) {
        ScrollView {
          
        }.background(.black.opacity(0.05))
        if viewModel.lines.isNotEmpty() || current.isNotEmpty() {
          Canvas { ctx, size in
            for line in viewModel.lines {
              var path = Path()
              path.addLines(line)
              ctx.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
            if current.isNotEmpty() {
              var path = Path()
              path.addLines(current)
              ctx.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
          }
        }
      }.gesture(DragGesture().onChanged({ value in
        let point = value.location
        debugPrint("loc: \(point)")
        viewModel.current.add(point)
      }).onEnded({ _ in
        if viewModel.current.isNotEmpty() {
          viewModel.lines.add(viewModel.current)
          viewModel.current.clear()
        }
      }))
      HStack(spacing: 12) {
        Spacer()
        Button {
          viewModel.onReset()
        } label: {
          Image(systemName: "trash").foregroundStyle(.white)
        }.buttonStyle(.plain)
        Button {
          viewModel.onUndo()
        } label: {
          Image(systemName: "arrow.uturn.left").foregroundStyle(
            viewModel.canUndo ? .white : .gray)
        }.disabled(!viewModel.canUndo).buttonStyle(.plain)
        divider
        if Device.current.isPad {
          15.HSpacer()
        }
        HStack(spacing: 10){
          let size = DrawViewModel.DRAW_WIDTHS.size
          ForEach(0..<size, id: \.self) { i in
            let size = CGFloat(10 + (i * 3))
            Button {
              viewModel.drawIndex = i
            } label: {
              ZStack(alignment: .center) {
                if viewModel.drawIndex == i {
                  Color.red.frame(width: size+5, height: size+5)
                    .clipShape(Circle())
                }
                Color.white.opacity(viewModel.drawIndex == i ? 0.8 : 1).frame(width: size, height: size)
                  .clipShape(Circle())
              }.squareFrame(18)
            }.buttonStyle(.plain)
          }
        }
        divider
        HStack(spacing: 10){
          let size = DrawViewModel.DRAW_COLORS.size
          ForEach(0..<size, id: \.self) { i in
            Button {
              viewModel.colorIndex = i
            } label: {
              HStack {
                if i == viewModel.colorIndex {
                  Image(systemName: "checkmark")
                    .square(size: 10)
                    .bold()
                    .foregroundStyle(DrawViewModel.DRAW_BG_COLORS[i])
                }
              }.squareFrame(20).background(Circle().fill(DrawViewModel.DRAW_COLORS[i]))
            }.buttonStyle(.plain)
          }
        }
        if (Device.current.isPad) {
          15.HSpacer()
        }
        divider
        
        Button {
          viewModel.onClose()
        } label: {
          Image(systemName: "xmark.circle").square(size: 18).foregroundStyle(.white)
        }.buttonStyle(.plain)
        if !Device.current.isPad {
          Spacer()
        }
      }.padding(.horizontal, 10).frame(height: 44).background(Color.colorPrimary).frame(maxWidth: .infinity)
    }
  }
}

#Preview {
  DrawPanel().environmentObject(DrawViewModel())
}
