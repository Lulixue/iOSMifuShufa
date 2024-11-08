//
//  BeitiePage.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//

import SwiftUI
import DeviceKit
import SDWebImageSwiftUI

extension CGFloat {
  func calculateRowSize(maxWidth: CGFloat) {
    
  }
}

extension View {
  @ViewBuilder func listItemBox() -> some View {
    self.font(.system(size: 11))
    .padding(.horizontal, 5)
    .padding(.vertical, 5)
    .fontWeight(.regular)
    .background(Colors.surfaceContainer.swiftColor)
    .clipShape(RoundedRectangle(cornerRadius: 2))
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
      }.frame(height: viewModel.searchBarHeight)
      TextField("search_beitie_hint".localized, text: $viewModel.searchText,
                onEditingChanged: { focused in
      })
      .font(.footnote)
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
      }
      
    }.padding(.horizontal, 10).background(Color.searchHeader).frame(height: viewModel.searchBarHeight)
  }
}

struct VersionWorkView: View {
  let works: List<BeitieWork>
  @EnvironmentObject var viewModel: BeitieViewModel

  var body: some View {
    VStack {
      VStack(spacing: 0) {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          Text(works.first().name).underline()
          Text(" (\(works.size))").font(.footnote)
        }.foregroundStyle(Color.darkSlateBlue)
        20.VSpacer()
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(0..<works.size, id: \.self) { i in
              Section {
                let work = works[i]
                let version = work.chineseVersion()
                let name = version?.isNotEmpty() == true ? version! : work.chineseName()
                Button {
                  
                } label: {
                  HStack {
                    WebImage(url: work.cover.url!) { img in
                      img.image?.resizable()
                        .aspectRatio(contentMode: .fill)
                    }.frame(width: 50, alignment: .topTrailing)
                      .frame(height: 40)
                      .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    VStack(alignment: .leading, spacing: 5) {
                      Text(name).foregroundStyle(Color.defaultText)
                        .font(.system(size: 15))
                      if work.hasSingle() {
                        Text(work.singleCount.toString() + "single_zi".localized)
                          .foregroundStyle(Color.darkSlateBlue)
                          .listItemBox()
                      }
                    }
                    Spacer()
                    Button {
                      
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
  
  var body: some View {
    Button {
      if (works.size > 1) {
        viewModel.updateVersionWorks(works: works)
      }
    } label: {
      HStack(spacing: 6) {
        let first = works.first()
        VStack(alignment: .leading, spacing: 6) {
          HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(first.chineseName())
              .foregroundStyle(Color.darkSlateGray)
            if viewModel.organizeStack && works.size > 1 {
              Text("(\(works.size))").font(.footnote).foregroundStyle(Color.darkSlateGray)
            } else if first.chineseVersion()?.isNotEmpty() == true {
              Text(first.chineseVersion()!).font(.footnote)
                .foregroundStyle(Color.darkSlateBlue)
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
          
        } label: {
          HStack(spacing: 3) {
            Image(systemName: "arrow.up.right.square").square(size: 10)
            Text("查看").font(.footnote)
          }
        }.buttonStyle(PrimaryButton(bgColor: .blue, horPadding: 6, verPadding: 4))
          .padding(.leading, 3)
      }.padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(.white)
    }.buttonStyle(BgClickableButton())
  }
}

struct WorkItem: View {
  static let itemWidth: CGFloat = 110
  static let itemHeight: CGFloat = 100
  let works: List<BeitieWork>
  @EnvironmentObject var viewModel: BeitieViewModel
  @State var coverUrl: URL
  @State var image: UIImage? = nil
  @State var loading: Bool = true
  
  init(works: List<BeitieWork>) {
    self.works = Array(works)
    let first = works.first { $0.hasSingle() } ?? works.first()
    self.coverUrl = URL(string: first.cover)!
  }
  
  private func onClick() {
    printlnDbg("onClick")
    if works.size == 1 {
      
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
        WebImage(url: coverUrl) { img in
          img.image?.resizable()
            .aspectRatio(contentMode: .fill)
        }
        .onSuccess(perform: { image, data, cacheType in
          DispatchQueue.main.async {
            self.loading = false
          }
        })
        .indicator(.activity).frame(width: Self.itemWidth-10, alignment: loading ? .center : .topTrailing)
        .frame(minHeight: Self.itemHeight-30)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        
        HStack(alignment: .firstTextBaseline, spacing: 1) {
          Text(first.chineseName()).font(.footnote)
            .lineLimit(1).foregroundStyle(Colors.darkSlateGray.swiftColor)
          if viewModel.organizeStack && works.size > 1 {
            Text("(\(works.size))").font(.system(size: 10))
              .lineLimit(1).foregroundStyle(Colors.darkSlateGray.swiftColor)
          } else if first.chineseVersion()?.isNotEmpty() == true {
            Text(first.chineseVersion()!).font(.system(size: 10))
              .lineLimit(1).foregroundStyle(Colors.souyun.swiftColor)
          }
        }
      }.padding(.horizontal, 5)
        .padding(.top, 5).padding(.bottom, 3).frame(width: Self.itemWidth, height: Self.itemHeight)
        .overlay(content: {
          RoundedRectangle(cornerRadius: 5)
            .stroke(.gray, lineWidth: 0.5)
        })
        .background(.white)
    }.buttonStyle(BgClickableButton())
      .padding(.bottom, 10)
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
  }
  
  func keyToString(key: AnyHashable) -> String {
    if key is WorkCategory {
      (key as! WorkCategory).chinese
    } else {
      "\(key)"
    }
  }
  
  var body: some View {
    Section {
      if !collapse {
        VStack(spacing: 0) {
          if viewModel.listView {
            ForEach(0..<works.size, id: \.self) { i in
              WorkListItem(works: works[i])
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
                  if j < works.size {
                    WorkItem(works: works[j])
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
          collapse.toggle()
        } label: {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(keyToString(key: key)).frame(alignment: .leading)
              .foregroundColor(Colors.searchHeader.swiftColor)
              .font(.system(size: 15))
            Text("(\(works.size))").font(.footnote).foregroundColor(Colors.searchHeader.swiftColor)
            Spacer()
            Image(systemName: "chevron.down")
              .square(size: 10).foregroundStyle(UIColor.lightGray.swiftColor)
              .rotationEffect(.degrees(collapse ? -90 : 0))
          }.padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.vertical, 8).background(Colors.surfaceVariant.swiftColor)
        }.buttonStyle(BgClickableButton())
      }
    } footer: {
      if collapse {
        Divider.overlayColor(Color.gray.opacity(0.25))
      }
    }
  }
}

struct BeitiePage: View {
  @StateObject var viewModel: BeitieViewModel = BeitieViewModel()
  private let btnColor = Color.colorPrimary
  @State var showOrderDropdown = false
   
  private let gridItemLayout = {
    var size = ((UIScreen.currentWidth - 100) / WorkItem.itemWidth)
    return (0..<Int(size)).map { _ in
      GridItem(.flexible())
    }
  }()
  
  var workList: some View {
    LazyVStack(alignment: .center, spacing: 0, pinnedViews: [.sectionHeaders]) {
      let showMap = viewModel.showMap
      ForEach(showMap.keys.map({ $0 }), id: \.self) { key in
        let works = showMap[key]!
        CategoryItem(key: key, works: works)
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
                .foregroundStyle(btnColor)
            }
            Button {
              viewModel.organizeStack.toggle()
            } label: {
              Image(viewModel.organizeStack ? "stack" : "single").renderingMode(.template).square(size: 20)
                .foregroundStyle(btnColor)
            }
            Spacer()
            if viewModel.orderType == .Az {
              Button {
                
              } label: {
                Image("order_pinyin").renderingMode(.template).square(size: 20)
                  .foregroundStyle(btnColor)
              }
            }
            
            Button {
              viewModel.listView.toggle()
            } label: {
              Image(viewModel.listView ? "list" : "previews").renderingMode(.template).square(size: 20)
                .foregroundStyle(btnColor)
            }
            Button {
              showOrderDropdown.toggle()
            } label: {
              Image("sort").renderingMode(.template).square(size: 20)
                .foregroundStyle(btnColor)
            }
          }.padding(.horizontal, 12)
          Text("title_beitie".localized)
            .foregroundStyle(btnColor)
        }.frame(height: CUSTOM_NAVIGATION_HEIGHT).background(Colors.surfaceVariant.swiftColor)
        Divider()
        ZStack(alignment: .top) {
          ScrollView {
            workList
          }.blur(radius: viewModel.showVersionWorks ? 3 : 0)
            .padding(.top, viewModel.showSearchBar ? viewModel.searchBarHeight : 0)
          if viewModel.showVersionWorks {
            ZStack(alignment: .center) {
              Color.black.opacity(0.35)
              VersionWorkView(works: viewModel.versionWorks)
            }
          }
          if viewModel.showSearchBar {
            SearchBar()
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
    }.simultaneousGesture(TapGesture().onEnded({ _ in
        showOrderDropdown = false
      }), isEnabled: showOrderDropdown)
    .gesture(TapGesture().onEnded({ _ in
      viewModel.hideVersionWorks()
    }), isEnabled: viewModel.showVersionWorks)
    .environmentObject(viewModel)
    .onChange(of: viewModel.organizeStack) { _ in
      viewModel.syncShowMap()
    }
    .onChange(of: viewModel.orderType) { _ in
      viewModel.syncShowMap()
    }
    .onChange(of: viewModel.showSearchBar) { _ in
      if !viewModel.showSearchBar {
        viewModel.syncShowMap()
      }
    }
  }
}

#Preview {
  BeitiePage()
}
