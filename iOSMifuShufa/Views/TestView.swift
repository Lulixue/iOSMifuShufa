//
//  TestView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/6.
//

import SwiftUI


struct VipBackground: View {
  let color = UIColor.init(argb: 0xFFFFA500)
  let size = "VIP".calculateUITextViewFreeSize(font: .preferredFont(forTextStyle: .footnote))
  let maxSize: CGFloat = 36
  
  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let height = geometry.size.height
      let vipBgWidth = min(width/2, maxSize)
      let vipBgHeight = min(height/2, maxSize)
      ZStack(alignment: .topLeading) {
        Path { path in
          path.moveTo(0, 0)
          path.lineTo(0, vipBgHeight)
          path.lineTo(vipBgWidth, 0)
          path.lineTo(0, 0)
        }
        .fill(color.swiftColor)
        let font = (size.width > (vipBgWidth*0.7)) ? Font.system(size: 6) : Font.footnote
        let percent = (size.width > (vipBgWidth*0.7)) ? 1.1 : 0.7
        Text("VIP").font(font).foregroundStyle(.white)
          .rotationEffect(.degrees(-45))
          .padding(.leading, max((vipBgWidth*percent-size.width)/2, 0))
          .padding(.top, max((vipBgHeight*percent-size.height)/2, 0))
        
      }
    }
    .aspectRatio(1, contentMode: .fit)
  }
}

#Preview {
  ZStack(alignment: .topLeading) {
    VipBackground()
  }.frame(width: 100, height: 100)
}

struct TestView: View {
  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0
  private let maxZoom = 5.0
  private let minZoom = 0.3
  @State private var offsetX = 0.0
  @State private var offsetY = 0.0
  @StateObject var alert = AlertViewModel()
  
  init() {
    let maxWidth = UIScreen.currentWidth - 20
    if maxWidth < imageSize.width {
      self.totalZoom = imageSize.width / maxWidth
    }
  }
  
  let imageSize = {
    let img = UIImage(named: "background")!
    let size = img.size
    return size
  }()
  
  @State var enabled = false
  var body: some View {
    ZStack {
      Color.white
      ScrollView {
        Spacer()
      }.background {
      }.padding()
      VipBackground()
      ProgressView().progressViewStyle(.circular).tint(.red)
        .font(.title)
        .scaleEffect(2)
//      stackView
      
    }
  }
  
  var stackView: some View {
    NavigationStack {
      ZStack(alignment: .topTrailing) {
        VStack {
          Button {
            alert.showFullAlert("hello", "this is the message", okTitle: "ok", okRole: .destructive, cancel:  {
              println("ok")
            })
          } label: {
            Image("background")
              .resizable()
              .scaleEffect(currentZoom + totalZoom)
              .scaledToFit()
              .padding(10)
              .gesture(MagnificationGesture().onChanged({ offset in
                println("offset \(offset)")
                currentZoom = offset - 1
              }).onEnded({ offset in
                totalZoom = max(min(totalZoom + currentZoom, maxZoom), minZoom)
                currentZoom = 0
              }))
          }.buttonStyle(.plain)
        }.padding(10)
      }.alert(alert.fullAlertTitle, isPresented: $alert.showFullAlert) {
        Button(alert.fullAlertOkTitle, role: alert.okButtonRole) {
          alert.fullAlertOk()
        }
        if let cancel = alert.fullAlertCancelTitle {
          Button(cancel, role: alert.cancelButtonRole) {
            alert.fullAlertCancle()
          }
        }
      } message: {
        if let msg = alert.fullAlertMsg {
          Text(msg)
        }
      }

    }
  }
}

#Preview("first") {
  TestView()
}

import SwiftUI
import Combine

  // MARK: This class will help you to navigate more easily
final class Router: ObservableObject {
    // Add the views you need to control
  public enum Destination: Codable, Hashable {
    case page2View
    case page3View
  }
  
  @Published var path = NavigationPath()
  
  func navigate(to destination: Destination) {
    path.append(destination)
  }
  
  func navigateBack() {
    path.removeLast()
  }
  
  func navigateToRoot() {
    path.removeLast(path.count)
  }
}

struct TestContentView: View {
  @ObservedObject var router = Router()
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack(path: $router.path) {
        // Wrap your main view inside a NavigationStack
      VStack {
        Text("1")
        NavigationLink(value: Router.Destination.page2View) {
          Text("View Page 2")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .onDisappear {
              dismiss()
            }
        }
        .padding()
        
        
      }
      .navigationBarTitle("Main Page")
      .navigationDestination(for: Router.Destination.self) { destination in
          // Handle navigation here
        
        switch destination {
        case .page2View: Page2View()
        case .page3View: Page3View()
        }
      }
      
    }.environmentObject(router)
  }
}

struct Page2View: View {
  @EnvironmentObject var router: Router
  
  var body: some View {
    VStack {
      Text("This is Page 2")
      
      Button(action: {
        router.navigateBack() // Pops the current view
      }, label: {
        Text("Remove View 2 and Show View 3")
      })
    }
    .navigationBarTitle("Page 2")
    .onDisappear(perform: {
      router.navigate(to: .page3View) // Navigates to another view
    })
  }
}

struct Page3View: View {
  var body: some View {
    Text("This is Page 3")
      .navigationBarTitle("Page 3")
  }
}


#Preview {
  TestContentView()
}


struct TestImage: View {
  let size: CGFloat = 200
  var body: some View {
    ZStack {
      Color.gray
      
      Image("background")
        .resizable()
        .scaledToFill()
        .frame(width: size)
        .frame(height: size)
        .clipped()
          
      Button {
        
      } label: {
        VStack {
        }.squareFrame(size).background {
          RoundedRectangle(cornerRadius: 5).stroke(.white, lineWidth: 1)
        }
      }
    }
  }
}

#Preview("TestImage") {
  TestImage()
}

func globalTest() {
//  let image = UIImage(named: "background")
//  image?.addWaterMark("app_name".resString)
}
