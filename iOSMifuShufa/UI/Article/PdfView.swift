//
//  PdfView.swift
//  iOSYanzqShufa
//
//  Created by lulixue on 2024/11/28.
//

import SwiftUI
import Foundation

class PdfViewModel: AlertViewModel {
  let article: Article
  let urls: [String]
  
  
  init(article: Article) {
    self.article = article
    var urls = [String]()
    for i in 0..<article.pdfImgCount {
      let fileName = String(format: "%@_%02d.jpg", article.pdfFolder, i)
      let url = "https://appdatacontainer.blob.core.windows.net/liren/web/pdf/\(article.pdfFolder)/\(fileName)"
      urls.append(url)
    }
    self.urls = urls
    super.init()
  }
}

struct PdfView: View {
  @StateObject var viewModel: PdfViewModel
  @Environment(\.presentationMode) var presentationMode
  
  var article: Article {
    viewModel.article
  }
  @State var currentPage = 0
  var body: some View {
    VStack(spacing: 0) {
      NaviView {
        NaviContents(title: article.title) {
          BackButtonView {
            self.presentationMode.wrappedValue.dismiss()
          }
        } trailing: {
          
        }
      }
      Divider()
      ZStack(alignment: .topLeading) {
        TabView(selection: $currentPage) {
          ForEach(0..<viewModel.urls.size, id: \.self) { i in
            SinglePreviewItem(url: viewModel.urls[i])
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        Text("\(currentPage+1)/\(viewModel.urls.size)")
          .padding(5)
          .foregroundStyle(.white)
          .background(.gray).clipShape(RoundedRectangle(cornerRadius: 5))
          .padding(.top, 10).padding(.leading, 10)
      }.background(.black)
    }.navigationBarHidden(true)
  }
}

#Preview {
  let json = """

      {
        "title": "方令光:《颜勤礼碑》、《颜家庙碑》真伪考",
        "pdfFolder": "flg",
        "pdfImgCount": 58,
        "url": "https://appdatacontainer.blob.core.windows.net/liren/web/yzq/flg.pdf"
      }
"""
  let article = try! JSONDecoder().decode(Article.self, from: json.utf8Data)
  PdfView(viewModel: PdfViewModel(article: article))
}
