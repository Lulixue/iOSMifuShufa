//
//  RecommendView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2025/4/19.
//
import SwiftUI
import SDWebImageSwiftUI

class LixueApp: Decodable {
  var name: String = ""
  var nameCht: String = ""
  var desc: String = ""
  var icon: String = ""
  var appId: String = ""
  
  enum CodingKeys: CodingKey {
    case name
    case nameCht
    case desc
    case icon
    case appId
  }
  
  func chineseName() -> String {
    name.orCht(nameCht)
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.nameCht = try container.decode(String.self, forKey: .nameCht)
    self.desc = try container.decode(String.self, forKey: .desc)
    self.icon = try container.decode(String.self, forKey: .icon)
    self.appId = try container.decode(String.self, forKey: .appId)
  }
}

class RecommendViewModel: BaseObservableObject {
  static let APPS = [LixueApp]()
  @Published var apps = [LixueApp]()
  override init() {
    super.init()
    if (Self.APPS.isNotEmpty()) {
      apps = Self.APPS
    } else {
      Task {
        NetworkHelper.getApps { apps in
          DispatchQueue.main.async {
            self.apps = apps
          }
        }
      }
    }
  }
}

struct RecommendView : View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var viewModel = RecommendViewModel()
  
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        NaviContents(title: "app_recommend".resString) {
          BackButtonView {
            presentationMode.wrappedValue.dismiss()
          }
        } trailing: {
          
        }
      }.background(Colors.background.swiftColor)
      Divider()
      ScrollView {
        LazyVStack {
          let apps = viewModel.apps.filter { $0.appId != APP_ID }
          ForEach(0..<apps.size, id: \.self) { i in
            let app = apps[i]
            Section {
              Button {
                Utils.gotoAppInStore(app.appId)
              } label: {
                VStack(alignment: .leading, spacing: 6) {
                  HStack {
                    WebImage(url: app.icon.url) { img in
                      img.image?.resizable()
                        .scaledToFill()
                        .frame(width: 26, height: 26)
                        .viewShape(Circle())
                        .clipShape(Circle())
                    }
                    Text(app.chineseName())
                        .foregroundStyle(Colors.iconColor(i))
                        .font(.title3)
                        .fontWeight(.regular)
                    Spacer()
                  }
                  Text(app.desc).font(.footnote).foregroundStyle(.defaultText).multilineTextAlignment(.leading)
                }.padding(.top, i == 0 ? 10 : 5).padding(.bottom, 6).padding(.horizontal, 15)
              }.buttonStyle(.plain)
            } footer: {
              if i != apps.lastIndex {
                Divider().padding(.leading, 15)
              }
            }
          }
        }
      }
    }.navigationBarBackButtonHidden()
  }
}


#Preview {
  RecommendView()
}
