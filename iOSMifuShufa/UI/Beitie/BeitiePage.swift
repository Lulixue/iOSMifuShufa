//
//  BeitiePage.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import SwiftUI
import DeviceKit
import SDWebImageSwiftUI
import Combine

extension View {
  @ViewBuilder func listItemBox() -> some View {
    self.font(.system(size: 10.5))
    .padding(.horizontal, 4)
    .padding(.vertical, 3)
    .fontWeight(.regular)
    .background(Colors.surfaceContainer.swiftColor)
    .clipShape(RoundedRectangle(cornerRadius: 4))
  }
  
  @ViewBuilder func viewShape<S>(_ shape: S) -> some View where S : Shape {
    contentShape(shape)
      .clipped()
  }
}

struct SearchBar: View {
  @FocusState var focused: Bool
  @EnvironmentObject var viewModel: BeitieViewModel
  func onSearch() {
    focused = false
    viewModel.onSearch()
  }
  var body: some View {
    HStack(spacing: 10) {
      Button {
        viewModel.dismissSearchBar()
      } label: {
        Image(systemName: "xmark").square(size: 11).foregroundStyle(.white)
          .padding(.horizontal, 3)
      }.frame(height: viewModel.searchBarHeight).buttonStyle(.plain)
      TextField("search_beitie_hint".localized, text: $viewModel.searchText,
                onEditingChanged: { focused in
      })
      .font(.callout)
      .focused($focused)
      .textFieldStyle(.plain)
      .submitLabel(.search)
      .onSubmit {
        onSearch()
      }
      .padding(.horizontal, 5).padding(.vertical, 5).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 3))
      
      Button {
        onSearch()
      } label: {
        Text("search".localized).foregroundStyle(.white)
      }.buttonStyle(.plain)
      
    }.padding(.horizontal, 10).background(Color.searchHeader).frame(height: viewModel.searchBarHeight)
  }
}

struct VersionWorkView: View {
  let works: List<BeitieWork>
  @EnvironmentObject var viewModel: BeitieViewModel
  @EnvironmentObject var naviVM: NavigationViewModel

  var body: some View {
    VStack {
      VStack(spacing: 0) {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          Text(works.first().name).underline()
          Text(" (\(works.size))").font(.footnote)
        }.foregroundStyle(Color.darkSlateBlue)
        12.VSpacer()
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(0..<works.size, id: \.self) { i in
              Section {
                let work = works[i]
                let version = work.chineseVersion()
                let name = version?.isNotEmpty() == true ? version! : work.chineseName()
                Button {
                  if !viewModel.listView {
                    naviVM.gotoWork(work: work)
                  } else {
                    naviVM.gotoWorkIntro(work: work)
                  }
                } label: {
                  HStack {
                    ZStack(alignment: .topLeading) {
                      WebImage(url: work.cover.url!) { img in
                        img.image?.resizable()
                          .aspectRatio(contentMode: .fill)
                      }.frame(width: 50, alignment: .topTrailing)
                        .frame(height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                      if (work.vip) {
                        VipBackground()
                      }
                    }.frame(width: 50, height: 40)
                    
                    VStack(alignment: .leading, spacing: 5) {
                      Text(name).foregroundStyle(Color.defaultText)
                        .font(.system(size: 15))
                      if work.hasSingle() {
                        Text(work.singleCount.toString() + "single_zi".localized)
                          .foregroundStyle(Color.darkSlateBlue)
                          .listItemBox()
                      }
                      if !work.isTrue() {
                        FakeTagView(radius: 0)
                      }
                    }
                    Spacer()
                    Button {
                      naviVM.gotoWork(work: work)
                    } label: {
                      HStack(spacing: 3) {
                        Image(systemName: "arrow.up.right.square").square(size: 10)
                        Text("查看").font(.footnote)
                      }
                    }.buttonStyle(PrimaryButton(bgColor: .blue, horPadding: 6, verPadding: 4))
                      .padding(.leading, 3)
                  }.padding(.vertical, 8).padding(.horizontal, 15).background(.white)
                }.buttonStyle(BgClickableButton())
              } footer: {
                if i != works.lastIndex {
                  Divider().padding(.leading, 10)
                }
              }
            }
          }
        }
      }.padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.2), lineWidth: 0.5))
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 5))
        .frame(maxHeight: UIScreen.currentHeight * 0.5)
        .frame(maxWidth: UIScreen.currentWidth * 0.75)
      20.VSpacer()
      Button {
        viewModel.hideVersionWorks()
      } label: {
        HStack {
          Image(systemName: "xmark").square(size: 10)
          Text("close_window".localized).font(.callout)
        }
      }.buttonStyle(PrimaryButton(bgColor: Colors.souyun.swiftColor, horPadding: 10, verPadding: 8))
    }
  }
}

struct WorkListItem: View {
  let works: List<BeitieWork>
  @EnvironmentObject var viewModel: BeitieViewModel
  @EnvironmentObject var naviVM: NavigationViewModel
  
  var body: some View {
    Button {
      if (works.size > 1) {
        viewModel.updateVersionWorks(works: works)
      } else {
        naviVM.gotoWorkIntro(work: works.first())
      }
    } label: {
      HStack(spacing: 6) {
        let first = works.first()
        VStack(alignment: .leading, spacing: 6) {
          let color = first.btType.nameColor(baseColor: Color.darkSlateGray)
          HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(first.chineseName()).font(.system(size: 17.5))
              .foregroundStyle(color)
            if viewModel.organizeStack && works.size > 1 {
              Text("(\(works.size))").font(.footnote).foregroundStyle(color)
            } else if first.chineseVersion()?.isNotEmpty() == true {
              Text(first.chineseVersion()!).font(.footnote)
                .foregroundStyle(Colors.purple.swiftColor)
            }
            if works.count(where: { $0.vip }) == works.size {
              Image("vip_border").renderingMode(.template).square(size: 14)
                .foregroundStyle(.blue).padding(.leading, 2)
            }
          }
          if first.chineseYear()?.isNotEmpty() == true {
            Text(first.chineseYear()! + "(\(first.ceYear))")
              .font(.system(size: 12))
              .foregroundStyle(Color.darkSlateBlue)
          }
        }
        Spacer()
        if first.hasSingle() {
          Text(first.singleCount.toString() + "single_zi".localized)
            .foregroundStyle(Color.defaultText)
            .listItemBox()
        }
        if first.type != .Hua {
          Text(first.showTypeChinese)
            .foregroundStyle(Color.souyun)
            .listItemBox()
          Text(first.font.longChinese)
            .font(.system(size: 11))
            .foregroundStyle(Color.defaultText)
        } else {
          Text(first.type.chinese)
            .font(.system(size: 11))
            .foregroundStyle(Color.defaultText)
        }
        Button {
          naviVM.gotoWork(work: works.first())
        } label: {
          HStack(spacing: 3) {
            Image(systemName: "arrow.up.right.square").square(size: 10)
            Text("查看").font(.footnote)
          }
        }.buttonStyle(PrimaryButton(bgColor: .blue, horPadding: 6, verPadding: 4))
          .padding(.leading, 3)
      }.padding(.vertical, 10)
        .padding(.horizontal, 13)
        .background(.white)
    }.buttonStyle(BgClickableButton())
  }
}

class WorkItemViewModel: BaseObservableObject {
  @Published var image: UIImage? = nil
  @Published var loading: Bool = true
  private var uiImageView: UIImageView!
  let works: [BeitieWork]
  init(works: List<BeitieWork>) {
    self.works = works
    uiImageView = UIImageView(frame: .zero)
    super.init()
    let first = works.first { $0.hasSingle() } ?? works.first()
    let url = first.cover.url!
    self.uiImageView.sd_setImage(with: url) { img, _, _, _ in
      DispatchQueue.main.async {
        self.image = img
        self.loading = false
      }
    }
  }
}

struct WorkItem: View {
  static let itemWidth: CGFloat = 110
  static let itemHeight: CGFloat = 100
  var works: List<BeitieWork> {
    itemViewModel.works
  }
  @EnvironmentObject var viewModel: BeitieViewModel
  @EnvironmentObject var naviVM: NavigationViewModel
  @StateObject var itemViewModel: WorkItemViewModel
   
  
  private func onClick() {
    debugPrint("onClick \(works.first().chineseName())")
    if works.size == 1 {
      naviVM.gotoWork(work: works.first())
    } else {
      viewModel.updateVersionWorks(works: works)
    }
  }
  
  var body: some View {
    Button {
      onClick()
    } label: {
      let first = works.first()
      VStack(spacing: 2) {
        if let image = itemViewModel.image {
            Image(uiImage: image).resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: Self.itemWidth-10)
              .frame(height: Self.itemHeight-30)
              .clipShape(RoundedRectangle(cornerRadius: 3))
              .modifier(BeitieModifier(work: first))
        } else {
          ProgressView().squareFrame(30)
            .progressViewStyle(.circular)
            .tint(.colorPrimary)
        }
        let color = first.btType.nameColor(baseColor: Color.darkSlateGray)
        HStack(alignment: .firstTextBaseline, spacing: 1) {
          Text(first.chineseName()).font(.system(size: 14))
            .lineLimit(1).foregroundStyle(color)
          if viewModel.organizeStack && works.size > 1 {
            Text("(\(works.size))").font(.system(size: 10))
              .lineLimit(1).foregroundStyle(color)
          } else if first.chineseVersion()?.isNotEmpty() == true {
            Text(first.chineseVersion()!).font(.system(size: 10))
              .lineLimit(1).foregroundStyle(Colors.purple.swiftColor)
          }
        }.padding(.top, 2)
      }.padding(.horizontal, 5)
        .padding(.top, 5).padding(.bottom, 5).frame(width: Self.itemWidth, height: Self.itemHeight)
        .overlay(content: {
          RoundedRectangle(cornerRadius: 5)
            .stroke(.gray, lineWidth: 0.5)
        })
        .background(.white)
    }.buttonStyle(BgClickableButton())
      .padding(.bottom, 10)
  }
}


func keyToString(key: AnyHashable) -> String {
  if key is WorkCategory {
    (key as! WorkCategory).chinese
  } else {
    "\(key)"
  }
}

struct CategoryItem: View {
  let key: AnyHashable
  let works: List<List<BeitieWork>>
  let rowCount: Int
  let itemSpacing: CGFloat
  @State var collapse: Bool = false
  let rowSize: Int
  @EnvironmentObject var viewModel: BeitieViewModel
  @EnvironmentObject var naviVM: NavigationViewModel
  let itemViewModels: [Int: WorkItemViewModel]
  
  init(key: AnyHashable, works: List<List<BeitieWork>>) {
    self.key = key
    self.works = works
    
    var rowItemSize = (UIScreen.currentWidth / WorkItem.itemWidth).toInt().toCGFloat()
    var spacing = (UIScreen.currentWidth - rowItemSize * WorkItem.itemWidth) / (rowItemSize + 1)
    if (spacing < 10) {
      rowItemSize -= 1
      spacing = (UIScreen.currentWidth - rowItemSize * WorkItem.itemWidth) / (rowItemSize + 1)
    }
    self.rowSize = Int(rowItemSize)
    self.itemSpacing = spacing
    self.rowCount = works.size / rowSize + ((works.size % rowSize > 0) ? 1 : 0)
    
    var models = [Int: WorkItemViewModel]()
    for i in 0..<works.size {
      models[i] = WorkItemViewModel(works: works[i].sortedByDescending(mapper: { $0.hasSingle() }))
    }
    self.itemViewModels = models
  }
  
  var body: some View {
    Section {
      if !collapse {
        VStack(spacing: 0) {
          if viewModel.listView {
            ForEach(0..<works.size, id: \.self) { i in
              WorkListItem(works: works[i].sortedByDescending(mapper: { $0.hasSingle() }))
              if i != works.lastIndex {
                Divider.overlayColor(.gray.opacity(0.4)).padding(.leading, 10)
              }
            }
          } else {
            4.VSpacer()
            ForEach(0..<rowCount, id: \.self) { i in
              HStack(spacing: itemSpacing) {
                let start = i * rowSize
                let end = min((i+1) * rowSize, works.size+1)
                ForEach(start..<end, id:\.self) { j in
                  if j < works.size, let vm = itemViewModels[j] {
                    WorkItem(itemViewModel: vm)
                      .id("\(key)\(j)")
                  } else {
                    Spacer()
                  }
                }
              }.frame(maxWidth: .infinity).padding(.horizontal, itemSpacing)
            }
          }
        }.padding(.vertical, 6)
      }
    } header: {
      VStack(spacing: 0) {
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            collapse.toggle()
          }
        } label: {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(keyToString(key: key)).frame(alignment: .leading)
              .foregroundColor(Colors.searchHeader.swiftColor)
              .font(.system(size: 16))
            Text("(\(works.size))").font(.footnote).foregroundColor(Colors.searchHeader.swiftColor)
            Spacer()
            Image(systemName: "chevron.down")
              .square(size: 10).foregroundStyle(UIColor.lightGray.swiftColor)
              .rotationEffect(.degrees(collapse ? -90 : 0))
          }.padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.vertical, 9).background(Colors.surfaceVariant.swiftColor)
        }.buttonStyle(BgClickableButton())
      }
    } footer: {
      if collapse {
        Divider.overlayColor(Color.gray.opacity(0.25))
      }
    }
  }
}


struct BeitieImageResultView : View {
  let match: BeitieImageMatch
  
  @EnvironmentObject var viewModel: BeitieViewModel
  @EnvironmentObject var naviVM: NavigationViewModel
  
  @State var collapse = false
  let itemViewModel: WorkItemViewModel
  
  init(_ match: BeitieImageMatch) {
    self.match = match
    self.itemViewModel = WorkItemViewModel(works: [match.work])
  }
  
  var images: List<BeitieImage> {
    match.images
  }
  
  var body: some View {
    Section {
      if !collapse {
        VStack(spacing: 0) {
          ForEach(0..<images.size, id: \.self) { i in
            let img = images[i]
            let html = match.htmls[i]
            Button {
              naviVM.gotoWork(work: match.work, index: img.index-1)
            } label: {
              HStack {
                10.HSpacer()
                WebImage(url: img.url(.JpgCompressedThumbnail).url!) { img in
                    img.image?.resizable()
                      .aspectRatio(contentMode: .fill)
                  }.frame(width: 40,alignment: .topTrailing)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                Text(html).font(.body).multilineTextAlignment(.leading)
                  .lineLimit(100)
                Spacer()
              }.padding(.vertical, 8)
                .background(.white)
            }.buttonStyle(BgClickableButton())
            if i != images.lastIndex {
              Divider.overlayColor(.gray.opacity(0.4)).padding(.leading, 10)
            }
          }
        }.padding(.vertical, 6)
      }
    } header: {
      VStack(spacing: 0) {
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            collapse.toggle()
          }
        } label: {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(keyToString(key: match.work.chineseName())).frame(alignment: .leading)
              .foregroundColor(Colors.searchHeader.swiftColor)
              .font(.system(size: 16))
            Text("(\(match.images.size))").font(.footnote).foregroundColor(Colors.searchHeader.swiftColor)
            Spacer()
            Image(systemName: "chevron.down")
              .square(size: 10).foregroundStyle(UIColor.lightGray.swiftColor)
              .rotationEffect(.degrees(collapse ? -90 : 0))
          }.padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.vertical, 9).background(Colors.surfaceVariant.swiftColor)
        }.buttonStyle(BgClickableButton())
      }
    } footer: {
      if collapse {
        Divider.overlayColor(Color.gray.opacity(0.25))
      }
    }
  }
}

struct FakeTagView: View {
  var radius: CGFloat = 3
  var body: some View {
    Image("fake")
      .renderingMode(.template)
      .square(size: 15)
      .foregroundStyle(.white)
      .padding(2)
      .background {
        Circle().fill(.red)
          .shadow(radius: radius)
      }
  }
}

struct BeitieModifier: ViewModifier {
  let work: BeitieWork
  var showFake: Bool = true
  func body(content: Content) -> some View {
    ZStack(alignment: .topLeading) {
      content
      if (work.vip) {
        VipBackground()
      }
      if showFake && !work.isTrue() {
        HStack {
          Spacer()
          FakeTagView()
        }.padding(.trailing, 2)
      }
    }
  }
}


struct BeitiePage: View {
  @StateObject var viewModel: BeitieViewModel = BeitieViewModel()
  private let btnColor = Color.colorPrimary
  @State var showOrderDropdown = false
  @State var showAzDropdown = false
  @EnvironmentObject var navigationVM: NavigationViewModel
   
  private let gridItemLayout = {
    var size = ((UIScreen.currentWidth - 100) / WorkItem.itemWidth)
    return (0..<Int(size)).map { _ in
      GridItem(.flexible())
    }
  }()
  
  @ViewBuilder
  func workListView(_ showMap: BeitieDbHelper.BeitieDictionary) -> some View {
    let keys = showMap.keys.map({ $0 })
    ForEach(0..<keys.size, id: \.self) { i in
      let key = keys[i]
      let works = showMap[key]!
      CategoryItem(key: key, works: works)
        .id(i)
    }
  }
  
  var workList: some View {
    LazyVStack(alignment: .center, spacing: 0, pinnedViews: [.sectionHeaders]) {
      workListView(viewModel.showMap)
      Spacer()
    }
  }
  
  @State var scrollProxy: ScrollViewProxy? = nil
  @State var orderPosition: CGRect = .zero
  
  var resultList: some View {
    LazyVStack(alignment: .center, spacing: 0, pinnedViews: [.sectionHeaders]) {
      let keys = viewModel.searchResult.keys.map { $0 }
      ForEach(0..<keys.size, id: \.self) { i in
        let key = keys[i]
        if key == viewModel.BEITIE {
          workListView(viewModel.searchResult[key] as! BeitieDbHelper.BeitieDictionary)
        } else {
          let matches = viewModel.searchResult[key] as! List<BeitieImageMatch>
          ForEach(0..<matches.size, id: \.self) { j in
            BeitieImageResultView(matches[j])
          }
        }
      }
      Spacer()
    }
  }
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(spacing: 0) {
        ZStack {
          HStack(spacing: 11) {
            Button {
              viewModel.showSearchBar.toggle()
            } label: {
              Image(systemName: "magnifyingglass")
                .square(size: 18, padding: 0.8)
                .foregroundStyle(btnColor)
            }.buttonStyle(.plain)
            Button {
              showAzDropdown = true
            } label: {
              Image(systemName: "arrow.down.to.line").square(size: 18)
                .foregroundStyle(btnColor)
            }.buttonStyle(.plain)
            Spacer()
            Button {
              viewModel.listView.toggle()
            } label: {
              Image(viewModel.listView ? "list" : "previews").renderingMode(.template).square(size: 20)
                .foregroundStyle(btnColor)
            }.buttonStyle(.plain)
            Button {
              showOrderDropdown.toggle()
            } label: {
              Image("sort").renderingMode(.template).square(size: 20)
                .foregroundStyle(btnColor)
            }.buttonStyle(.plain)
          }.padding(.horizontal, 12)
          NaviTitle(text: "title_beitie".localized)
        }.frame(height: CUSTOM_NAVIGATION_HEIGHT).background(Colors.surfaceVariant.swiftColor)
        Divider()
        ZStack(alignment: .top) {
          if !viewModel.showSearchResult {
            ScrollView {
              ScrollViewReader { proxy in
                workList
                  .id("\(viewModel.orderType)")
                  .modifier(DragDismissModifier(show: $showAzDropdown))
                  .modifier(DragDismissModifier(show: $showOrderDropdown))
                  .onAppear {
                    scrollProxy = proxy
                  }
              }
            }.blur(radius: viewModel.showVersionWorks ? 5 : 0)
              .padding(.top, viewModel.showSearchBar ? viewModel.searchBarHeight : 0)
          }
          if viewModel.showVersionWorks {
            ZStack(alignment: .center) {
              Color.black.opacity(0.8)
              VersionWorkView(works: viewModel.versionWorks)
            }
          }
          if viewModel.showSearchBar {
            VStack(spacing: 0) {
              SearchBar()
              if viewModel.showSearchResult {
                resultList
              }
              Spacer()
            }
          }
        }
      }.background(Color.white)
      if showOrderDropdown {
        DropDownOptionsView(param: viewModel.param, selected: viewModel.orderType, selectedDecoration: [.Bold, .Underline], onClickItem: { t in
          viewModel.orderType = t
          showOrderDropdown = false
        })
        .offset(x: -10, y: 36)
      }
      if showAzDropdown {
        let offsetX = viewModel.orderParam!.maxWidth+40
        DropDownOptionsView(param: viewModel.orderParam!, selected: nil, selectedDecoration: [], onClickItem: { t in
          let index = viewModel.orderParam.items.indexOf(t)
          scrollProxy?.scrollTo(index, anchor: .top)
          showAzDropdown = false
        })
        .offset(x: -UIHelper.screenWidth+offsetX, y: 36)
      }
      if viewModel.showToast {
        ZStack {
          Color.clear
          ToastView(title: viewModel.toastTitle)
        }
      }
    }.modifier(TapDismissModifier(show: $showAzDropdown))
      .modifier(TapDismissModifier(show: $showOrderDropdown))
      .modifier(AlertViewModifier(viewModel: viewModel))
    .gesture(TapGesture().onEnded({ _ in
      viewModel.hideVersionWorks()
    }), isEnabled: viewModel.showVersionWorks)
    .environmentObject(viewModel)
    .environmentObject(navigationVM)
    .onChange(of: viewModel.organizeStack) { _ in
      viewModel.syncShowMap()
      resetScroll()
    }
    .onChange(of: viewModel.listView, perform: { newValue in
      resetScroll()
    })
    .onChange(of: viewModel.orderType) { _ in
      viewModel.syncShowMap()
      resetScroll()
    }
    .onChange(of: viewModel.showSearchBar) { _ in
      if !viewModel.showSearchBar {
        viewModel.showSearchResult = false
      }
      resetScroll()
    }
  }
  
  private func resetScroll() {
    debugPrint("resetScroll")
    Task {
      try? await Task.sleep(nanoseconds: 300_000_000)
      DispatchQueue.main.async {
        self.scrollProxy?.scrollTo(0, anchor: .top)
      }
    }
  }
}

#Preview {
  BeitiePage().environmentObject(NavigationViewModel())
}
