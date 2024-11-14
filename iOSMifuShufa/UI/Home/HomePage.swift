  //
  //  Home.swift
  //  iOSMifuShufa
  //
  //  Created by lulixue on 2024/10/30.
  //

import SwiftUI
import DeviceKit
import SDWebImageSwiftUI

struct TodayCardView<Content: View>: View {
  let title: String
  let onClick: () -> Void
  let content: Content
  init(title: String,
       onClick: @escaping () -> Void,
       @ViewBuilder content: @escaping () -> Content) {
    self.title = title
    self.onClick = onClick
    self.content = content()
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      Button {
        onClick()
      } label: {
        VStack(alignment: .leading) {
          HStack {
            Text(title).font(.callout).foregroundColor(Colors.searchHeader.swiftColor)
            Spacer()
          }
          ZStack(alignment: .topLeading) {
            Color.clear
            content
          }
        }.padding(.horizontal, 12)
          .padding(.top, 10).padding(.bottom, 15)
          .background(.white)
      }.buttonStyle(BgClickableButton())
      
    }.background(RoundedRectangle(cornerRadius: 10).fill(.white))
      .frame(maxWidth: .infinity)
      .cornerRadius(10)
      .shadow(radius: 0.8, y: 0.5)
  }
}


struct HomePage: View {
  @StateObject var viewModel: HomeViewModel
  @StateObject var sideVM = SideMenuViewModel()
  @EnvironmentObject var navVM: NavigationViewModel
  @FocusState var focused: Bool
  private let searchBarHeight = 36.0
  private let radius = 4.0
  private let font = Font.system(size: 14)
  
  
  var searchBar: some View {
    HStack {
      HStack {
        HStack {
          8.HSpacer()
          Button {
            
          } label: {
            HStack(spacing: 0) {
              Text(viewModel.searchCharType.chinese).font(font)
              3.HSpacer()
              Image(systemName: "chevron.down").square(size: 8)
            }.padding(.horizontal, 3).foregroundStyle(Color.gray)
              .font(.callout)
          }
          8.HSpacer()
        }.frame(height: searchBarHeight).background(Color.background)
        
        Color.gray.frame(width: 0.4)
        
        TextField(viewModel.searchCharType.hint, text: $viewModel.text,
                  onEditingChanged: { focused in
          if viewModel.showDeleteAlert {
            return
          }
          viewModel.focused = focused
          viewModel.updateHistoryBarVisible()
        })
        .font(font)
        .focused($focused)
        .textFieldStyle(.plain)
        .submitLabel(.search)
        .onSubmit {
          onSearch()
        }
        Button {
          onSearch()
        } label: {
          HStack(spacing: 3) {
            Image(systemName: "magnifyingglass").square(size: 10)
            Text("search".resString).font(font)
          }
        }.buttonStyle(PrimaryButton(bgColor: .blue)).padding(.trailing, 5)
      }.clipShape(RoundedRectangle(cornerRadius: radius)).padding(0.6).background(RoundedRectangle(cornerRadius: radius, style: .circular).stroke(Color.gray, lineWidth: 0.6)).frame(height: searchBarHeight)
    }.padding(.horizontal, 35)
  }
  
  private func onSearch() {
    focused = false
    let text = viewModel.text
    viewModel.onSearch(text)
  }
  
  @ViewBuilder func todayWork(_ work: BeitieWork) -> some View {
    TodayCardView(title: "今日法帖") {
      self.navVM.gotoWork(work: work)
    } content: {
      VStack(alignment: .center, spacing: 8) {
        HStack(alignment: .center) {
          Spacer()
          WebImage(url: work.cover.url!) { img in
            img.image?.resizable()
              .scaledToFit()
              .frame(height: 90)
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .padding(3)
              .background(content: {
                RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.5), lineWidth: 0.5)
              })
          }
          Spacer()
        }.padding(.vertical, 5)
        
        Text(work.workNameAttrStr(.body, smallerFont: .footnote))
          .foregroundStyle(Color.searchHeader)
        
        if work.chineseIntro()?.isNotEmpty() == true {
          Text(work.chineseIntro()!).font(.footnote)
            .lineLimit(5)
            .foregroundStyle(Color.defaultText)
        }
      }
    }
  }
  
  @ViewBuilder func todaySingle(_ single: BeitieSingle) -> some View {
    TodayCardView(title: "今日单字".orCht("今日單字")) {
      Task {
        let imageSingles = BeitieDbHelper.shared.getSinglesByImageId(single.imageId)
        let index = imageSingles.firstIndex { $0.id == single.id }!
        DispatchQueue.main.async {
          self.navVM.gotoSingles(singles: imageSingles, index: index)
        }
      }
    } content: {
      VStack(alignment: .center) {
        HStack(alignment: .center) {
          Spacer()
          WebImage(url: single.thumbnailUrl.url!) { img in
            img.image?.resizable()
              .scaledToFit()
              .frame(height: 60)
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .padding(3)
              .background(content: {
                RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.5), lineWidth: 0.5)
              })
          }
          Spacer()
        }
        Text(single.showChars)
          .foregroundStyle(Color.defaultText)
          .font(.body)
        Text(single.work.workNameAttrStr(.body, smallerFont: .footnote))
          .foregroundStyle(Color.searchHeader)
          .padding(.top, 1)
      }
    }
  }
  private let orderFont = Font.system(size: 15)
  private let orderImgSize: CGFloat = 6
  
  
  @ViewBuilder func resultSection(_ key: AnyHashable, _ singles: List<BeitieSingle>) -> some View {
    let collapseBinding = viewModel.collapseBinding(key)
    let order = viewModel.order
    Section {
      
      if !collapseBinding.wrappedValue {
        
        let showSubtitle = singles.hasAny { it in order.getSingleSubtitle(it)?.isNotEmpty() == true }
        autoColumnGrid(singles, space: 12, parentWidth: UIScreen.currentWidth, maxItemWidth: 70, rowSpace: 12, paddingValues: PaddingValue(vertical: 10)) { width, i, single in
          Button {
            viewModel.onClickSinglePreview(i, collection: singles)
          } label: {
            VStack(spacing: 5) {
              if showSubtitle {
                if let subTitle = order.getSingleSubtitle(single) {
                  Text(subTitle).font(.footnote)
                    .foregroundStyle(single.work.btType.nameColor(baseColor: Color.defaultText))
                }
              }
              let padding: CGFloat = 3
              WebImage(url: single.thumbnailUrl.url!) { img in
                img.image?.resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: width - 2 * padding)
                  .clipShape(RoundedRectangle(cornerRadius: 2))
              }.padding(padding).overlay {
                RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
              }
              
              Text(order.getSingleTitle(single))
                .lineLimit(1)
                .font(.footnote)
                .foregroundStyle(single.work.btType.nameColor(baseColor: Color.defaultText))
            }.frame(width: width)
          }
        }
      }
    } header: {
      Button {
        collapseBinding.wrappedValue.toggle()
      } label: {
        HStack {
          Text(key.toString().smallSuffix("(\(singles.size))"))
            .foregroundStyle(Color.colorPrimary)
          Spacer()
          Image(systemName: "chevron.down").square(size: 10)
            .rotationEffect(.degrees(collapseBinding.wrappedValue ? -90: 0))
        }.padding(.horizontal, 10).frame(height: 40).background(Colors.surfaceContainer.swiftColor)
      }.buttonStyle(BgClickableButton())
    } footer: {
      if collapseBinding.wrappedValue {
        Divider.overlayColor(Color.gray.opacity(0.35))
      }
    }
  }
  private let previewColor = Color.black.opacity(0.9)
  
  private func hidePreview() {
    viewModel.showPreview = false
  }
  
  var previewResult: some View {
    ZStack(alignment: .top) {
      let singles = viewModel.selectedSingleCollection
      let selectedSingle = singles[viewModel.selectedSingleIndex]
      TabView(selection: $viewModel.selectedSingleIndex) {
        ForEach(0..<singles.count, id: \.self) { i in
          let single = singles[i]
          ZStack(alignment: .top) {
            SinglePreviewItem(single: single) {
              hidePreview()
            } onClick: {
              navVM.gotoSingles(singles: singles, index: i)
            }
          }.tag(i)
        }
      }.tabViewStyle(.page(indexDisplayMode: .never))
      
      VStack {
        let attr = {
          var charAttr = AttributedString(selectedSingle.showChars)
          charAttr.font = .title3
          let sub = selectedSingle.work.workNameAttrStr(.body, smallerFont: .footnote)
          return charAttr + sub
        }()
        Spacer()
        Text(attr).foregroundStyle(.white)
      }.padding(.bottom, 8)
      VStack {
        ZStack {
          HStack {
            Spacer()
            Text("\(viewModel.selectedSingleIndex+1)/\(singles.size)")
              .font(.body)
              .foregroundStyle(.white).padding(.vertical, 12)
            Spacer()
          }
          HStack(spacing: 12) {
            Spacer()
            
            Button {
              viewModel.showDrawPanel.toggle()
              if !viewModel.showDrawPanel {
                viewModel.drawViewModel.onClose()
              }
            } label: {
              Image("handwriting").renderingMode(.template).square(size: 22).foregroundStyle(.white)
            }
            Divider.overlayColor(.white).frame(width: 0.5, height: 16)
            Button {
              hidePreview()
            } label: {
              Image(systemName: "xmark.circle").square(size: 22).foregroundStyle(.white)
            }.padding(.trailing, 10)
          }.padding(.vertical, 12)
        }
        if viewModel.showDrawPanel {
          DrawPanel().environmentObject(viewModel.drawViewModel)
        }
      }
    }.background(previewColor)
  }
  private let orderSpacing: CGFloat = 14
  private let orderBarHeight: CGFloat = 40
  @State var resultProxy: ScrollViewProxy? = nil
  var resultView: some View {
    ZStack(alignment: .topLeading) {
      VStack(spacing: 0) {
        HStack(spacing: orderSpacing) {
          Button {
            viewModel.showOrder = true
          } label: {
            HStack(spacing: 5) {
              Text(viewModel.order.chinese + "排序").font(orderFont)
              Image(systemName: "arrowtriangle.down.fill").square(size: orderImgSize)
                .rotationEffect(.degrees(viewModel.showOrder ? 180 : 0))
            }.foregroundStyle(Colors.colorPrimary.swiftColor)
          }.background(WidthReaderView(binding: $viewModel.orderWidth))
          Button {
            viewModel.showFastRedirect = true
          } label: {
            HStack(spacing: 5) {
              let fastResultKey = viewModel.resultKeys[max(viewModel.fastResultIndex, 0)]
              Text(fastResultKey).font(orderFont)
              Image(systemName: "arrowtriangle.down.fill").square(size: orderImgSize).rotationEffect(.degrees(viewModel.showFastRedirect ? 180 : 0))
            }.foregroundStyle(Colors.colorPrimary.swiftColor)
          }.background(WidthReaderView(binding: $viewModel.fastRedirectWidth))
          
          Button {
            viewModel.showFont = true
          } label: {
            HStack(spacing: 5) {
              Text(viewModel.currentFontResultKey()).font(orderFont)
              Image(systemName: "arrowtriangle.down.fill").square(size: orderImgSize).rotationEffect(.degrees(viewModel.showFont ? 180 : 0))
            }.foregroundStyle(Colors.colorPrimary.swiftColor)
          }
          Spacer()
          Button {
            viewModel.toggleCollapseAll()
            resultProxy?.scrollTo(0, anchor: .top)
          } label: {
            HStack {
              Image(systemName: "chevron.down.2").square(size: 9)
                .rotationEffect(.degrees(viewModel.allCollapse ? 180 : 0))
                .foregroundStyle(Colors.colorPrimary.swiftColor)
            }.padding(.horizontal, 12).padding(.vertical, 7)
              .overlay {
                RoundedRectangle(cornerRadius: 5).stroke(Color.searchHeader.opacity(0.8), lineWidth: 0.3)
              }
          }.buttonStyle(BgClickableButton())
            .background(WidthReaderView(binding: $viewModel.fontWidth))
        }.padding(.horizontal, 10).frame(height: orderBarHeight).background(Colors.surfaceContainer.swiftColor)
        Divider()
        ZStack {
          ScrollView {
            ScrollViewReader { proxy in
              LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                let results = viewModel.singleResult.elements
                ForEach(0..<results.count, id: \.self) { i in
                  let elem = results[i]
                  resultSection(elem.key, elem.value)
                    .id(i)
                }
              }.onAppear {
                resultProxy = proxy
              }
            }
          }.id(viewModel.resultId)
        }
      }.blur(radius: viewModel.showPreview ? 6 : 0)
      if viewModel.showPreview {
        previewResult
      }
      if viewModel.showOrder {
        DropDownOptionsView(param: viewModel.orderTypeParam) { order in
          viewModel.updateOrder(order)
        }.offset(x: 10, y: orderBarHeight+1)
      }
      if viewModel.showFastRedirect {
        DropDownOptionsView(param: viewModel.fastDirectParam) { index in
          viewModel.fastResultIndex = index
          resultProxy?.scrollTo(index - 1, anchor: .top)
        }.offset(x: 10 + viewModel.orderWidth + orderSpacing, y: orderBarHeight+1)
      }
      if viewModel.showFont {
        DropDownOptionsView(param: viewModel.fontParam) { font in
          viewModel.updatePreferredFont(font)
        }.offset(x: 10 + viewModel.orderWidth + orderSpacing + viewModel.fastRedirectWidth, y: orderBarHeight+1)
      }
    }.simultaneousGesture(TapGesture().onEnded({ _ in
      viewModel.hideDropdown()
    }), isEnabled: viewModel.hasDropdown())
    .simultaneousGesture(DragGesture().onChanged({ _ in
      viewModel.hideDropdown()
    }), isEnabled: viewModel.hasDropdown())
  }
  
  var defaultView: some View {
    ScrollView {
      VStack(spacing: 12) {
        if let single = viewModel.todaySingle {
          todaySingle(single)
        }
        if let work = viewModel.todayWork {
          todayWork(work)
        }
        Spacer()
      }.padding(.horizontal, 12).padding(.vertical, 12)
    }.background(Colors.surfaceVariant.swiftColor)
  }
  
  @Environment(\.safeAreaInsets) private var safeAreaInsets
  @State var filterWidth: CGFloat = 0
  @State var tabBarHeight: CGFloat = 0
  
  var sideMenu: some View {
    VStack(spacing: 0) {
      safeAreaInsets.top.VSpacer()
      FilterView().environmentObject(viewModel.filterViewModel)
      tabBarHeight.VSpacer()
    }.background(WidthReaderView(binding: $viewModel.filterViewModel.viewWidth))
  }
  
  var body: some View {
    SideMenu(leftMenu: sideMenu, centerView: {
      centerView
        .background(TabBarAccessor { tabBar in
          printlnDbg(">> TabBar height: \(tabBar.bounds.height)")
          tabBarHeight = tabBar.bounds.height
          if #available(iOS 18.0, *) {
            if Device.current.isPad {
              tabBarHeight = 0
            }
          }
        })
    }, viewModel: sideVM)
  }
  
  var centerView: some View {
    VStack(spacing: 0) {
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          Image("mi").renderingMode(.template).resizable().frame(width: 18, height: 20)
            .foregroundStyle(Color.searchHeader)
            .rotationEffect(.degrees(5))
          3.HSpacer()
          Image("fu").renderingMode(.template).resizable().scaledToFill().frame(width: 18, height: 22).rotationEffect(.degrees(2))
            .foregroundStyle(Color.searchHeader)
          Spacer()
          Button {
            sideVM.sideMenuLeftPanel.toggle()
          } label: {
            Image(systemName: "line.3.horizontal")
              .square(size: 20)
              .foregroundStyle(Color.colorPrimary)
              .buttonStyle(PrimaryButton())
            
          }
          5.HSpacer()
        }.padding(.horizontal, 15)
        10.VSpacer()
        searchBar
        if viewModel.showHistoryBar {
          HistoryBarView(page: .Search, showDeleteAlert: $viewModel.showDeleteAlert, onClearLogs: {
            viewModel.updateHistoryBarVisible()
          }) { l in
            viewModel.text = l.text!
            onSearch()
          }
          8.VSpacer()
        } else {
          10.VSpacer()
        }
      }.background(.white)
      0.4.HDivder()
      if viewModel.singleResult.isNotEmpty() {
        resultView.background(.white)
      } else {
        defaultView
      }
    }.background(Colors.surfaceVariant.swiftColor)
      .onAppear {
        UITextField.appearance().clearButtonMode = .whileEditing
      }.alert(viewModel.alertTitle  , isPresented: $viewModel.showAlert) {
        Button("好", role: .cancel, action: {})
      }
  }
}

#Preview {
  HomePage(viewModel: HomeViewModel())
  .environmentObject(NavigationViewModel())
}



extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
  open override func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
    }
  public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
    viewControllers.count > 1
    }
}
