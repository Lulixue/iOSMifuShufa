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

struct AlertViewModifier: ViewModifier {
  @StateObject var viewModel: AlertViewModel
  func body(content: Content) -> some View {
    content.alert(viewModel.fullAlertTitle, isPresented: $viewModel.showFullAlert) {
      Button(viewModel.fullAlertOkTitle, role: viewModel.okButtonRole) {
        viewModel.fullAlertOk()
      }
      if let cancel = viewModel.fullAlertCancelTitle {
        Button(cancel, role: viewModel.cancelButtonRole) {
          viewModel.fullAlertCancle()
        }
      }
    } message: {
      if let msg = viewModel.fullAlertMsg {
        Text(msg)
      }
    }.alert(viewModel.nextTitle, isPresented: $viewModel.nextAlert) {
      Button {
        
      } label: {
        Text("好")
      }
    }
  }
}

struct DeviceRotationViewModifier: ViewModifier {
  let action: (UIDeviceOrientation) -> Void
  
  func body(content: Content) -> some View {
    content
      .onAppear()
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        action(UIDevice.current.orientation)
      }
  }
}

struct MiGridModifier: ViewModifier {
  @StateObject var viewModel = MiGridViewModel.shared
  var onChange: () -> Void = {}
  func body(content: Content) -> some View {
    content.onChange(of: viewModel.centroidMi) { newValue in
      onChange()
    }
    .onChange(of: viewModel.singleType) { newValue in
      onChange()
    }
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
  
  
  @State private var charTypePosition: CGRect = .zero
  var searchBar: some View {
    HStack {
      HStack {
        HStack {
          8.HSpacer()
          Button {
            showCharType = true
          } label: {
            HStack(spacing: 0) {
              Text(viewModel.searchCharType.chinese).font(font)
              3.HSpacer()
              Image(systemName: "chevron.down").square(size: 8)
                .rotationEffect(.degrees(showCharType ? 180: 0))
            }.padding(.horizontal, 3).foregroundStyle(Color.gray)
              .font(.callout)
          }.buttonStyle(.plain)
          8.HSpacer()
        }.frame(height: searchBarHeight).background(Color.background)
          .background(PositionReaderView(binding: $charTypePosition))
        
        Color.gray.frame(width: 0.4)
        
        TextField(viewModel.hint, text: $viewModel.text,
                  onEditingChanged: { focused in
          if viewModel.showDeleteAlert {
            return
          }
          viewModel.focused = focused
          viewModel.updateHistoryBarVisible()
        })
        .font(.callout)
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
      }.clipShape(RoundedRectangle(cornerRadius: radius)).background(RoundedRectangle(cornerRadius: radius).fill(.white).shadow(radius: focused ? 1.5 : 0 )).padding(0.6).background(RoundedRectangle(cornerRadius: radius, style: .circular).stroke(Color.gray, lineWidth: 0.6)).frame(height: searchBarHeight)
    }
  }
  
  private func onSearch() {
    focused = false
    let text = viewModel.text
    viewModel.onSearch(text)
  }
  
  @EnvironmentObject var networkVM: NetworkMonitor
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
          }.buttonStyle(.plain)
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
  
  var rotation: Double {
    switch viewModel.orientation {
    case .portrait:
      0
    case .portraitUpsideDown:
      180
    case .landscapeLeft:
      90
    case .landscapeRight:
      270
    case .faceUp:
      0
    case .faceDown:
      0
    default:
      0
    }
  }
  @StateObject var miViewModel = MiGridViewModel.shared
  
  @State private var showMiGrids = false
  var previewResult: some View {
    ZStack(alignment: .top) {
      let singles = viewModel.selectedSingleCollection
      let selectedSingle = singles[viewModel.selectedSingleIndex]
      TabView(selection: $viewModel.selectedSingleIndex) {
        ForEach(0..<singles.count, id: \.self) { i in
          let single = singles[i]
          ZStack(alignment: .top) {
            if let vm = viewModel.singleViewModels[single] {
              MiGridZoomableImageView(viewModel: vm) {
                hidePreview()
              } onClick: {
                navVM.gotoSingles(singles: singles, index: i)
              }.rotationEffect(.degrees(rotation))
            }
          }.tag(i)
        }
      }.tabViewStyle(.page(indexDisplayMode: .never))
        .id(miViewModel.viewId)
        .onChange(of: viewModel.selectedSingleIndex, perform: { newValue in
          let single = singles[newValue]
          if miViewModel.isVipFeature && single.work.notMatchVip {
            viewModel.showToast("碑帖「\(single.work.chineseFolder())」不支持当前米字格".orCht("碑帖「\(single.work.chineseFolder())」不支持當前米字格"))
          }
        })
      
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
          VStack(spacing: 10) {
            HStack(spacing: 0) {
              NavigationLink {
                AnalyzeView(viewModel: AnalyzeViewModel(selectedSingle))
              } label: {
                Image("analyze").renderingMode(.template).square(size: 28).foregroundStyle(.white)
              }.buttonStyle(.plain)
              0.5.VDivideer(color: .white).frame(height: 16).padding(.horizontal, 12)
              Button {
                withAnimation(.linear(duration: 0.2)) {
                  showMiGrids.toggle()
                }
              } label: {
                Image("mi_mi").renderingMode(.template).square(size: 26).foregroundStyle(.white)
              }.buttonStyle(.plain)
              Spacer()
              Text("\(viewModel.selectedSingleIndex+1)/\(singles.size)")
                .font(.body)
                .foregroundStyle(.white).padding(.vertical, 8)
              Spacer()
              Button {
                viewModel.showDrawPanel.toggle()
                if !viewModel.showDrawPanel {
                  viewModel.drawViewModel.onClose()
                }
              } label: {
                Image("handwriting").renderingMode(.template).square(size: 22).foregroundStyle(.white)
              }.buttonStyle(.plain)
              0.5.VDivideer(color: .white).frame(height: 16).padding(.horizontal, 14)
              Button {
                hidePreview()
              } label: {
                Image(systemName: "xmark.circle").square(size: 22).foregroundStyle(.white)
              }.buttonStyle(.plain)
            }.padding(.top, 12).padding(.horizontal, 10)
              .background(HeightReaderView(binding: $headerHeight))
            if showMiGrids {
              SingleMiGridView(miViewModel: miViewModel)
            }
            Spacer()
          }
        }
      }
      if viewModel.showDrawPanel {
        DrawPanel().environmentObject(viewModel.drawViewModel).zIndex(10).padding(.top, headerHeight)
      }
      if viewModel.showToast {
        VStack {
          Spacer()
          ToastView(title: viewModel.toastTitle)
          Spacer()
        }
      }
    }.background(previewColor)
      .modifier(MiGridModifier(){
        viewModel.syncViewModels()
      })
  }
  
  @State private var headerHeight: CGFloat = 0
  private let orderSpacing: CGFloat = 14
  private let orderBarHeight: CGFloat = 40
  private let clickedColor: Color = .gray
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
            }.foregroundStyle(viewModel.showOrder ? clickedColor : Colors.colorPrimary.swiftColor)
          }.buttonStyle(.plain).background(WidthReaderView(binding: $viewModel.orderWidth))
          Button {
            viewModel.showFastRedirect = true
          } label: {
            HStack(spacing: 5) {
              let fastResultKey = viewModel.resultKeys[max(viewModel.fastResultIndex, 0)]
              Text(fastResultKey).font(orderFont)
              Image(systemName: "arrowtriangle.down.fill").square(size: orderImgSize).rotationEffect(.degrees(viewModel.showFastRedirect ? 180 : 0))
            }.foregroundStyle(viewModel.showFastRedirect ? clickedColor : Colors.colorPrimary.swiftColor)
          }.buttonStyle(.plain).background(WidthReaderView(binding: $viewModel.fastRedirectWidth))
          
          Button {
            viewModel.showFont = true
          } label: {
            HStack(spacing: 5) {
              Text(viewModel.currentFontResultKey()).font(orderFont)
              Image(systemName: "arrowtriangle.down.fill").square(size: orderImgSize).rotationEffect(.degrees(viewModel.showFont ? 180 : 0))
            }.foregroundStyle(viewModel.showFont ? clickedColor : Colors.colorPrimary.swiftColor)
          }.buttonStyle(.plain)
          Spacer()
          Button {
            viewModel.toggleCollapseAll()
            resultProxy?.scrollTo(0, anchor: .top)
          } label: {
            HStack {
              Image("chevron.up.2").renderingMode(.template).square(size: 9)
                .rotationEffect(.degrees(viewModel.allCollapse ? 0 : 180))
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
            .simultaneousGesture(DragGesture().onChanged({ _ in
              viewModel.hideDropdown()
            }), isEnabled: viewModel.hasDropdown())
            .simultaneousGesture(TapGesture().onEnded({ _ in
              self.viewModel.hideDropdown()
            }), isEnabled: viewModel.hasDropdown())
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
    .onChange(of: showMiGrids) { newValue in
      if !newValue {
        miViewModel.reset()
      }
    }
    .onChange(of: viewModel.showPreview) { newValue in
      if !newValue {
        showMiGrids = false
        viewModel.showDrawPanel = false
      }
    }.onChange(of: viewModel.showDrawPanel) { newValue in
      viewModel.showToast(newValue ? "handwriting_on".resString : "handwriting_off".resString)
    }
  }
  
  var defaultView: some View {
    ScrollView {
      VStack(spacing: 12) {
        if networkVM.isConnected {
          if let single = viewModel.todaySingle {
            todaySingle(single)
          }
          if let work = viewModel.todayWork {
            todayWork(work)
          }
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
        .modifier(AlertViewModifier(viewModel: viewModel.filterViewModel))
        .modifier(AlertViewModifier(viewModel: viewModel))
        .background(TabBarAccessor { tabBar in
          debugPrint(">> TabBar height: \(tabBar.bounds.height)")
          tabBarHeight = tabBar.bounds.height
          if #available(iOS 18.0, *) {
            if Device.current.isPad {
              tabBarHeight = 0
            }
          }
        })
    }, viewModel: sideVM)
  }
  
  var otherwiseCharType: some View {
    Button {
      viewModel.searchCharType = viewModel.searchCharType.otherwise
      showCharType = false
    } label: {
      HStack {
        8.HSpacer()
        HStack(spacing: 0) {
          Text(viewModel.searchCharType.otherwise.chinese).font(font)
            .foregroundStyle(.colorPrimary)
            .bold()
          3.HSpacer()
        }.padding(.horizontal, 3)
          .font(.callout).padding(.vertical, 8)
        16.HSpacer()
      }.background(Colors.surfaceContainer.swiftColor)
        .cornerRadius(2)
        .background {
          RoundedRectangle(cornerRadius: 2).stroke(.gray, lineWidth: 0.5)
        }
    }.buttonStyle(BgClickableButton())
  }
  
  @State private var showCharType = false
  var centerView: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        CalligrapherView()
        Spacer()
        Button {
          focused = false
          sideVM.sideMenuLeftPanel.toggle()
        } label: {
          Image(systemName: "line.3.horizontal")
            .square(size: 20)
            .foregroundStyle(Color.colorPrimary)
        }.buttonStyle(.plain)
        5.HSpacer()
      }.padding(.horizontal, 15)
        .background(.white)
      Color.white.frame(height: 10)
      ZStack(alignment: .topLeading) {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            searchBar
            if viewModel.showHistoryBar {
              2.VSpacer()
              HistoryBarView(page: .Search, showDeleteAlert: $viewModel.showDeleteAlert, onClearLogs: {
                viewModel.updateHistoryBarVisible()
              }) { l in
                if l.extra == "false" {
                  viewModel.filters.parseFilters(l.text!)
                } else {
                  viewModel.text = l.text!
                }
                onSearch()
              }
              8.VSpacer()
            } else {
              10.VSpacer()
            }
          }.padding(.horizontal, 35) .background(.white)
          0.4.HDivder()
          if viewModel.singleResult.isNotEmpty() {
            resultView.background(.white)
          } else {
            defaultView
          }
        }
        if showCharType {
          otherwiseCharType
            .offset(x: charTypePosition.minX, y: charTypePosition.height)
        }
      }
    }
    .modifier(TapDismissModifier(show: $showCharType))
    .modifier(DragDismissModifier(show: $showCharType))
    .background(Colors.surfaceVariant.swiftColor)
    .modifier(DeviceRotationViewModifier(action: { orientation in
      if !Device.current.isPad && AnalyzeHelper.homeRotate {
        viewModel.orientation = orientation
      } else {
        viewModel.orientation = .unknown
      }
    }))
    .onAppear {
      UITextField.appearance().clearButtonMode = .whileEditing
#if DEBUG
      Task {
        globalTest()
      }
#endif
    }
    
  }
}

#Preview {
  HomePage(viewModel: HomeViewModel())
    .environmentObject(NavigationViewModel())
    .environmentObject(NetworkMonitor())
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
