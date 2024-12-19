//
//  CollectionView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/20.
//

import SwiftUI
import Collections
import CoreData
import SDWebImageSwiftUI

enum CollectionType: String, CaseIterable {
  case Beitie
  case Single
  
  var chinese: String {
    switch self {
    case .Beitie:
      "title_beitie".localized
    case .Single:
      "single_zi".localized
    }
  }
}

class CollectionViewModel: AlertViewModel {
  static let shared = CollectionViewModel()
  @Published var allCollections = [CollectionType: [CollectionItem]]()
  private lazy var managedContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  
  override init() {
    super.init()
    self.initCollections()
  }
  
  var types: [CollectionType] {
    CollectionType.allCases.filter {
      typeCount($0) > 0 }
  }
  
  func typeCollections(_ type: CollectionType) -> [CollectionItem]? {
    allCollections[type]
  }
  
  func typeCount(_ type: CollectionType) -> Int {
    allCollections[type]?.size ?? 0
  }
  
  func itemCollected(_ image: BeitieImage) -> Bool {
    allCollections[.Beitie]?.contains(where: { $0.collectionId == image.id }) ?? false
  }
  
  
  func itemCollected(_ single: BeitieSingle) -> Bool {
    allCollections[.Single]?.contains(where: { $0.collectionId == single.id }) ?? false
  }
  
  func initCollections() {
    let fetchRequest = CollectionItem.fetchRequest()
    do {
      let result = try managedContext.fetch(fetchRequest)
      let sorted = result.sorted { a, b in
        a.time! > b.time!
      }
      for data in sorted {
        let page = CollectionType(rawValue: data.type!)!
        insertItem(item: data, type: page)
      }
    } catch {
      print("Failed")
    }
  }
  
  func hasSameBefore(id: Int, type: CollectionType) -> CollectionItem? {
    guard let logs = allCollections[type] else { return nil }
    return logs.first(where: { log in
      log.collectionId == id
    })
  }
  
  func insertItem(item: CollectionItem, type: CollectionType) {
    if !allCollections.containsKey(type) {
      allCollections[type] = [item]
    } else {
      allCollections[type]?.insert(item, at: 0)
    }
  }
  func removeItem(item: CollectionItem, type: CollectionType) {
    guard var logs = allCollections[type] else { return }
    logs.removeItem(item)
    allCollections[type] = logs
    do {
      managedContext.delete(item)
      try managedContext.save()
    } catch {
      print("failed refreshLog \(error)")
    }
  }
  
  func toggleItem(_ single: BeitieSingle) {
    if let previous = hasSameBefore(id: single.id, type: .Single) {
      removeItem(item: previous, type: .Single)
      return
    }
    let item = CollectionItem(context: managedContext)
    item.collectionId = Int32(single.id)
    item.type = CollectionType.Single.rawValue
    item.title = single.chars.first().toString()
    item.subTitle = "\(single.work.chineseFolder())"
    item.imageUrl = single.thumbnailUrl
    item.time = Date()
    
    insertItem(item: item, type: .Single)
    do {
      managedContext.insert(item)
      try managedContext.save()
    } catch {
      print("failed refreshLog \(error)")
    }
  }
  
  func toggleItem(_ image: BeitieImage) {
    if let previous = hasSameBefore(id: image.id, type: .Beitie) {
      removeItem(item: previous, type: .Beitie)
      return
    }
    let item = CollectionItem(context: managedContext)
    item.collectionId = Int32(image.id)
    item.type = CollectionType.Beitie.rawValue
    item.title = image.work.chineseFolder()
    item.time = Date()
    item.subTitle = "\(image.index)/\(image.work.imageCount)"
    item.imageUrl = image.url(.JpgCompressedThumbnail)
    
    insertItem(item: item, type: .Beitie)
    do {
      managedContext.insert(item)
      try managedContext.save()
    } catch {
      print("failed refreshLog \(error)")
    }
  }
}

struct CollectionView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel = CollectionViewModel.shared
  @StateObject var naviVM = NavigationViewModel()
  @State private var selectedType = 0
  var types: [CollectionType] {
    viewModel.types
  }
  private let settings = ScrollableBarSettings(
    textColors: [Color.gray, Colors.colorPrimary.swiftColor],
    textFonts: [.system(size: 13.5), .system(size: 14.5, weight: .bold)],
    indicatorHeight: 2.5,
    indicatorColor: Colors.colorPrimary.swiftColor,
    indicatorPadding: 0,
    indicatorTextSpacing: 8,
    tabSpacing: 0,
    alignment: .leading,
    selectAnimation: false,
    extraTabSize: 0,
    buttonStyle: true
  )
  
  var content: some View {
    VStack(spacing: 0) {
      HStack {
        ScrollableTabView(activeIdx: $selectedType, dataSet: types, settings: settings) { i, type in
          HStack(spacing: 0) {
            Text(type.chinese)
            Text("(\(viewModel.typeCount(type)))").font(.footnote)
          }.padding(.horizontal, 15).padding(.top, 15)
            .foregroundStyle(i == selectedType ? Color.darkSlateGray : .gray )
        }
      }.background(Colors.surfaceContainer.swiftColor)
        .frame(maxWidth: .infinity)
      let type = types[selectedType]
      let collections = viewModel.typeCollections(type) ?? []
      
      ScrollView {
        autoColumnLazyGrid(collections, space: 20, parentWidth: UIScreen.currentWidth, maxItemWidth: 60, rowSpace: 10, paddingValues: PaddingValue(horizontal: 10, vertical: 15)) { width, i, item in
          Button {
            if type == CollectionType.Single {
              naviVM.gotoCollectionSingles(collections, i)
            } else {
              naviVM.gotoCollectionWork(Int(item.collectionId))
            }
          } label: {
            VStack {
              Text(item.subTitle ?? "").font(.footnote)
                .foregroundStyle(.gray)
              HStack {
                if let url = item.imageUrl?.url {
                  WebImage(url: url) { img in
                    img.image?.resizable()
                      .aspectRatio(contentMode: .fit)
                      .contentShape(RoundedRectangle(cornerRadius: 2)).clipped().padding(3).overlay {
                        RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                      }
                  }
                }
              }.frame(height: width)
              Text(item.title ?? "")
                .lineLimit(1)
                .font(.callout)
                .foregroundStyle(.darkSlateGray)
            }.frame(width: width)
              .background(.white)
          }.buttonStyle(BgClickableButton())
        }
      }
    }
  }
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "collection".localized)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }.background(Colors.surfaceContainer.swiftColor)
      Divider()
      if types.isEmpty {
        emptyView
      } else {
        content
      }
    }.navigationBarHidden(true)
      .modifier(SingleDestinationModifier(naviVM: naviVM))
      .modifier(WorkDestinationModifier(naviVM: naviVM))
  }
  
  var emptyView: some View {
    VStack {
      Spacer()
      Image(systemName: "circle.slash").resizable().scaledToFit()
        .frame(width: 40, height: 40).foregroundColor(Colors.darkSlateGray.swiftColor)
        .font(.body.weight(.thin))
      Spacer.height(20)
      Text("你没有收藏".orCht("你沒有收藏")).font(.body).foregroundColor(Colors.darkSlateGray.swiftColor)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
      Spacer()
    }
  }
}


#Preview {
  CollectionView()
}
