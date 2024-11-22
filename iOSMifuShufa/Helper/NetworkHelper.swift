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
let LIXUE_TEST_URL = "https://lulixuetest.azurewebsites.net/"

#if DEBUG
let AZURE_WEB_URL = LIXUE_TEST_URL
#else
let AZURE_WEB_URL = OUYANGXUN_AZURE_WEB
#endif


enum ConvertRegion : String{
  case Original,
       Mainland,
       Taiwan,
       Hongkong
}

extension ConvertRegion {
  var variantStd: String {
    switch self {
    case .Original: return "opencc_std_variant"
    case .Hongkong: return "hongkong_std_variant"
    case .Taiwan: return "taiwan_std_variant"
    default: return ""
    }
  }
  
  var phrase: String {
    switch self {
    case .Original: return "no_convert"
    case .Taiwan: return "taiwan_mode"
    default: return ""
    }
  }
}

enum TranslateMode {
  case HansToHant, HantToHans
}

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
  
  static func syncUser(id: String, onResult: @escaping (PoemUser?) -> Void) {
    let url = AZURE_WEB_URL + "LirenAPI/SyncUser"
    let parameters: [String: Any] = [
      "userId": id,
      "appVersion": "iOS v\(Bundle.main.appVersion)"
    ]
    
    AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody)
      .responseDecodable(of: PoemUser.self) { response in
        switch response.result {
        case .success(let user):
          onResult(user)
        case .failure(let error):
          print(error)
          onResult(nil)
        }
      }
  }
  
  static func changeUserName(_ newName: String, onResult: @escaping (PoemUser?) -> Void) {
    let url = AZURE_WEB_URL + "LirenAPI/ChangeUserName"
    let parameters: [String: Any] = [
      "userId": CurrentUser.userId,
      "newName": newName,
      "transactionKey": "N3QRThrgr0C9D9B8eNiTnBjgXX3Dpv"
    ]
    AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody)
      .responseDecodable(of: PoemUser.self) { response in
        switch response.result {
        case .success(let user):
          onResult(user)
        case .failure(let error):
          print(error)
          onResult(nil)
        }
      }
  }
  
  static func deleteAccount(_ id: String, onResult: @escaping (Bool) -> Void) {
    let url = AZURE_WEB_URL + "LirenAPI/DeleteAccount"
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
        println("\(String(describing: response.error))")
        onResult(nil)
      }
    }
  }
  
  
  static func loginPoemByPhone(_ phoneNum: String, _ deviceId: String, onResult: @escaping (PoemUser?) -> Void) {
    let url = AZURE_WEB_URL + "LirenAPI/UserLoginLiren"
    let response = "{\"number\": \"86\(phoneNum)\"}"
    let parameters: [String: Any] = [
      "response": response,
      "ip": "",
      "source": "Phone",
      "deviceId": deviceId
    ]
    AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody)
      .responseDecodable(of: PoemUser.self) { response in
        switch response.result {
        case .success(let user):
          onResult(user)
        case .failure(let error):
          print(error)
          onResult(nil)
        }
      }
  }
  
  static func loginPoem(_ id: String, _ deviceId: String, onResult: @escaping (PoemUser?) -> Void) {
    let url = AZURE_WEB_URL + "LirenAPI/UserLoginLiren"
    let response = "{\"userId\": \"\(id)\"}"
    let parameters: [String: Any] = [
      "response": response,
      "ip": "",
      "source": "Apple",
      "deviceId": deviceId
    ]
    AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody)
      .responseDecodable(of: PoemUser.self) { response in
        switch response.result {
        case .success(let user):
          onResult(user)
        case .failure(let error):
          print(error)
          onResult(nil)
        }
      }
  }
   
  static func syncConfig(after: @escaping (AzureConfig) -> Void) {
    let CONFIG_URL = STORAGE_URL + "/liren/\(STORAGE_DIR)/config.json"
    URLCache.shared.removeAllCachedResponses()
    AF.request(CONFIG_URL.getEncodedURL()).responseDecodable(of: AzureConfig.self) { response in
      switch response.result {
      case .success(let config):
        Settings.config = config
        after(config)
      case .failure(let error):
        println("syncConfig \(error)")
      }
    }
  }
  /*
   @FormUrlEncoded
   @POST("Opencc/Convert")
   suspend fun convert(@Field("input") input: String, @Field("mode") mode: TranslateMode,
   @Field("variant") variant: ConvertRegion,
   @Field("region") region: ConvertRegion): ResponseBody*/
  static func convert(input: String, mode: TranslateMode,
                      variant: ConvertRegion, region: ConvertRegion, onResult: @escaping (String, Bool) -> Void) {
    let SUBMIT_URL = OYX_WEB_URL + "Opencc/Convert"
    let paramaters = [
      "input": input,
      "mode": mode,
      "variant": variant,
      "region": region
    ] as [String : Any]
    AF.request(SUBMIT_URL, method: .post,  parameters: paramaters, headers: POST_HEADERS).response { response in
      switch response.result {
      case .success:
        onResult(String(data: response.data!, encoding: .utf8)!, true)
      case let .failure(error):
        onResult(error.localizedDescription, false)
      }
    }
  }
  
  static func convert(text: String, mode: TranslateMode, onResult: @escaping (String, Bool) -> Void) {
    NetworkHelper.convert(input: text, mode: mode, variant: .Original,
                          region: .Original, onResult: onResult)
      
  }
}

extension String {
  func getEncodedURL() -> String {
    return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
  }
}
