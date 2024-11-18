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
  
  var name: String {
    rawValue.localized
  }
  var extraSize: [CGFloat] {
    switch self {
    case .update: return [-2, -2]
    case .feedback: return [-1, -1]
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
    default: return Image(systemName: "star")
    }
  }
  
  var subText: String {
    switch (self) {
    case .vip:
      return CurrentUser.userVipStatus
    case .update:
      return CurrentUser.updateStatus
    default:
      return ""
    }
  }
}

private let ITEM_BG_COLOR = Color.white
private let BASE_NAVIGATION_BAR_COLOR = UIColor.systemGray4.swiftColor

struct DashboardDivider: View {
  var body: some View {
    Divider().overlay(UIColor.systemGray5.swiftColor)
  }
}

struct DashboardItemView: View {
  let row: DashboardRow
  @ViewBuilder var content: some View {
    let verticalPadding: CGFloat = row == .vip ? 15 : 12
    let extraSize = row.extraSize
    HStack(alignment: .center, spacing: 0) {
      ZStack(alignment: .center) {
        row.image
          .renderingMode(.template)
          .resizable()
          .scaledToFill()
          .foregroundColor(Colors.darkSlateGray.swiftColor)
          .frame(width: 18+extraSize[0], height: 18+extraSize[1])
      }.frame(width: 24, height: 24)
      Spacer.width(10)
      Text(row.rawValue.interfaceStr)
        .font(.system(size: 18))
        .foregroundColor(.black)
      Spacer()
      Text(row.subText).font(.callout)
        .foregroundColor(Color.gray)
      Spacer().frame(width: 12)
      Image(systemName: "chevron.right")
        .resizable()
        .scaledToFit()
        .foregroundColor(.gray)
        .frame(width: 7)
    }.padding(EdgeInsets(top: verticalPadding, leading: 12, bottom: verticalPadding, trailing: 16)).background(ITEM_BG_COLOR)
  }
  
  var body: some View {
    content
  }
}

struct UserItemView: View {
  @StateObject var viewModel: UserViewModel = CurrentUser
  var onClick: () -> Void = { }
  var body: some View {
    Button {
      onClick()
    } label: {
      HStack(alignment: .center) {
        Spacer().frame(width: 5)
        Image(CurrentUser.userLogin ? "login_user" : "default_user")
          .renderingMode(.original)
          .square(size: 45)
          .foregroundColor(Color(UIColor.gray))
        Spacer().frame(width: 15)
        VStack(alignment: .leading) {
          Text("\(viewModel.userName)").font(.system(size: 17)).foregroundColor(.black)
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
  }
}


struct DashboardPage : View {
  let middleItems: [DashboardRow] = [.about, .rate, .update, .feedback]
  var body: some View {
    NavigationStack {
      contents
    }
  }
  
  @ViewBuilder func destinationView(_ row: DashboardRow) -> some View {
    switch row {
    case .about:
      AboutView()
    default:
      EmptyView()
    }
  }
  
  var itemDivider: some View {
    
    HStack(spacing: 0) {
      GeometryReader { geometry in
        Divider().padding(.leading, 46)
      }
    }.background(ITEM_BG_COLOR).padding(EdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(width: UIScreen.currentWidth, height: 1)
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
            UserItemView() {
            }
          }
          15.VSpacer()
          Group {
            DashboardDivider()
            NavigationLink(destination: EmptyView()) {
              DashboardItemView(row: .collection)
            }.buttonStyle(BgClickableButton())
            DashboardDivider()
          }.background(.white)
          15.VSpacer()
          Group {
            DashboardDivider()
            ForEach(middleItems, id:\.self) { row in
              NavigationLink(destination: {
                destinationView(row)
              }) {
                DashboardItemView(row: row)
              }.buttonStyle(BgClickableButton())
              if row != middleItems.last {
                Divider().padding(.leading, 46)
              }
            }
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
    }.navigationBarHidden(true)
      
  }
}

#Preview {
  DashboardPage()
}
