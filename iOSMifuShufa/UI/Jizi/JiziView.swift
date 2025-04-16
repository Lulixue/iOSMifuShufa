//
//  JiziView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/12.
//
import SwiftUI
import Collections
import SDWebImageSwiftUI
import DeviceKit

struct TapDismissModifier: ViewModifier {
  @Binding var show: Bool
  func body(content: Content) -> some View {
    content.simultaneousGesture(TapGesture().onEnded({ _ in
      show = false
    }), isEnabled: show)
  }
}

struct DragDismissModifier: ViewModifier {
  @Binding var show: Bool
  func body(content: Content) -> some View {
    content.simultaneousGesture(DragGesture().onEnded({ _ in
      show = false
    }), isEnabled: show)
  }
}


struct JiziView : View {
  @StateObject var viewModel: JiziViewModel
  @StateObject var historyVM = HistoryViewModel.shared
  @StateObject var naviVM: NavigationViewModel = NavigationViewModel()
  @Environment(\.presentationMode) var presentationMode
  var items: List<JiziItem> {
    viewModel.jiziItems
  }
  
  var currentItem: JiziItem {
    viewModel.jiziItems[viewModel.selectedIndex]
  }
  var singleCharCandidates: OrderedDictionary<AnyHashable, List<BeitieSingle>>? {
    if items.isNotEmpty() {
      return currentItem.candidates?.isNotEmpty() == true ? currentItem.candidates : nil
    } else {
      return nil
    }
  }
  
  var candidatePanel: some View {
    ScrollView {
      autoColumnLazyGrid(items, space: 6, parentWidth: UIScreen.currentWidth, maxItemWidth: 70, rowSpace: 2, paddingValues: PaddingValue(horizontal: 10, vertical: 10)) { size, i, item in
        let selected = i == viewModel.selectedIndex
        let single = item.selected
        Button {
          if (viewModel.selectedIndex != i) {
            workIndex = 0
            singleIndex = -1
            itemLoc.clear()
            viewModel.selectChar(i) {
              autoScroll = true
              lastScrollDestination = viewModel.singleIndex
            }
          }
        } label: {
          VStack(spacing: 0) {
            ZStack {
              WebImage(url: item.charUrl!) { img in
                img.image?.resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(height: size-16)
                  .contentShape(RoundedRectangle(cornerRadius: 2))
                  .clipped()
                  .onAppear(perform: {
                    viewModel.loaded(index: i)
                  })
              }
              .onSuccess(perform: { _, _, _ in
                viewModel.loaded(index: i)
              })
              .indicator(.activity).tint(Color.colorPrimary)
              .id(single?.id ?? i)
              if viewModel.jiziImageLoaded[i] != true {
                ProgressView().squareFrame(20)
                  .tint(.colorPrimary)
              }
            }.frame(height: size-16)
            Text(item.char.toString() + "(\(item.results.size))").font(.callout)
              .underline(item.jiziUseComponents).padding(.top, 5).padding(.bottom, 2)
              .foregroundStyle(single?.work.btType.nameColor(baseColor: defaultTextColor) ?? defaultTextColor)
            
          }.padding(.top, 5).padding(.bottom, 3).padding(.horizontal, itemPaddingHor).frame(width: size).frame(height: size+20)
            .background(selected ? .gray.opacity(0.4) : .white).clipShape(RoundedRectangle(cornerRadius: 4))
        }.buttonStyle(BgClickableButton())
      }
    }
  }
  
  private let workPadding: CGFloat = 5
  @State private var singleIndex = 0
  @State private var workIndex = 0
  @State private var singleProxy: ScrollViewProxy? = nil
  @State private var workProxy: ScrollViewProxy? = nil
  @State private var showFonts = false
  @State private var showWorks = false
  @State private var fontPosition = CGRect.zero
  @State private var worksPosition = CGRect.zero
  
  private let scrollSettings = ScrollableBarSettings(
    textColors: [.gray, .white],
    textFonts: [.system(size: 14), .system(size: 12)],
    indicatorHeight: 1.5,
    indicatorPadding: 0,
    indicatorTextSpacing: 0,
    backgroundColor: .blue)
  
  private let itemPaddingHor: CGFloat = 6
  private let defaultTextColor = Color.defaultText
  var buttonView: some View {
    HStack {
      Button {
        showWorks = true
        debugPrint("worksPosition \(worksPosition)")
      } label: {
        HStack(spacing: 4) {
          Image(JiziOptionType.Work.icon).renderingMode(.template).square(size: 14)
          if let selected = viewModel.selectedWork {
            Text(selected.workNameAttrStr(curves: false))
          } else {
            Text(JiziOptionType.Work.chinese)
          }
        }.foregroundStyle(showWorks ? .gray.opacity(0.7) : Colors.iconColor(1))
      }.buttonStyle(.plain).background(PositionReaderView(binding: $worksPosition))
      Button {
        showFonts = true
        debugPrint("fontPosition \(fontPosition)")
      } label: {
        HStack(spacing: 4) {
          Image(JiziOptionType.Font.icon).renderingMode(.template).square(size: 18)
          if let selected = viewModel.selectedFont {
            Text(selected.longChinese)
          } else {
            Text(JiziOptionType.Font.chinese)
          }
        }.foregroundStyle(showFonts ? .gray.opacity(0.7) : Colors.iconColor(1))
      }.buttonStyle(.plain).background(PositionReaderView(binding: $fontPosition))
      Spacer()
      Button {
        naviVM.gotoPuzzle(viewModel.jiziItems)
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "command").square(size: 11)
          Text("puzzle".localized).font(.system(size: 14))
        }
      }.buttonStyle(PrimaryButton(enabled: true, bgColor: .blue, horPadding: 8, verPadding: 6))
    }.padding(.vertical, 10).padding(.horizontal, 14)
  }
  
  var naviBar: some View {
    NaviView {
      BackButtonView {
        presentationMode.wrappedValue.dismiss()
      }
      Spacer()
      NaviTitle(text: "title_jizi".localized)
      Spacer()
      (CUSTOM_NAVI_ICON_SIZE-2).HSpacer()
    }.background(Colors.surfaceVariant.swiftColor)
  }
  
  @ViewBuilder func filterView(_ type: JiziOptionType, binding: Binding<JiziPreferType>) -> some View {
    HStack {
      Image(type.icon).renderingMode(.template).square(size: 18).foregroundStyle(.colorPrimary)
      Text(type.chinese).font(.callout).foregroundStyle(.colorPrimary)
      Spacer()
      Picker("", selection: binding) {
        ForEach(JiziPreferType.allCases, id: \.self) { t in
          Text(t.chinese).tag(t)
        }
      }.pickerStyle(.segmented)
        .fixedSize().foregroundStyle(.colorPrimary)
    }.padding(.horizontal, 15).padding(.vertical, 8)
  }
  
  func showPosition(_ pos: CGRect) -> CGSize {
    CGSize(width: pos.minX, height: pos.maxY - UIScreen.statusBarHeight + 3 - CUSTOM_NAVIGATION_HEIGHT)
  }
  
  var body: some View {
    NavigationStack {
      content
    }.modifier(VipViewModifier(viewModel: viewModel))
      .navigationDestination(isPresented: $naviVM.gotoPuzzleView) {
        PuzzleView(viewModel: naviVM.puzzleVM!)
      }
  }
  
  var jiziContents: some View {
    VStack(spacing: 0) {
      buttonView
      Divider().padding(.horizontal, 10)
      VStack(spacing: 0) {
        candidatePanel
        if let candidates = singleCharCandidates {
          5.VSpacer()
          singleCandidates(candidates)
            .id(viewModel.selectedIndex.toString() + viewModel.currentItem.char.toString())
        }
      }.modifier(DragDismissModifier(show: $showFonts)).modifier(DragDismissModifier(show: $showWorks))
    }
  }
  
  var content: some View {
    VStack(spacing: 0) {
      naviBar
      Divider()
      ZStack {
        ZStack(alignment: .topLeading) {
          if !viewModel.initializing {
            jiziContents
          } else {
            LoadingView(title: .constant("正在加载...".orCht("正在加載...")))
          }
          if showFonts {
            DropDownOptionsView(param: viewModel.fontParam) { font in
              viewModel.selectFont(font)
              showFonts = false
            }.offset(showPosition(fontPosition))
          }
          if showWorks {
            DropDownOptionsView(param: viewModel.workParam) { work in
              viewModel.selectWork(work)
              showWorks = false
            }.offset(showPosition(worksPosition))
          }
        }
      }
    }.navigationBarHidden(true)
      .onDisappear {
        viewModel.savePuzzleLog()
      }
      .modifier(TapDismissModifier(show: $showFonts))
      .modifier(TapDismissModifier(show: $showWorks))
  }
     
  @ViewBuilder
  func singleCandidate(_ i: Int, _ single: BeitieSingle) -> some View {
    let matchVip = single.matchVip
    let selected = i == viewModel.singleIndex
    Button {
      if matchVip {
        singleIndex = i
        viewModel.selectSingle(i, single)
      } else {
        viewModel.showConstraintVip("当前单字不支持集字，是否开通VIP继续？".orCht("當前單字不支持集字，是否開通VIP繼續？"))
      }
    } label: {
      WebImage(url: single.jiziUrl!) { img in
        img.image?.resizable()
          .aspectRatio(contentMode: .fit)
          .frame(minWidth: 40, minHeight: 40)
          .contentShape(RoundedRectangle(cornerRadius: 2))
          .clipped()
          .padding(0.5)
          .background {
            RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .white, lineWidth: selected ? 4 : 0.5)
          }.blur(radius: matchVip ? 0 : 1)
      }
      .onSuccess(perform: { _, _, _ in
        if shouldAutoScroll {
          scrollToIndex(lastScrollDestination)
        }
      })
      .indicator(.activity)
        .tint(.white)
        .frame(minWidth: 40, minHeight: 40)
        .onAppear {
          if shouldAutoScroll {
            scrollToIndex(lastScrollDestination)
          }
        }
    }.buttonStyle(.plain)
  }
  
  @State var itemLoc = [Int: CGFloat]()
  
  @ViewBuilder
  func singleCandidates(_ candidates: OrderedDictionary<AnyHashable, Array<BeitieSingle>>) -> some View {
    let keys = Array(candidates.keys)
    let singles = currentItem.results
    let separators = {
      var indices = [Int]()
      var counter = 0
      for (_, v) in candidates {
        counter += v.size
        indices.append(counter)
      }
      if (indices.isNotEmpty()) {
        indices.remove(at: indices.lastIndex)
      }
      return indices
    }()
    
    VStack(spacing: 0) {
      ScrollView(.horizontal, showsIndicators: false) {
        ScrollViewReader { proxy in
          ScrollableTabView(activeIdx: $workIndex, dataSet: keys, settings: scrollSettings, onClickTab: { value in
            viewModel.selectWork(value)
          }) { i, item in
            let selected = workIndex == i
            let color: Color = selected ? .white : .white.opacity(0.6)
            if let title = item as? String {
              Text(title).font(scrollSettings.normalFont)
                .foregroundStyle(color).padding(.vertical, workPadding)
            } else if let work = item as? BeitieWork {
              Text(work.workNameAttrStr(scrollSettings.normalFont, smallerFont: .system(size: 8), curves: false))
                .foregroundStyle(color).padding(.vertical, workPadding)
            }
          }.onAppear {
            workProxy = proxy
          }
        }
      }.background(.blue)
        .onChange(of: viewModel.workIndex) { newValue in
          if workIndex != newValue {
            workIndex = viewModel.workIndex
            workProxy?.scrollTo(newValue, anchor: .leading)
          }
        }
       
      ScrollView([.horizontal], showsIndicators: true) {
        ScrollViewReader { proxy in
          LazyHStack(spacing: 0) {
            ForEach(0..<singles.size, id: \.self) { i in
              let single = singles[i]
              HStack {
                singleCandidate(i, single)
              }.id(i).padding(.horizontal, 5)
                .background(
                  GeometryReader { reader in
                    Color.clear
                      .preference(
                        key: WidthPreferenceKey.self,
                        value: reader.frame(in: .named("frameLayer")).width
                      )
                  }.onPreferenceChange(WidthPreferenceKey.self) { h in
                    itemLoc[i] = max(h, itemLoc[i] ?? 0)
                    debugPrint("[\(i)] \(h)")
                  }
                )
              if separators.containsItem(i+1) {
                Divider().frame(width: 1, height: 15)
                  .clipShape(RoundedRectangle(cornerRadius: 3))
                  .background(.gray)
                  .padding(.horizontal, 1)
              }
            }
          }.background(Color.singlePreviewBackground)
            .onAppear {
              singleProxy = proxy
            }
        }.padding(.top, 9).padding(.bottom, Device.hasTopNotch ? 0 : 9).padding(.horizontal, 5)
      }
      .coordinateSpace(name: "frameLayer")
      .scrollViewStyle(.defaultStyle($candidateScrollState))
      .onChange(of: viewModel.singleIndex) { newValue in
        if singleIndex != newValue {
          self.singleIndex = newValue
          autoScroll = true
          scrollToIndex(newValue)
        }
      }
      .onChange(of: viewModel.singleStartIndex) { newValue in
        autoScroll = true
        scrollToIndex(newValue)
      }.background(Color.singlePreviewBackground)
        .frame(height: 80)
        .modifier(AlertViewModifier(viewModel: viewModel))
        .onChange(of: candidateScrollState.isDragging) { newValue in
          if newValue {
            autoScroll = false
          }
        }
        .onChange(of: candidateScrollState.offset) { newValue in
          debugPrint("offset x \(newValue.x)")
          if (!autoScroll) {
            let loc = itemLoc.sorted { $0.key < $1.key }
            var last = -1
            var offset: CGFloat = 0
            for (k, v) in loc {
              if (k - last != 1) {
                break
              }
              last = k
              offset += v
              if abs(offset - newValue.x) < 20 {
                viewModel.workIndex = currentItem.getWorkIndex(k)
                debugPrint("workIndex \(viewModel.workIndex)")
                break
              }
            }
          }
        }
    }
  }
  
  @State private var visible: [Int] = []
  

  var shouldAutoScroll: Bool {
    autoScroll && (lastScrollDestination == viewModel.singleStartIndex || lastScrollDestination == viewModel.singleIndex)
  }
  
  @State private var autoScroll = false
  @ScrollState private var candidateScrollState
  
  @State private var lastScrollDestination = -1
  private func scrollToIndex(_ index: Int) {
    DispatchQueue.main.async {
      debugPrint("scrollToSingleIndex \(index)")
      self.lastScrollDestination = index
      singleProxy?.scrollTo(index, anchor: .leading)
    }
  }
}


#Preview {
  JiziView(viewModel: {
    let text = "可你分明在世上，更在我心尖"
    let vm = JiziViewModel(text: text)
    return vm
  }())
}

extension Device {
  static var hasTopNotch: Bool {
    if #available(iOS 11.0, tvOS 11.0, *) {
      return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
    }
    return false
  }
}

extension Data {
  var utf8String: String {
    String(decoding: self, as: UTF8.self)
  }
}
