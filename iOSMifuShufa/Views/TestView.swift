//
//  TestView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/6.
//

import SwiftUI

struct TestView: View {
  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0
  private let maxZoom = 5.0
  private let minZoom = 0.3
  @State private var offsetX = 0.0
  @State private var offsetY = 0.0
  
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
      ProgressView().progressViewStyle(.circular).tint(.red)
        .font(.title)
        .scaleEffect(2)
    }
  }
  
  var stackView: some View {
    NavigationStack {
      ZStack(alignment: .topTrailing) {
        VStack {
          NavigationLink(isActive: $enabled) {
            Text("call")
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
            
            
              //            .gesture(DragGesture().onChanged({ drag in
              //              let offsetX = drag.translation.width
              //              let offsetY = drag.translation.height
              //              printlnDbg("offset: \(offsetX) \(offsetY)")
              //            }).onEnded({ drag in
              //
              //            }))
              //            .onAppear {
              //
              //            }
          }
        }.padding(10)
      }
    }
  }
}

#Preview {
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
