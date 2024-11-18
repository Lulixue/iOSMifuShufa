//
//  NetworkHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/15.
//
import Alamofire
import SwiftyJSON
import DeviceKit
import Foundation

let STORAGE_URL = "https://appdatacontainer.blob.core.windows.net"
let OYX_WEB_URL = "http://www.ouyangxun.net/"
let OUYANGXUN_AZURE_WEB = "https://ouyangxunshufa.azurewebsites.net/"
let LIXUE_TEST_URL = "http://lulixuetest.azurewebsites.net/"

#if DEBUG
let AZURE_WEB_URL = LIXUE_TEST_URL
#else
let AZURE_WEB_URL = OUYANGXUN_AZURE_WEB
#endif


class NetworkHelper {
  private static let POST_HEADERS: HTTPHeaders = [
    "Content-Type": "application/x-www-form-urlencoded"
  ]
  private static func getDeviceInfo() -> String {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    
    var s = "From: == \("app_name".localized) ==, "
    s += "iOS App Version: " + appVersion
    s += ", Device: " + Device.current.description
    return s
  }
  
  
  
  static func deleteAccount(_ id: String, onResult: @escaping (Bool) -> Void) {
    let url = AZURE_WEB_URL + "JiyunAPI/DeleteAccount"
    let parameters: [String: Any] = [
      "userId": id,
      "name": CurrentUser.poemUser?.Username ?? "",
      "transactionKey": "N3QRThrgr07b5TPAB8eNiTnBjgxx3Dpv"
    ]
    AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody)
      .responseString { response in
        switch response.result {
        case .success(_):
          onResult(true)
        case .failure(let error):
          print("error: \(error)")
          onResult(false)
          
        }
      }
  }
  
  static func submitFeedback(feedback: String, contact: String, onResult: @escaping (String?) -> Void) {
    let SUBMIT_URL = AZURE_WEB_URL + "API/SubmitFeedback"
    
    let json: JSON = [
      "feedback" : feedback,
      "contact" : contact,
      "ip" :  getDeviceInfo()
    ]
    let jsonString = json.rawString([.castNilToNSNull: true])
    
    let submitURL = SUBMIT_URL + "?json=" + jsonString!
    let encoded = submitURL.urlEncoded!
    
    AF.request(encoded,
               method: .get ).response { response in
      switch response.result {
      case .success:
        onResult(nil)
      case let .failure(error):
        onResult(error.localizedDescription)
      }
    }
  }
  
  static func fetchArticles(onResult: @escaping ([ArticleSection]?) -> Void) {
    let url = STORAGE_URL + "/liren/\(STORAGE_DIR)/articles.json"
    AF.request(url.getEncodedURL()).responseDecodable(of: [ArticleSection].self) { response in
      switch response.result {
      case .success(let sections):
        onResult(sections)
      default:
        println("\(response.error)")
        onResult(nil)
      }
    }
  }
}

extension String {
  func getEncodedURL() -> String {
    return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
  }
}
