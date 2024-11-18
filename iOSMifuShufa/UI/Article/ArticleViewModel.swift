//
//  ArticleViewModel.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/15.
//
import Foundation
import SwiftUI

class ArticleSection: Decodable {
  var section: String = ""
  var articles: List<Article> = []
  
  var htmlSection: AttributedString!
  var menuSection: AttributedString!
  
  enum CodingKeys: CodingKey {
    case section
    case articles
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.section = try container.decode(String.self, forKey: .section)
    self.articles = try container.decode([Article].self, forKey: .articles)
    
    let html = section.toHtmlString(font: .preferredFont(forTextStyle: .title3), textColor: Colors.defaultText.hexString)
    htmlSection = html!.swiftuiAttrString
    menuSection = section.toHtmlString(font: .preferredFont(forTextStyle: .callout), textColor: Colors.colorPrimary.hexString)!.swiftuiAttrString
  }
}

class Article: Decodable {
  var title = ""
  var url = ""
  var pdfFolder = ""
  var pdfImgCount = 0
  
  enum CodingKeys: CodingKey {
    case title
    case url
    case pdfFolder
    case pdfImgCount
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.title = try container.decode(String.self, forKey: .title)
    self.url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    self.pdfFolder = try container.decodeIfPresent(String.self, forKey: .pdfFolder) ?? ""
    self.pdfImgCount = try container.decodeIfPresent(Int.self, forKey: .pdfImgCount) ?? 0
  }
}

class AppRecommendItem: Decodable {
  var name = ""
  var icon = ""
  var pkg = ""
  var desc: String? = nil
  
  enum CodingKeys: CodingKey {
    case name
    case icon
    case pkg
    case desc
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.icon = try container.decode(String.self, forKey: .icon)
    self.pkg = try container.decode(String.self, forKey: .pkg)
    self.desc = try container.decodeIfPresent(String.self, forKey: .desc)
  }
}

class ArticleViewModel: AlertViewModel {
  @Published var clicked: Set<String> = Set<String>()
  static let shared = ArticleViewModel()
  @Published var sections = [ArticleSection]()
  override init() {
    super.init()
    self.fetchArticles()
  }
  
  func fetchArticles() {
    if sections.isNotEmpty() {
      return
    }
    Task {
      NetworkHelper.fetchArticles { sections in
        if let sections {
          DispatchQueue.main.async {
            self.sections = sections
          }
        }
      }
    }
  }
  
}
