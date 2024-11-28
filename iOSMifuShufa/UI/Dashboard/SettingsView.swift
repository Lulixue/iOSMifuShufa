//
//  SettingsView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/13.
//
import SwiftUI
import Foundation

enum SettingsItem: String, CaseIterable {
  case Home
  case SingleRotate
  case Beitie
  case Language
  case Jizi
  
  var key: String { "\(self)SettingsKey" }
  
  static var languageOption: ChineseVersion {
    get { ChineseVersion(rawValue: Settings.getString(Language.key, ChineseVersion.Unspecified.toString()))! }
    set {
      Settings.putString(Language.key, newValue.toString())
    }
  }
    
  static var jiziCandidateEnable: Boolean {
    get { Settings.getBoolean(Jizi.key, true) }
    set {
      Settings.putBoolean(Jizi.key, newValue)
    }
  }
}


enum SettingRow: CaseIterable {
  case Language, Rotation, Beitie, Jizi
  
  var chinese: String {
    switch self {
    case .Language:
      "ui_language".localized
    case .Beitie:
      "title_beitie".localized
    case .Jizi:
      "title_jizi".localized
    case .Rotation:
      "single_rotate".localized
    }
  }
  
  var icon: String {
    switch self {
    case .Language:
      "chinese_language"
    case .Beitie:
      "work"
    case .Jizi:
      "jizi"
    case .Rotation:
      "rotate"
    }
  }
  
}

private struct BeitieSettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  
  @State private var singleOriginal = AnalyzeHelper.singleOriginal {
    didSet {
      AnalyzeHelper.singleOriginal = singleOriginal
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "title_beitie".localized + "settings".localized)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }
      Divider()
      ScrollView {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            NavigationLink(destination: {
              BeitieSingleSettingsView()
            }) {
              SettingItemView(icon: "", title: "单字范围".orCht("單字範圍"))
                .padding(.leading, 5)
            }
            Divider().padding(.leading, 15)
            Button {
              singleOriginal.toggle()
            } label: {
              HStack {
                Text("使用单字原图".orCht("使用單字原圖")).foregroundStyle(Color.darkSlateGray)
                Spacer()
                Toggle(isOn: $singleOriginal) {
                  
                }
              }.padding(.vertical, 8).padding(.horizontal, 15)
                .background(.white)
            }.buttonStyle(BgClickableButton())
          }.background(.white)
          HStack {
            Text(
              "从碑帖获取单字截图后，为了便于识别和使用，对图片的干扰部分进行了处理，开启则使用未处理原图"
                .orCht("從碑帖獲取單字截圖後，為了便於識別和使用，對圖片的干擾部分進行了處理，開啓則使用未處理原圖"))
            .font(.footnote).foregroundStyle(.gray)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 15).padding(.top, 8)
            Spacer()
          }
        }
      }.background(Colors.wx_background.swiftColor)
    }
  }
  
}


private struct BeitieSingleSettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel = CurrentUser
  @State private var canJiziWorks = [BeitieWork: Bool]()
  @State private var canSearchWorks = [BeitieWork: Bool]()
  @State private var collapsed = [AnyHashable: Bool]()
  private let elements: [(AnyHashable, List<List<BeitieWork>>)]
  
  init() {
    var all = [(AnyHashable, List<List<BeitieWork>>)]()
    let items = Array(BeitieDbHelper.shared.getDefaultTypeWorks(false).elements.filter { elem in
      elem.value.hasAny { $0.first().hasSingle() }
    })
    var canJiziWorks = [BeitieWork: Bool]()
    var canSearchWorks = [BeitieWork: Bool]()
    var collapsed = [AnyHashable: Bool]()
    for (k, v) in items {
      let filtered = v.filter { $0.first().hasSingle() }
      all.add((k, filtered))
      for works in filtered {
        let work = works.first()
        canJiziWorks[work] = work.canJizi
        canSearchWorks[work] = work.canSearch
      }
      collapsed[k] = false
    }
    self.collapsed = collapsed
    self.elements = all
    self.canJiziWorks = canJiziWorks
    self.canSearchWorks = canSearchWorks
  }
  
  func workJiziBinding(_ work: BeitieWork) -> Binding<Bool> {
    Binding {
      self.canJiziWorks[work] ?? work.canJizi
    } set: {
      if work.vip && !CurrentUser.isVip {
        self.viewModel.showConstraintVip("当前碑帖不支持设置，请联系客服".orCht("當前碑帖不支持設置，請聯繫客服"))
      } else {
        self.canJiziWorks[work] = $0
        work.canJizi = $0
      }
    }
  }
  
  func workSearchBinding(_ work: BeitieWork) -> Binding<Bool> {
    Binding {
      self.canSearchWorks[work] ?? work.canSearch
    } set: {
      if work.vip && !CurrentUser.isVip {
        self.viewModel.showConstraintVip("当前碑帖不支持设置，请联系客服".orCht("當前碑帖不支持設置，請聯繫客服"))
        return
      }
      self.canSearchWorks[work] = $0
      work.canSearch = $0
    }
  }
  @State private var showOverflow = false
  var body: some View {
    ZStack(alignment: .topTrailing) {
      contents
      if showOverflow {
        Button {
          showOverflow = false
          resetDefault()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "arrow.clockwise").square(size: 12)
            Text("reset_default".resString).font(.system(size: 15))
          }.padding(.horizontal, 10).padding(.vertical, 7).background(.white).clipShape(RoundedRectangle(cornerRadius: 5))
            .background {
              RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 0.5)
            }.foregroundStyle(.blue)
        }.buttonStyle(BgClickableButton()).offset(x: -10, y: CUSTOM_NAVIGATION_HEIGHT-5)
      }
    }.simultaneousGesture(TapGesture().onEnded({ _ in
      showOverflow = false
    }), isEnabled: showOverflow)
    .simultaneousGesture(DragGesture().onEnded({ _ in
      showOverflow = false
    }), isEnabled: showOverflow)
  }
  
  private func resetDefault() {
    for (_, v) in elements {
      for works in v {
        let work = works.first()
        canJiziWorks[work] = true
        canSearchWorks[work] = true
        work.canJizi = true
        work.canSearch = true
      }
    }
  }
  
  var contents: some View {
    VStack(spacing: 0) {
      NaviView {
        NaviContents(title: "单字范围设置".orCht("單字範圍設置")) {
          BackButtonView {
            presentationMode.wrappedValue.dismiss()
          }
        } trailing: {
          Button {
            showOverflow = true
          } label: {
            Image(systemName: "ellipsis.circle").square(size: CUSTOM_NAVI_ICON_SIZE)
              .foregroundStyle(Color.colorPrimary)
          }
        }
      }.background(Colors.surfaceVariant.swiftColor)
      Divider()
      ScrollView {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
          ForEach(0..<elements.size, id: \.self ) { i in
            let elem = elements[i]
            let works = elem.1
            let binding = Binding {
              self.collapsed[elem.0] ?? false
            } set: {
              self.collapsed[elem.0] = $0
            }
            Section {
              if !binding.wrappedValue {
                VStack(spacing: 0) {
                  ForEach(0..<works.size, id: \.self) { j in
                    HStack(spacing: 6) {
                      let first = works[j].first()
                      VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                          Text(first.chineseName())
                            .foregroundStyle(Color.darkSlateGray)
                          if first.chineseVersion()?.isNotEmpty() == true {
                            Text(first.chineseVersion()!).font(.footnote)
                              .foregroundStyle(Color.darkSlateBlue)
                          }
                          if first.vip {
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
                      HStack(spacing: 0) {
                        Toggle(isOn: workSearchBinding(first)) {
                          Text("search".localized).font(.footnote).foregroundStyle(Colors.iconColor(0))
                        }.toggleStyle(CheckboxStyle(iconSize: 15, leadingSpacing: 4, iconColor: Colors.iconColor(0)))
                        0.5.VDivideer(color: .gray.opacity(0.35)).frame(height: 14).padding(.horizontal, 5)
                        Toggle(isOn: workJiziBinding(first)) {
                          Text("title_jizi".localized).font(.footnote).foregroundStyle(Colors.iconColor(1))
                        }.toggleStyle(CheckboxStyle(iconSize: 15, leadingSpacing: 4, iconColor: Colors.iconColor(1)))
                      }
                    }.padding(.horizontal, 10).padding(.vertical, 6)
                    if j != works.lastIndex {
                      Divider().padding(.leading, 10)
                    }
                  }
                }.padding(.vertical, 6)
              }
            } header: {
              Button {
                binding.wrappedValue.toggle()
              } label: {
                VStack(spacing: 0) {
                  HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(keyToString(key: elem.0)).frame(alignment: .leading)
                      .foregroundColor(Colors.searchHeader.swiftColor)
                      .font(.system(size: 15))
                    Text("(\(works.size))").font(.footnote).foregroundColor(Colors.searchHeader.swiftColor)
                    Spacer()
                    Image(systemName: "chevron.down")
                      .square(size: 10).foregroundStyle(UIColor.lightGray.swiftColor)
                      .rotationEffect(.degrees(!binding.wrappedValue ? -90 : 0))
                  }.padding(.leading, 10)
                    .padding(.trailing, 10)
                    .padding(.vertical, 8).background(Colors.surfaceVariant.swiftColor)
                  if binding.wrappedValue {
                    Divider.overlayColor(Color.gray.opacity(0.35))
                  }
                }
              }.buttonStyle(BgClickableButton())
            }
          }
        }
      }
    }.onDisappear {
      BeitieDbHelper.shared.syncWorkRanges()
    }
    .navigationBarHidden(true)
  }
}

private struct RotationView: View {
  @Environment(\.presentationMode) var presentationMode
  @State var version = Settings.languageVersion
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "ui_language".localized)
        Spacer()
        Button {
        } label: {
          Text("保存").font(.footnote)
        }.buttonStyle(PrimaryButton(bgColor: Colors.colorAccent.swiftColor))
      }
      Divider()
      ScrollView {
        VStack(spacing: 0) {
          let cases = ChineseVersion.allCases
          ForEach(0..<cases.size, id: \.self) { i in
            let c = cases[i]
            Button {
              version = c
            } label: {
              HStack {
                Text(c.name)
                Spacer()
                if c == version {
                  Image(systemName: "checkmark")
                    .foregroundStyle(Color.colorPrimary)
                }
              }.padding(.vertical, 15).padding(.horizontal, 15)
                .background(.white)
            }.buttonStyle(BgClickableButton())
            if c != cases.last {
              Divider().padding(.leading, 15)
            }
          }
        }.background(.white)
      }.background(Colors.wx_background.swiftColor)
    }
  }
}

struct LanguageView: View {
  @Environment(\.presentationMode) var presentationMode
  @State var version = Settings.languageVersion
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "ui_language".localized)
        Spacer()
        Button {
          if version != Settings.languageVersion {
            Settings._languageVersion = version
            presentationMode.wrappedValue.dismiss()
            CurrentUser.language = Settings.languageVersion
          }
        } label: {
          Text("保存").font(.footnote)
        }.buttonStyle(PrimaryButton(bgColor: Colors.colorAccent.swiftColor))
      }
      Divider()
      ScrollView {
        VStack(spacing: 0) {
          let cases = ChineseVersion.allCases
          ForEach(0..<cases.size, id: \.self) { i in
            let c = cases[i]
            Button {
              version = c
            } label: {
              HStack {
                Text(c.name)
                Spacer()
                if c == version {
                  Image(systemName: "checkmark")
                    .foregroundStyle(Color.colorPrimary)
                }
              }.padding(.vertical, 15).padding(.horizontal, 15)
                .background(.white)
            }.buttonStyle(BgClickableButton())
            if c != cases.last {
              Divider().padding(.leading, 15)
            }
          }
        }.background(.white)
      }.background(Colors.wx_background.swiftColor)
    }
  }
}

struct SubSettingsView: View {
  let settingsRow: SettingRow
  
  var body: some View {
    VStack(spacing: 0) {
      switch settingsRow {
      case .Language:
        LanguageView()
      case .Rotation:
        RotationSettingsView()
      case .Beitie:
        BeitieSettingsView()
      case .Jizi:
        JiziSettingsView()
      }
    }.navigationBarHidden(true)
  }
}

struct SettingItemView: View {
  let icon: String
  let title: String
  var value: String = ""
  var iconSize: CGFloat = 20
  var color: Color = Colors.iconColor(0)
  var body: some View {
    HStack {
      if icon.isNotEmpty() {
        ZStack {
          Image(icon).renderingMode(.template)
            .square(size: iconSize).foregroundStyle(color)
        }.frame(width: 24, height: 24)
      }
      Text(title).foregroundStyle(Color.darkSlateGray)
      Spacer()
      if value.isNotEmpty() {
        Text(value).font(.footnote).foregroundStyle(.gray)
      }
      Image(systemName: "chevron.right")
        .foregroundStyle(.gray)
    }.padding(.vertical, 13).padding(.leading, 10)
      .padding(.trailing, 15)
      .background(.white)
  }
}

struct SettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  @StateObject var viewModel = CurrentUser
  var body: some View {
    NavigationStack {
      contents
    }
  }
  
  var contents: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "settings".localized)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }
      Divider()
      ScrollView {
        LazyVStack(spacing: 0) {
          let cases = SettingRow.allCases
          ForEach(0..<cases.size, id: \.self) { i in
            let c = cases[i]
            NavigationLink(destination: SubSettingsView(settingsRow: c)) {
              SettingItemView(icon: c.icon, title: c.chinese, color: Colors.iconColor(i))
            }.buttonStyle(BgClickableButton())
            if i != cases.lastIndex {
              Divider().padding(.leading, 15)
            }
          }
        }.background(.white)
      }.background(Colors.wx_background.swiftColor)
        .id(viewModel.language)
    }.navigationBarHidden(true)
  }
}

struct RotationSettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  
  @State private var singleRotation = AnalyzeHelper.singleRotate {
    didSet {
      AnalyzeHelper.singleRotate = singleRotation
    }
  }
  
  @State private var homeRotation = AnalyzeHelper.homeRotate {
    didSet {
      AnalyzeHelper.homeRotate = homeRotation
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "title_jizi".localized + "settings".localized)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }
      Divider()
      ScrollView {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            Button {
              homeRotation.toggle()
            } label: {
              HStack {
                Text("首页单字旋转".orCht("首頁單字旋轉")).foregroundStyle(Color.darkSlateGray)
                Spacer()
                Toggle(isOn: $homeRotation) {
                  
                }
              }.padding(.vertical, 8).padding(.horizontal, 15)
                .background(.white)
            }.buttonStyle(BgClickableButton())
            Divider().padding(.leading, 15)
            Button {
              singleRotation.toggle()
            } label: {
              HStack {
                Text("单字页面旋转".orCht("單字頁面旋轉")).foregroundStyle(Color.darkSlateGray)
                Spacer()
                Toggle(isOn: $singleRotation) {
                  
                }
              }.padding(.vertical, 8).padding(.horizontal, 15)
                .background(.white)
            }.buttonStyle(BgClickableButton())
          }
          HStack {
            let chs = "当手机旋转时，如果方向没有锁定，开启则单字跟随旋转。"
            let cht = "當手機旋轉時，如果方向沒有鎖定，開啓則單字跟隨旋轉。"
            Text(chs.orCht(cht))
              .font(.footnote).foregroundStyle(.gray)
              .multilineTextAlignment(.leading)
              .padding(.horizontal, 15).padding(.top, 8)
            Spacer()
          }
        }
      }.background(Colors.wx_background.swiftColor)
    }
  }
}

#Preview {
  SettingsView()
}

#Preview("language") {
  LanguageView()
}

#Preview("beitie") {
  BeitieSettingsView()
}
 
#Preview("jizi") {
  JiziSettingsView()
}

#Preview("rotate") {
  RotationSettingsView()
}

struct JiziSettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  
  @State private var jiziCandidate = SettingsItem.jiziCandidateEnable {
    didSet {
      SettingsItem.jiziCandidateEnable = jiziCandidate
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: "title_jizi".localized + "settings".localized)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }
      Divider()
      ScrollView {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            Button {
              jiziCandidate.toggle()
            } label: {
              HStack {
                Text("jizi_candidate".localized).foregroundStyle(Color.darkSlateGray)
                Spacer()
                Toggle(isOn: $jiziCandidate) {
                  
                }
              }.padding(.vertical, 8).padding(.horizontal, 15)
                .background(.white)
            }.buttonStyle(BgClickableButton())
          }.background(.white)
          HStack {
            let chs = """
  当集字找不到单字图片时，可对字进行部件拆解，获取含有本身和部件的单字作为参考和候补。如「楚」字，如无单字结果，搜索含有本身「楚」和部件「林」和「疋」的单字作为候补，如「礎」、「禁」、「胥」等。
  """
            let cht = """
  當集字找不到單字圖片時，可對字進行部件拆解，獲取含有本身和部件的單字作爲參考和候補。如「楚」字，如無單字結果，搜索含有本身「楚」和部件「林」和「疋」的單字作爲候補，如「礎」、「禁」、「胥」等。
  """
            Text(chs.orCht(cht))
            .font(.footnote).foregroundStyle(.gray)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 15).padding(.top, 8)
            Spacer()
          }
        }
      }.background(Colors.wx_background.swiftColor)
    }
  }
  
}
