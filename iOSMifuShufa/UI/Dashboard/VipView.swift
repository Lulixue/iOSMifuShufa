//
//  VipView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2025/2/26.
//
import Foundation
import SwiftUI
import StoreKit

class VipPackage : Decodable, Equatable {
  static func == (lhs: VipPackage, rhs: VipPackage) -> Bool {
    lhs.englishName == rhs.englishName
  }
  
  var productIdentifier: String = ""
  var name: String = ""
  var nameCht: String = ""
  var englishName: String = ""
  var price = 0.0
  var futurePrice = 0.0
  var months = 0
  
  var chineseName: String {
    name.orCht(nameCht)
  }
}
 

class PurchaseViewModel: NSObject, ObservableObject,
                          SKProductsRequestDelegate, SKPaymentTransactionObserver  {
  static var vipPackages = [VipPackage]()
  static let sharedViewModel = AlertViewModel()
  var alertViewModel: AlertViewModel {
    PurchaseViewModel.sharedViewModel
  }
  @Published var navigateToLogin = false
  @Published var packages = [VipPackage]()
  @Published var futureWidth: CGFloat? = nil
  @Published var nameWidth: CGFloat? = nil
  @Published var selected: VipPackage? = nil
  @Published var purchasing = false
  
  let futureFont = UIFont.systemFont(ofSize: 16)
  let priceFont = UIFont.systemFont(ofSize: 21)
  let nameFont = UIFont.systemFont(ofSize: 21)
  
  let navigationController: UINavigationController?
  init(navi: UINavigationController? = nil) {
    navigationController = navi
    super.init()
    initVipPackages()
    SKPaymentQueue.default().add(self)
  }
  
  deinit {
    SKPaymentQueue.default().remove(self)
  }
  
  private var request: SKProductsRequest!
  private var orderDate: Date!
   
  func validate(productIdentifiers: [String]) {
    let productIdentifiers = Set(productIdentifiers)
    request = SKProductsRequest(productIdentifiers: productIdentifiers)
    request.delegate = self
    request.start()
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
    return true
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    self.purchasing = false
    transactions.forEach { ta in
      switch ta.transactionState {
        case .purchased:
          SKPaymentQueue.default().finishTransaction(ta)
          printlnDbg("purchased, \(ta.transactionDate!), \(ta.payment.productIdentifier)")
          onPurchased(ta.payment.productIdentifier)
        case .restored:
          SKPaymentQueue.default().finishTransaction(ta)
        case .purchasing:
          printlnDbg("purchasing")
          self.purchasing = true
        default:
          printlnDbg(ta.transactionState.rawValue)
      }
    }
  }
  
  private func onPurchased(_ productIdentifier: String, restore: Boolean = false) {
    guard let selected = packages.first(where: { $0.productIdentifier == productIdentifier}) else { return }
    NetworkHelper.purchaseVip(CurrentUser.userId, selected.englishName) { user in
      if user != nil {
        CurrentUser.updateUser(user)
        DispatchQueue.main.async {
          let restoreMsg = "VIP购买已恢复，感谢诗友的信任！".orCht("VIP購買已恢復，感謝詩友的信任！")
          self.alertViewModel.showFullAlert("VIP支付", restore ? restoreMsg : "buy_vip_success".resString)
        }
      } else {
        DispatchQueue.main.async {
          self.alertViewModel.showFullAlert("VIP购买出现错误，请联系客服！".orCht("VIP購買出現錯誤，請聯繫客服！"))
        }
      }
    }
  }
  
  func restore() {
    if !CurrentUser.userLogin {
      showAnonymousDialog {
        NetworkHelper.loginPoemTmp(DEVICE_ID) { user in
          if let user = user {
            DispatchQueue.main.async {
              KeychainItem.updateTmpUserId(user.ID!)
              CurrentUser.updateUser(user)
              SKPaymentQueue.default().restoreCompletedTransactions()
            }
          } else {
            self.alertViewModel.showFullAlert("恢复购买出现错误，请稍后重试!".orCht("恢復購買出現錯誤，請稍後重試！"))
          }
        }
      }
    } else {
      SKPaymentQueue.default().restoreCompletedTransactions()
    }
  }
  
  var anonymousPurchase: String {
    "匿名购买".orCht("匿名購買")
  }
  
  var anonymouseMessage: String {
    "当前为匿名购买，仅在当前设备有效；登录之后购买，则可进行跨设备端使用，推荐登录之后再进行购买。"
      .orCht("當前爲匿名購買，僅在當前設備有效；登錄之後購買，則可進行跨設備端使用，推薦登録之後再進行購買。")
  }
  
  func doPurchase(productId: String) {
    guard SKPaymentQueue.canMakePayments() else { return }
    guard let product = products.first(where: {$0.productIdentifier == productId}) else { return }
    orderDate = Date.now
    let paymentRequest = SKPayment(product: product)
    SKPaymentQueue.default().add(paymentRequest)
  }
  
  func showAnonymousDialog(cancelHandler: @escaping () -> Void) {
      let login = "登录".orCht("登録")
    alertViewModel.showFullAlert("重要提醒", anonymouseMessage,
                                 okTitle: login, okRole: .destructive, ok: {
      self.doLogin()
    }, cancelTitle: anonymousPurchase, cancel: cancelHandler)
  }
  
  func purchase(productId: String) {
    if !CurrentUser.userLogin {
      showAnonymousDialog {
        NetworkHelper.loginPoemTmp(DEVICE_ID) { user in
          if let user = user {
            DispatchQueue.main.async {
              KeychainItem.updateTmpUserId(user.ID!)
              CurrentUser.updateUser(user)
              if !CurrentUser.isForeverVip {
                self.doPurchase(productId: productId)
              }
            }
          } else {
            self.alertViewModel.showAlertDlg("购买出现错误，请稍后重试!".orCht("購買出現錯誤，請稍後重試！"))
          }
        }
      }
    } else {
      self.doPurchase(productId: productId)
    }
  }
  
  private var products = [SKProduct]()
  // Create the SKProductsRequestDelegate protocol method
  // to receive the array of products.
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    if !response.products.isEmpty {
      products = response.products
      #if DEBUG
      for p in products {
        println("name: \(p.productIdentifier), price:\(p.price)")
      }
      #endif
    }
  }
  
  func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    for ta in queue.transactions {
      self.onPurchased(ta.payment.productIdentifier)
      SKPaymentQueue.default().finishTransaction(ta)
    }
  }
  
  func doLogin() {
    self.navigateToLogin = true
  }
  
  func syncPackages() {
    packages = Self.vipPackages
    self.updateFutureWidth()
    var productIds = [String]()
#if DEBUG
    productIds.append("testVipItem")
#endif
    productIds.append(contentsOf:  self.packages.map({ $0.productIdentifier}))
    self.validate(productIdentifiers: productIds)
  }
  
  func initVipPackages() {
    if Self.vipPackages.isNotEmpty() {
      syncPackages()
      return
    }
    NetworkHelper.getVipPackages { pkgs in
      if let pkgs = pkgs {
        Self.vipPackages = pkgs
        self.syncPackages()
      }
    }
  }
  
  func updateFutureWidth() {
    selected = packages.first
    if let max = packages.max(by: { $0.futurePrice < $1.futurePrice })?.futurePrice {
      let text = String(format: "￥%.1f", max)
      futureWidth = text.calculateUITextViewFreeSize(font: futureFont).width + 20
    }
    if let max = packages.max(by: { $0.chineseName.length < $1.chineseName.length})?.chineseName {
      
      nameWidth = max.calculateUITextViewFreeSize(font: nameFont).width + 40
    }
  }
   
}


enum LirenApp: CaseIterable {
  case Ouyx, Mifu, Wangxz, Yanzq

  var pkg: String {
    switch self {
    case .Ouyx:
      "com.lulixue.OuyangxunDict"
    case .Mifu:
      "com.lulixue.iOSMifuShufa"
    case .Wangxz:
      "com.lulixue.iOSWangxzShufa"
    case .Yanzq:
      "com.lulixue.iOSYanzqShufa"
    }
  }
  
  var appId: String {
    switch self {
    case .Ouyx:
      "1499296451"
    case .Mifu:
      "6520390752"
    case .Wangxz:
      "6742651023"
    case .Yanzq:
      "6738764319"
    }
  }
  
  var icon: String {
    switch (self) {
    case .Yanzq: return "yzq_icon.png"
    case .Mifu: return "mifu_logo.png"
    case .Ouyx: return "oyx_icon.png"
    case .Wangxz: return "wxz_icon.png"
    }
  }
    
  var url: String {
    "https://appdatacontainer.blob.core.windows.net/liren/config/icons/\(icon)"
  }
    
  static let anothersApps: Array<LirenApp> = {
    let pkgName = Bundle.main.bundleIdentifier
    return LirenApp.allCases.filter { $0.pkg != pkgName }
  }()
}

@ViewBuilder
func VipPackagesView() -> some View {
  LazyView {
    VipPackagesContentsView()
  }
}

struct VipPackagesContentsView: View {
  @ObservedObject var viewModel = PurchaseViewModel()
  @ObservedObject var CurrentUser = UserViewModel.shared
  @ObservedObject var alertViewModel = PurchaseViewModel.sharedViewModel
  
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    NavigationStack {
      bodyView
    }
    .navigationDestination(isPresented: $viewModel.navigateToLogin) {
      LoginView()
    }
  }
  var bodyView: some View {
    ZStack {
      VStack(spacing: 0) {
        NaviView {
          ZStack {
            HStack {
              Spacer()
              NaviTitle(text: "vip_service".localized)
              Spacer()
            }
            HStack {
              BackButtonView {
                presentationMode.wrappedValue.dismiss()
              }
              Spacer()
              Button {
                viewModel.restore()
              } label: {
                Text("恢复购买".orCht("恢復購買"))
                  .foregroundStyle(.blue)
              }.buttonStyle(.plain)
            }
          }
        }.background(Colors.background.swiftColor)
        Divider()
        GeometryReader { geo in
          contents(geo: geo).padding(.all, 20)
        }
      }
      if viewModel.purchasing {
        LoadingView(title: .constant("正在购买...".orCht("正在購買...")),
                    bgColor: Color.gray.opacity(0.2))
      }
    }.navigationBarHidden(true).background(Colors.wx_background.swiftColor)
      .modifier(AlertViewModifier(viewModel: alertViewModel))
  }
  
  @ViewBuilder func contents(geo: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      Spacer.height(50)
      let status = CurrentUser.currentStatus
      if let astr = status as? AttributedString {
        NavigationLink {
          LoginView()
        } label: {
          Text(astr)
        }.buttonStyle(.plain)
      } else {
        Text(status as! String).font(UserViewModel.STATUS_FONT.swiftFont).foregroundColor(CurrentUser.currentStatusColor)
      }
      if CurrentUser.isVip && UserItem.source.canSync {
        HStack(spacing: 4) {
          Text("已同步").foregroundStyle(.searchHeader).font(.footnote)
          let anotherApps = LirenApp.anothersApps
          ForEach(anotherApps, id: \.self) { type in
            Button {
              Utils.gotoAppInStore(type.appId)
            } label: {
              AsyncImage(url: type.url.url!) { image in
                image.image?.resizable()
              }
              .frame(width: 24, height: 24)
              .aspectRatio(contentMode: .fit)
              .clipShape(Circle())
              .background {
                Circle().stroke(.gray, lineWidth: 0.5)
              }
            }
          }
        }.padding(.horizontal, 4).padding(.vertical, 3).background {
          RoundedRectangle(cornerRadius: 5).stroke(.gray, lineWidth: 0.5)
        }.padding(.vertical, 5)
      }
      if let expired = CurrentUser.expiredTime {
        Text(expired.replace("-", "/")).font(.footnote).foregroundColor(Colors.purple.swiftColor).padding(.vertical, 5)
      }
      
      if viewModel.packages.isEmpty {
        ProgressView()
          .controlSize(ControlSize.large)
          .tint(.gray).progressViewStyle(.circular).frame(width: 100, height: 100)
          .background(Colors.second_background.swiftColor).padding(.top, 35)
      } else {
        VStack(spacing: 0) {
          ForEach(0..<viewModel.packages.size, id:\.self) { i in
          let pkg = viewModel.packages[i]
          let selected = viewModel.selected == pkg
          Button {
            viewModel.selected = pkg
          } label: {
            HStack(spacing: 0) {
              if selected {
                Image(systemName: "checkmark.circle.fill").square(size: 16).foregroundColor(Colors.darkOrange.swiftColor)
              } else {
                Spacer.width(16)
              }
              Text(pkg.chineseName).font(viewModel.nameFont.swiftFont)
                .frame(width: viewModel.nameWidth, alignment: .center).foregroundColor(Colors.darkSlateGray.swiftColor)
              Divider().frame(height: 15)
              HStack(alignment: .center) {
                Text(String(format: "￥%.1f", pkg.futurePrice)).strikethrough().font(viewModel.futureFont.swiftFont).foregroundColor(UIColor.lightGray.swiftColor)
              }.frame(width: viewModel.futureWidth)
              Text(String(format: "￥%.1f", pkg.price)).font(viewModel.priceFont.swiftFont).frame(maxWidth: .infinity).foregroundColor(Colors.darkSlateGray.swiftColor)
            }.padding(.leading, 10).padding(.vertical, 10).background(selected ? Colors.background.swiftColor : .clear).frame(maxWidth: .infinity)
          }.buttonStyle(.plain)
          if i != viewModel.packages.size - 1 {
            Divider().padding(.leading, 10)
          }
        }
        }.background(Colors.wx_background.swiftColor).overlay {
          RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.45), lineWidth: 1)
        }.cornerRadius(5).padding(.horizontal, 15).padding(.top, 35)
        
      }
      HStack {
        Image(systemName: "deskclock").resizable().scaledToFit().frame(width: 12, height: 12).foregroundColor(.white)
        Text("限时优惠".orCht("限時優惠")).font(.footnote).foregroundColor(.white)
      }.padding(.horizontal, 10).padding(.vertical, 5).background(Colors.darkOrange.swiftColor).cornerRadius(15).padding(.top, 35)
      Button {
        if let selected = viewModel.selected {
          viewModel.purchase(productId: selected.productIdentifier)
        }
      } label: {
        Text("confirm_purchase".localized).tracking(1).font(.title3).padding(.horizontal, 10)
          .padding(.vertical, 2)
      }.buttonStyle(PrimaryButton(enabled: !CurrentUser.isForeverVip))
        .padding(.top, 10)
        .disabled(CurrentUser.isForeverVip)
      Spacer()
      NavigationLink {
        VipPrivilegeView()
      } label: {
        Text(">> \(VipPrivilegeView.VIP_PRIVILEGE) >>")
          .foregroundStyle(.blue)
          .font(.callout)
          .underline()
      }.buttonStyle(.plain)
      20.VSpacer()
      let width = min(geo.size.width-10, UserViewModel.KEFU_HTML.size.width+1)
      SelectableTextView(htmlText: UserViewModel.KEFU_HTML.html, fixedWidth: width).frame(width: width, height: UserViewModel.KEFU_HTML.size.height)
        .padding(.bottom, 15)
    }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Colors.second_background.swiftColor).cornerRadius(5).shadow(radius: 1)
  }
}


struct VipPackagesView_Previews: PreviewProvider {
  static var previews: some View {
    VipPackagesView()
  }
}
 


struct SelectableTextView: UIViewRepresentable {
  let text: String
  let font: UIFont
  let fixedWidth: CGFloat
  let htmlText: NSAttributedString?
  let textColor: UIColor?
  let textViewModifier: (UITextView) -> Void
  let maxHeight: CGFloat?
  
  init(text: String = "", htmlText: NSAttributedString? = nil, font: UIFont = UIFont.preferredFont(forTextStyle: .body),
       fixedWidth: CGFloat, textColor: UIColor? = nil,
       maxHeight: CGFloat? = nil,
       textViewModifier: @escaping (UITextView) -> Void = { _ in }) {
    self.text = text
    self.htmlText = htmlText
    self.font = font
    self.fixedWidth = fixedWidth
    self.textColor = textColor
    self.textViewModifier = textViewModifier
    self.maxHeight = maxHeight
  }
  
  func makeUIView(context: Context) -> UIView {
    let parentView = UIView(frame: .zero)
    parentView.backgroundColor = .clear
    let textView = UITextView(frame: .zero)
    textView.isSelectable = true
    textView.isUserInteractionEnabled = true
    textView.isScrollEnabled = false
    textView.isEditable = false
    textView.textContainer.lineBreakMode = .byCharWrapping
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.font = font
    textView.backgroundColor = .clear
    parentView.addSubview(textView)
    if textColor != nil {
      if htmlText == nil {
        textView.textColor = self.textColor
      }
    }
    textViewModifier(textView)
    parentView.translatesAutoresizingMaskIntoConstraints = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      parentView.widthAnchor.constraint(equalToConstant: fixedWidth),
      textView.topAnchor.constraint(equalTo: parentView.topAnchor),
      textView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
      textView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor)
    ])
    if let maxHeight = self.maxHeight {
      NSLayoutConstraint.activate([
        parentView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight)
      ])
    }
    if htmlText != nil {
      textView.attributedText = htmlText
    } else {
      textView.text = text
    }
    
    return parentView
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    let textView = uiView.subviews[0] as! UITextView
    if htmlText != nil  {
      textView.attributedText = htmlText
    } else {
      textView.text = text
    }
    self.textViewModifier(textView)
  }
}

extension String {
  func trimIndent() -> String {
    self.trim()
  }
}

struct VipPrivilegeView: View {
  static var VIP_PRIVILEGE: String {
    "VIP会员权益".orCht("VIP會員權益")
  }
  
  
  @Environment(\.presentationMode) var presentationMode
  
  @State var html: AttributedString? = nil
  
  static var contentHTML: AttributedString {
    let contentChs = """
      1. 更多汉字同时搜索和集字 <br />
      2. 同时多个过滤器 <br />
      3. 所有碑帖下载，且无水印 <br />
      4. 无广告 <br />
      5. 立人书法所有App，目前有欧阳询、王羲之、米芾、颜真卿App，手机和苹果帐号通用VIP
    """.trimIndent()
    let contentCht = """
      1. 更多漢字同時搜索和集字 <br />
      2. 同時多個過濾器 <br />
      3. 所有碑帖下載，且無水印 <br />
      4. 無廣告 <br />
      5. 立人書法所有App，目前有歐陽詢、王羲之、米芾、顏真卿App，手機和蘋果帳號通用VIP
    """.trimIndent()
    let text = contentChs.orCht(contentCht)
    return text.toHtmlString(font: .preferredFont(forTextStyle: .body))!.swiftuiAttrString
  }
   
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationMode.wrappedValue.dismiss()
        }
        Spacer()
        NaviTitle(text: Self.VIP_PRIVILEGE)
        Spacer()
        CUSTOM_NAVI_BACK_SIZE.HSpacer()
      }
      Divider()
      ScrollView {
        if let html {
          Text(html)
            .multilineTextAlignment(.leading)
            .lineSpacing(1.5)
            .padding()
        }
      }
    }.navigationBarBackButtonHidden()
      .onAppear {
        if html == nil {
          Task {
            let html = Self.contentHTML
            DispatchQueue.main.async {
              self.html = html
            }
          }
        }
      }
  }
}

#Preview(body: {
  VipPrivilegeView()
})
