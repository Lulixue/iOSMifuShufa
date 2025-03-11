//
//  WorkIntroView.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/12.
//
import SwiftUI
import SDWebImageSwiftUI

struct WorkIntroView: View {
  @StateObject var viewModel: WorkViewModel
  @StateObject var naviVM = NavigationViewModel()
  @Environment(\.presentationMode) var presentationmode
  
  var work: BeitieWork {
    viewModel.work
  }
  
  private struct ItemView: View {
    let title: String
    let value: String
    var body: some View {
      HStack(alignment: .top) {
        Text(title).font(.footnote).bold().padding(.horizontal, 4).padding(.vertical, 3).foregroundStyle(.white).background {
          RoundedRectangle(cornerRadius: 5).fill(Color.searchHeader)
        }
       
        Text(value).foregroundStyle(Color.colorPrimary)
          .textSelection(.enabled)
          
        Spacer()
      }.padding(.horizontal, 15)
    }
  }
  
  var body: some View {
    NavigationStack {
      contents
    }.modifier(WorkDestinationModifier(naviVM: naviVM))
  }
  var contents: some View {
    VStack(spacing: 0) {
      NaviView {
        BackButtonView {
          presentationmode.wrappedValue.dismiss()
        }
        Spacer()
        Text(work.workNameAttrStr(.title3, curves: false))
        Spacer()
        Button {
          naviVM.gotoWork(work: work)
        } label: {
          HStack(spacing: 3) {
            Image(systemName: "arrow.up.right.square").square(size: 10)
            Text("查看").font(.footnote)
          }
        }.buttonStyle(PrimaryButton(bgColor: .blue, horPadding: 6, verPadding: 4))
          .padding(.leading, 3)
      }.background(Colors.surfaceContainer.swiftColor)
      Divider()
      ScrollView {
        VStack(spacing: 10) {
          HStack(alignment: .center) {
            Spacer()
            Button {
              naviVM.gotoWork(work: work)
            } label: {
              WebImage(url: work.cover.url!) { img in
                img.image?.resizable()
                  .scaledToFit()
                  .frame(height: 100)
                  .contentShape(RoundedRectangle(cornerRadius: 5))
                  .clipped()
                  .padding(3)
                  .background(content: {
                    RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.5), lineWidth: 0.5)
                  })
              }
            }.buttonStyle(.plain)
            Spacer()
          }.padding(.top, 20).padding(.horizontal, 20)
          ItemView(title: "名称".orCht("名稱"), value: work.chineseName())
          if let version = work.chineseVersion()?.emptyNull {
            ItemView(title: "版本".orCht("版本"), value: version)
          }
          if (work.ceYear > 0) {
            ItemView(title: "时间".orCht("時間"), value: "\(work.chineseYear() ?? "")(\(work.ceYear)年)")
          }
          ItemView(title: "类型".orCht("類型"), value: work.type.typeChinese)
          if (work.type != CalligraphyType.Hua) {
            ItemView(title: "书体".orCht("書體"), value: work.font.longChinese)
            ItemView(title: "尺寸", value: work.shuType!.chinese)
          }
          if (work.hasSingle()) {
            ItemView(title: "单字".orCht("單字"), value: work.singleCount.toString())
          }
          if let intro = work.chineseIntro()?.emptyNull {
            ItemView(title: "简介".orCht("簡介"), value: intro)
          }
          if let text = work.chineseText()?.emptyNull {
            ItemView(title: "释文".orCht("釋文"), value: text)
          }
        }
      }
      Divider()
      Button {
        naviVM.gotoWork(work: work)
      } label: {
        HStack {
          Spacer()
          Text("查看").foregroundStyle(.blue).font(.callout)
          Spacer()
        }.padding(.vertical, 5).background(.white)
      }.buttonStyle(BgClickableButton())
    }.navigationBarHidden(true)
  }
}

#Preview {
  WorkIntroView(viewModel: WorkViewModel(work: BeitieDbHelper.shared.works[0]))
}


extension String {
  var emptyNull: String? {
    isEmpty ? nil : self
  }
}
