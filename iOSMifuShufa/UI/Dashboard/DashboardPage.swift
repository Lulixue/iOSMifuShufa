//
//  DashboardPage.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/13.
//
import SwiftUI


enum DashboardRow: String, CaseIterable, Identifiable {
  var id : String { UUID().uuidString }
  case vip = "vip_service"
  case user = "user"
  case collection = "collection"
  case about = "about_Mifu"
  case rate = "rate_app"
  case update = "check_update"
  case feedback = "feedback"
  case settings = "general_settings"
  case sync = "cloud_sync"
  case recommend = "app_recommend"
  
  var name: String {
    rawValue.localized
  }
  var extraSize: [CGFloat] {
    switch self {
    case .update: return [-2, -2]
    case .feedback: return [1, 1]
    case .settings: return [2, 2]
    case .collection: return [-2.5, -2.5]
    case .rate: return [1, 1]
    case .sync: return [1, 1]
    default: return [0, 0]
    }
  }
}

extension DashboardRow {
  var image: Image {
    switch (self) {
    case .sync: return Image("cloud_sync")
    case .about: return Image(systemName: "info.circle")
    case .rate: return Image(systemName: "star")
    case .update: return  Image(systemName: "square.and.arrow.up")
    case .feedback: return Image(systemName: "square.and.pencil")
    case .collection: return Image(systemName: "suit.heart")
    case .settings: return Image(systemName: "hammer")
    case .vip: return Image(systemName: "v.circle")
    case .recommend: return Image(systemName: "hand.thumbsup")
    default: return Image(systemName: "star")
    }
  }
  
}

private let ITEM_BG_COLOR = Color.white
private let BASE_NAVIGATION_BAR_COLOR = UIColor.systemGray4.swiftColor
let DASH_FONT: Font = .system(size: 18.5)
let SETTINGS_FONT: Font = .system(size: 17.5)

struct DashboardDivider: View {
  var body: some View {
    Divider().overlay(UIColor.systemGray5.swiftColor)
  }
}
 
struct DashboardPage : View {
  let middleItems: [DashboardRow] = [.about, .rate, .update, .feedback]
  var body: some View {
    NavigationStack {
      contents
    }
  }
  @StateObject var viewModel: UserViewModel = CurrentUser
  
  @ViewBuilder
  func DashboardItemView(row: DashboardRow, subText: @escaping () -> String = { "" }) -> some View {
    let verticalPadding: CGFloat = row == .vip ? 15 : 15
    let extraSize = row.extraSize
    let baseSize: CGFloat = 19
    HStack(alignment: .center, spacing: 0) {
      ZStack(alignment: .center) {
        row.image
          .renderingMode(.template)
          .resizable()
          .scaledToFill()
          .foregroundColor(Colors.darkSlateGray.swiftColor)
          .frame(width: baseSize+extraSize[0], height: baseSize+extraSize[1])
      }.frame(width: 24, height: 24)
      Spacer.width(10)
      Text(row.rawValue.interfaceStr)
        .font(DASH_FONT)
        .foregroundColor(Color.darkSlateGray)
      Spacer()
      Text(subText()).font(.callout)
        .foregroundColor(Color.gray)
      Spacer().frame(width: 12)
      Image(systemName: "chevron.right")
        .resizable()
        .scaledToFit()
        .foregroundColor(.gray)
        .frame(width: 7)
    }.padding(EdgeInsets(top: verticalPadding, leading: 12, bottom: verticalPadding, trailing: 16)).background(ITEM_BG_COLOR)
  }
  
  var itemDivider: some View {
    
    HStack(spacing: 0) {
      GeometryReader { geometry in
        Divider().padding(.leading, 46)
      }
    }.background(ITEM_BG_COLOR).padding(EdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(width: UIScreen.currentWidth, height: 1)
  }
  
  var userItemView: some View {
    HStack(alignment: .center) {
      Spacer().frame(width: 5)
      Image(CurrentUser.userLogin ? "login_user" : "default_user")
        .renderingMode(.original)
        .square(size: 45)
        .foregroundColor(Color(UIColor.gray))
      Spacer().frame(width: 15)
      VStack(alignment: .leading) {
        Text("\(viewModel.userName)").font(.system(size: 17))
          .foregroundColor(Color.darkSlateGray)
        if CurrentUser.userLogin {
          Spacer().frame(height: 5)
          Text("\(viewModel.userType)")
            .font(.system(size: 14)).foregroundColor(.secondary)
        }
      }
      Spacer()
      Image(systemName: "chevron.right")
        .resizable()
        .scaledToFit()
        .foregroundColor(.gray)
        .frame(width: 8)
    }.padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 16)).background(ITEM_BG_COLOR)
  }
   
  @State private var clickedRow: DashboardRow? = nil
  var contents: some View {
    VStack(spacing: 0) {
      NaviView {
        Spacer()
        NaviTitle(text: "user_center".localized)
        Spacer()
      }
      Divider()
      ScrollView {
        VStack(spacing: 0) {
          Group {
            if CurrentUser.userLogin {
              NavigationLink {
                UserView()
              } label: {
                userItemView
              }.buttonStyle(BgClickableButton())
            } else {
              NavigationLink {
                LoginView()
              } label: {
                userItemView
              }.buttonStyle(BgClickableButton())
            }
            DashboardDivider()
            NavigationLink {
              VipPackagesView() 
            } label: {
              DashboardItemView(row: .vip) {
                CurrentUser.userVipStatus
              }
            }
          }
          15.VSpacer()
          Group {
            DashboardDivider()
            NavigationLink(destination: {
              CollectionView()
            }) {
              DashboardItemView(row: .collection)
            }.buttonStyle(BgClickableButton())
            DashboardDivider()
          }.background(.white)
          15.VSpacer()
          Group {
            DashboardDivider()
            NavigationLink(destination: {
              AboutView()
            }) {
              DashboardItemView(row: .about)
            }.buttonStyle(BgClickableButton())
            Divider().padding(.leading, 46)
            Button {
              viewModel.rateApp()
            } label: {
              DashboardItemView(row: .rate)
            }.buttonStyle(BgClickableButton())
            Divider().padding(.leading, 46)
            Button {
              viewModel.checkUpdate()
            } label: {
              DashboardItemView(row: .update) {
                CurrentUser.updateStatus
              }
            }.buttonStyle(BgClickableButton())
            Divider().padding(.leading, 46)
            NavigationLink {
              FeedbackView()
            } label: {
              DashboardItemView(row: .feedback)
            }.buttonStyle(BgClickableButton())
            Divider().padding(.leading, 46)
            NavigationLink {
              RecommendView()
            } label: {
              DashboardItemView(row: .recommend)
            }.buttonStyle(BgClickableButton())
            DashboardDivider()
          }.background(.white)
          Spacer().frame(height: 15)
          Group {
            DashboardDivider()
            NavigationLink(destination: SettingsView()) {
              DashboardItemView(row: .settings)
            }.buttonStyle(BgClickableButton())
            DashboardDivider()
          }
        }
      }.background(Colors.wx_background.swiftColor)
        .modifier(AlertViewModifier(viewModel: viewModel))
        .id(viewModel.language)
    }.navigationBarHidden(true)
  }
}

public struct LazyView<Content: View>: View {
    let build: () -> Content
    public init(_ build: @escaping () -> Content) {
        self.build = build
    }
    public var body: Content {
        build()
    }
}
#Preview {
  DashboardPage()
}
