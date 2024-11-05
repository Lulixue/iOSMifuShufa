//
//  ContentView.swift
//  SideMenu
//
//  Created by Vidhyadharan Mohanram on 11/06/19.
//  Copyright © 2019 Vid. All rights reserved.
//

import SwiftUI

public class SideMenuViewModel: BaseObservableObject {
  @Published var sideMenuLeftPanel = false
  @Published var sideMenuRightPanel = false
  public override init() {
    super.init()
    #if DEBUG
//    sideMenuLeftPanel = true
    #endif
  }
}

public struct SideMenu<CenterView: View> : View {
  
  //  MARK: Custom initializers
  @ViewBuilder var centerViewBuilder: () -> CenterView
  public init<Menu: View>(leftMenu: Menu,
                          @ViewBuilder centerView: @escaping () -> CenterView,
                                            viewModel: SideMenuViewModel = SideMenuViewModel(),
                                            config: SideMenuConfig = SideMenuConfig()) {
    self.leftMenu = AnyView(leftMenu)
    self.viewModel = viewModel
    self.config = config
    self.centerViewBuilder = centerView
    self._sideMenuLeftPanel = Binding { viewModel.sideMenuLeftPanel } set: {
      newValue in
      viewModel.sideMenuLeftPanel = newValue
    }
    self._sideMenuRightPanel = Binding { viewModel.sideMenuRightPanel } set: {
      newValue in
      viewModel.sideMenuRightPanel = newValue
    }
  }
  
  public init<Menu: View>(rightMenu: Menu,
                                            @ViewBuilder centerView: @escaping () -> CenterView,
                                            viewModel: SideMenuViewModel = SideMenuViewModel(),
                                            config: SideMenuConfig = SideMenuConfig()) {
    self.rightMenu = AnyView(rightMenu)
    
    self.viewModel = viewModel
    self.config = config
    self.centerViewBuilder = centerView
    self._sideMenuLeftPanel = Binding { viewModel.sideMenuLeftPanel } set: {
      newValue in
      viewModel.sideMenuLeftPanel = newValue
    }
    self._sideMenuRightPanel = Binding { viewModel.sideMenuRightPanel } set: {
      newValue in
      viewModel.sideMenuRightPanel = newValue
    }
  }
  
  public init<LMenu: View, RMenu: View>(leftMenu: LMenu,
                                                          rightMenu: RMenu,
                                                          @ViewBuilder centerView: @escaping () -> CenterView,
                                                          viewModel: SideMenuViewModel = SideMenuViewModel(),
                                                          config: SideMenuConfig = SideMenuConfig()) {
    self.leftMenu = AnyView(leftMenu)
    self.rightMenu = AnyView(rightMenu)
    self.viewModel = viewModel
    self.centerViewBuilder = centerView
    self.config = config
    self._sideMenuLeftPanel = Binding { viewModel.sideMenuLeftPanel } set: {
      newValue in
      viewModel.sideMenuLeftPanel = newValue
    }
    self._sideMenuRightPanel = Binding { viewModel.sideMenuRightPanel } set: {
      newValue in
      viewModel.sideMenuRightPanel = newValue
    }
  }
  
  private var leftMenu: AnyView? = nil
  private var rightMenu: AnyView? = nil
  
  private var config: SideMenuConfig
  @ObservedObject var viewModel: SideMenuViewModel
  
  @State private var leftMenuBGOpacity: Double = 0
  @State private var rightMenuBGOpacity: Double = 0
  
  @State private var leftMenuOffsetX: CGFloat = 0
  @State private var rightMenuOffsetX: CGFloat = 0
  @State var isLandscape: Bool?
  
  @Environment (\.editMode) var editMode;
  
  @State private var sideMenuGestureMode: SideMenuGestureMode = SideMenuGestureMode.active;
  @Binding private var sideMenuLeftPanel: Bool
  @Binding private var sideMenuRightPanel: Bool
  
  private var menuAnimation: Animation {
    .easeOut(duration: self.config.animationDuration)
  }
  
  @ViewBuilder var centerView: some View {
    centerViewBuilder()
  }
  
  public var body: some View {
    GeometryReader { geometry in
      ZStack {
        centerView
        if self.sideMenuLeftPanel && self.leftMenu != nil {
          MenuBackgroundView(sideMenuLeftPanel: self.$sideMenuLeftPanel,
                             sideMenuRightPanel: self.$sideMenuRightPanel,
                             bgColor: self.config.menuBGColor,
                             bgOpacity: self.leftMenuBGOpacity)
          .zIndex(1)
          
          self.leftMenu!
            .edgesIgnoringSafeArea(Edge.Set.all)
            .frame(width: self.config.menuWidth)
            .offset(x: self.leftMenuOffsetX, y: 0)
            .transition(.move(edge: Edge.leading))
            .zIndex(2)
            .animation(self.menuAnimation)
        }
        
        if self.sideMenuRightPanel && self.rightMenu != nil {
          MenuBackgroundView(sideMenuLeftPanel: self.$sideMenuLeftPanel,
                             sideMenuRightPanel: self.$sideMenuRightPanel,
                             bgColor: self.config.menuBGColor,
                             bgOpacity: self.rightMenuBGOpacity)
          .zIndex(3)
          self.rightMenu!
            .edgesIgnoringSafeArea(Edge.Set.all)
            .frame(width: self.config.menuWidth)
            .offset(x: self.rightMenuOffsetX, y: 0)
            .transition(.move(edge: Edge.trailing))
            .zIndex(4)
            .animation(self.menuAnimation)
        }
      }.gesture(viewModel.sideMenuLeftPanel ? self.panelDragGesture(geometry.size.width) : nil)
        .onAppear {
          self.leftMenuOffsetX = -self.menuXOffset(geometry.size.width)
          self.rightMenuOffsetX = self.menuXOffset(geometry.size.width)
          self.leftMenuBGOpacity = self.config.menuBGOpacity
          self.rightMenuBGOpacity = self.config.menuBGOpacity
        }
      // Previously, the following was driven by a NotificationCenter event. But it wasn't handling rotations correctly all the time. It wasn't giving the right width on a rotation. I think it was gettig called before the GeometryReader change.
      // This is a little crude, but I wanted to have an update that occurred on any change to the view-- so I could test if the landscape/portrait orientation had changed.
        .modifier(CallOnViewUpdate({
          let newIsLandscape = geometry.size.width > geometry.size.height
          var update = false
          if isLandscape == nil {
            update = true
          }
          else if isLandscape != newIsLandscape {
            update = true
          }
          
          if update {
            DispatchQueue.main.async {
              self.isLandscape = newIsLandscape
              self.rightMenuOffsetX = self.menuXOffset(geometry.size.width)
              self.leftMenuOffsetX = -self.menuXOffset(geometry.size.width)
            }
          }
        }))
        .environment(\.sideMenuGestureModeKey, self.$sideMenuGestureMode)
        .environment(\.sideMenuLeftPanelKey, self.$sideMenuLeftPanel)
        .environment(\.sideMenuRightPanelKey, self.$sideMenuRightPanel)
        .environment(\.horizontalSizeClass, .compact)
    }
  }
  
  // Just a means to get some code executed when a View is updated.
  private struct CallOnViewUpdate: ViewModifier {
    init(_ closure: ()->()) {
      closure()
    }
    
    func body(content: Content) -> some View {
      content
    }
  }
  
  private func panelDragGesture(_ screenWidth: CGFloat) -> _EndedGesture<_ChangedGesture<DragGesture>>? {
    if let mode = self.editMode?.wrappedValue, mode != EditMode.inactive {
      return nil
    }
    if self.sideMenuGestureMode == SideMenuGestureMode.inactive {
      return nil
    }
    
    return DragGesture()
      .onChanged { (value) in
        self.onChangedDragGesture(value: value, screenWidth: screenWidth)
      }
      .onEnded { (value) in
        self.onEndedDragGesture(value: value, screenWidth: screenWidth)
      }
  }
  
  private func menuXOffset(_ screenWidth: CGFloat) -> CGFloat {
    return (screenWidth - (self.config.menuWidth))/2
  }
  
  //  MARK: Drag gesture methods
  
  func onChangedDragGesture(value: DragGesture.Value, screenWidth: CGFloat) {
    let startLocX = value.startLocation.x
    let translation = value.translation
    
    let translationWidth = translation.width > 0 ? translation.width : -(translation.width)
    
    let leftMenuGesturePositionX = screenWidth * 0.1
    let rightMenuGesturePositionX = screenWidth * 0.9
    
    guard translationWidth <= self.config.menuWidth else { return }
    
    if self.sideMenuLeftPanel, value.dragDirection == .left, self.leftMenu != nil {
      let newXOffset = -self.menuXOffset(screenWidth) - translationWidth
      self.leftMenuOffsetX = newXOffset
      
      let translationPercentage = (self.config.menuWidth - translationWidth) / self.config.menuWidth
      guard translationPercentage > 0 else { return }
      self.leftMenuBGOpacity = self.config.menuBGOpacity * Double(translationPercentage)
    } else if self.sideMenuRightPanel, value.dragDirection == .right, self.rightMenu != nil {
      let newXOffset = self.menuXOffset(screenWidth) + translationWidth
      self.rightMenuOffsetX = newXOffset
      
      let translationPercentage = (self.config.menuWidth - translationWidth) / self.config.menuWidth
      guard translationPercentage > 0 else { return }
      self.rightMenuBGOpacity = self.config.menuBGOpacity * Double(translationPercentage)
    } else if startLocX < leftMenuGesturePositionX, value.dragDirection == .right, self.leftMenu != nil {
      if !self.sideMenuLeftPanel {
        self.sideMenuLeftPanel.toggle()
      }
      
      let defaultOffset = -(self.menuXOffset(screenWidth) + self.config.menuWidth)
      let newXOffset = defaultOffset + translationWidth
      
      self.leftMenuOffsetX = newXOffset
      
      let translationPercentage = translationWidth / self.config.menuWidth
      
      guard translationPercentage > 0 else { return }
      self.leftMenuBGOpacity = self.config.menuBGOpacity * Double(translationPercentage)
    } else if startLocX > rightMenuGesturePositionX, value.dragDirection == .left, self.rightMenu != nil {
      if !self.sideMenuRightPanel {
        self.sideMenuRightPanel.toggle()
      }
      
      let defaultOffset = self.menuXOffset(screenWidth) + self.config.menuWidth
      let newXOffset = defaultOffset - translationWidth
      
      self.rightMenuOffsetX = newXOffset
      
      let translationPercentage = translationWidth / self.config.menuWidth
      guard translationPercentage > 0 else { return }
      self.rightMenuBGOpacity = self.config.menuBGOpacity * Double(translationPercentage)
    }
  }
  
  func onEndedDragGesture(value: DragGesture.Value, screenWidth: CGFloat) {
    let midXPoint = (0.5 * self.config.menuWidth)
    
    if self.sideMenuRightPanel, self.rightMenu != nil {
      let rightMenuMidX = self.menuXOffset(screenWidth) + midXPoint
      
      if self.rightMenuOffsetX > rightMenuMidX {
        self.sideMenuRightPanel.toggle()
      }
      
      self.rightMenuOffsetX = self.menuXOffset(screenWidth)
      self.rightMenuBGOpacity = self.config.menuBGOpacity
    } else if self.sideMenuLeftPanel, self.leftMenu != nil {
      let leftMenuMidX = -self.menuXOffset(screenWidth) - midXPoint
      
      if self.leftMenuOffsetX < leftMenuMidX {
        self.sideMenuLeftPanel.toggle()
      }
      
      self.leftMenuOffsetX = -self.menuXOffset(screenWidth)
      self.leftMenuBGOpacity = self.config.menuBGOpacity
    }
  }
  
}

//@available(iOS 14.0, *)
//struct SideMenuViewProvider: LibraryContentProvider {
//
//  @LibraryContentBuilder var views: [LibraryItem] {
//    LibraryItem(SideMenu(leftMenu: LeftMenuPanel(), centerView: CenterView()),
//                visible: true,
//                title: "SideMenu with left menu",
//                category: .control)
//
//    LibraryItem(SideMenu(rightMenu: RightMenuPanel(), centerView: CenterView()),
//                visible: true,
//                title: "SideMenu with right menu",
//                category: .control)
//
//    LibraryItem(SideMenu(leftMenu: LeftMenuPanel(), rightMenu: RightMenuPanel(), centerView: CenterView()),
//                visible: true,
//                title: "SideMenu with both left and right menu",
//                category: .control)
//  }
//
//}

//  MARK: Menu background view

struct MenuBackgroundView : View {
  @Binding var sideMenuLeftPanel: Bool
  @Binding var sideMenuRightPanel: Bool
  
  let bgColor: Color
  let bgOpacity: Double
  
  var body: some View {
    Rectangle()
      .background(bgColor)
      .opacity(bgOpacity)
      .transition(.opacity)
      .onTapGesture {
        withAnimation {
          if self.sideMenuLeftPanel {
            self.sideMenuLeftPanel.toggle()
          }
          
          if self.sideMenuRightPanel {
            self.sideMenuRightPanel.toggle()
          }
        }
      }
      .edgesIgnoringSafeArea(Edge.Set.all)
  }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
  static var previews: some View {
    let leftMenu = LeftMenuPanel()
    let rightMenu = RightMenuPanel()

    return Group {
      SideMenu(leftMenu: leftMenu, centerView: { CenterView() } )

      SideMenu(rightMenu: rightMenu, centerView: { CenterView() })

      SideMenu(leftMenu: leftMenu, rightMenu: rightMenu, centerView: { CenterView() })
    }
  }
}
#endif
