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



struct JiziView : View {
  @StateObject var viewModel: JiziViewModel
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
      LazyVStack {
        autoColumnGrid(items, space: 10, parentWidth: UIScreen.currentWidth, maxItemWidth: 70, rowSpace: 4, paddingValues: PaddingValue(vertical: 10)) { size, i, item in
          let selected = i == viewModel.selectedIndex
          let single = item.selected
          Button {
            workIndex = 0
            singleIndex = 0
            viewModel.selectChar(i)
          } label: {
            VStack(spacing: 0) {
              if let single {
                WebImage(url: single.url.url!) { img in
                  img.image?.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: size-16)
                }
                .indicator(.activity).tint(Color.colorPrimary).clipShape(RoundedRectangle(cornerRadius: 2))
                .frame(height: size-16)
              } else {
                Text(item.char.toString()).font(.largeTitle).frame(width: size-itemPaddingHor*2, height: size).background(.black)
                  .foregroundStyle(.white)
              }
              Text(item.char.toString()).font(.callout).padding(.top, 5).padding(.bottom, 2)
                .foregroundStyle(single?.work.btType.nameColor(baseColor: defaultTextColor) ?? defaultTextColor)
            }.padding(.top, 5).padding(.bottom, 3).padding(.horizontal, itemPaddingHor).frame(width: size).frame(height: size+20)
              .background(selected ? .gray.opacity(0.4) : .white).clipShape(RoundedRectangle(cornerRadius: 4))
          }.buttonStyle(BgClickableButton())
        }
      }
    }
  }
  
  private let workPadding: CGFloat = 5
  @State private var singleIndex = 0
  @State private var workIndex = 0
  @State private var singleProxy: ScrollViewProxy? = nil
  @State private var workProxy: ScrollViewProxy? = nil
  
  private let scrollSettings = ScrollableBarSettings(
    textColors: [.gray, .white],
    textFonts: [.system(size: 14), .system(size: 12)],
    indicatorHeight: 1.5,
    indicatorPadding: 0,
    indicatorTextSpacing: 0,
    backgroundColor: .blue)
  
  private let itemPaddingHor: CGFloat = 6
  private let defaultTextColor = Color.defaultText
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          
        }
        Spacer()
        Text("title_jizi".localized).font(.title3)
          .foregroundStyle(Color.colorPrimary)
        Spacer()
        Button {
          
        } label: {
          Image("switches").renderingMode(.template).square(size: CUSTOM_NAVI_ICON_SIZE-2)
            .foregroundStyle(Color.colorPrimary)
        }
      }.background(Colors.surfaceVariant.swiftColor)
      Divider()
      HStack {
        Button {
          
        } label: {
          HStack(spacing: 4) {
            Image(JiziOptionType.Work.icon).renderingMode(.template).square(size: 14)
            if let selected = viewModel.selectedWork {
              Text(selected.workNameAttrStr())
            } else {
              Text(JiziOptionType.Work.chinese)
            }
          }.foregroundStyle(Colors.iconColor(1))
        }
        Button {
          
        } label: {
          HStack(spacing: 4) {
            Image(JiziOptionType.Font.icon).renderingMode(.template).square(size: 16)
            if let selected = viewModel.selectedFont {
              Text(selected.longChinese)
            } else {
              Text(JiziOptionType.Font.chinese)
            }
          }.foregroundStyle(Colors.iconColor(1))
        }
        Spacer()
        
        Button {
          
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "command").square(size: 11)
            Text("puzzle".localized).font(.system(size: 14))
          }
        }.buttonStyle(PrimaryButton(bgColor: .blue))
      }.padding(.vertical, 10).padding(.horizontal, 14)
      Divider().padding(.horizontal, 10)
      candidatePanel
      if let candidates = singleCharCandidates {
        5.VSpacer()
        let keys = Array(candidates.keys)
        let singles = currentItem.results ?? Array()
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
              }.id(currentItem.char)
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
                  let selected = i == viewModel.singleIndex
                  HStack {
                    Button {
                      singleIndex = i
                      viewModel.selectSingle(i, single)
                    } label: {
                      WebImage(url: single.thumbnailUrl.url!) { img in
                        img.image?.resizable()
                          .aspectRatio(contentMode: .fit)
                          .frame(minWidth: 10, minHeight: 10)
                      }.clipShape(RoundedRectangle(cornerRadius: 2))
                      .padding(0.5)
                      .background {
                        RoundedRectangle(cornerRadius: 2).stroke(selected ? .red: .white, lineWidth: selected ? 2 : 0.5)
                      }.padding(.horizontal, selected ? 0 : 0.5)
                    }
                  }.id(i).padding(.horizontal, 5)
                }
              }.background(Color.singlePreviewBackground)
                .onAppear {
                  singleProxy = proxy
                }.id(currentItem.char)
            }.padding(.top, 9).padding(.bottom, Device.hasTopNotch ? 0 : 9).padding(.horizontal, 5)
          }.onChange(of: viewModel.singleIndex) { newValue in
              if singleIndex != newValue {
                self.singleIndex = newValue
                self.singleProxy?.scrollTo(newValue, anchor: .leading)
              }
            }
            .onChange(of: viewModel.singleStartIndex) { newValue in
              singleProxy?.scrollTo(newValue, anchor: .leading)
            }.background(Color.singlePreviewBackground)
            .frame(height: 80)
        }
      }
    }.navigationBarHidden(true)
  }
}


#Preview {
  JiziView(viewModel: {
    let vm = JiziViewModel(text: "寒雨连江夜入吴")
    vm.onSearch {
      
    }
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
