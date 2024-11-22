//
//  VerifyHelper.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/20.
//

import UIKit
import Foundation
import CommonCrypto
import Collections
import Alamofire

class RequestModel: Decodable {
  var VerifyCode: String = ""
  var OutId: String = ""
  var RequestId: String = ""
  var BizId: String = ""
}

typealias MutableMap = Dictionary

class RequestResponse: Decodable  {
  var message: String = ""
  var code: String = ""
  var model: RequestModel = RequestModel()
  var success: Bool = false
  
  enum CodingKeys: CodingKey {
    case Message
    case Code
    case Model
    case Success
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.message = (try? container.decodeIfPresent(String.self, forKey: .Message)) ?? ""
    self.code = try container.decode(String.self, forKey: .Code)
    self.model = (try? container.decode(RequestModel.self, forKey: .Model)) ?? RequestModel()
    self.success = (try? container.decodeIfPresent(Bool.self, forKey: .Success)) ?? false
  }
}

class VerifyResponse: Decodable {
  var message: String = ""
  var code: String = ""
  var model: VerifyModel = VerifyModel()
  var success: Bool = false
  
  enum CodingKeys: CodingKey {
    case Message
    case Code
    case Model
    case Success
  }
  
  required init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.message = try container.decode(String.self, forKey: .Message)
    self.code = try container.decode(String.self, forKey: .Code)
    self.model = (try? container.decodeIfPresent(VerifyModel.self, forKey: .Model)) ?? VerifyModel()
    self.success = try container.decode(Bool.self, forKey: .Success)
  }
}

class VerifyModel: Decodable {
  var VerifyResult: String = ""
}

struct VerifyHelper {
  private static let signName = "立雪网络科技"
  private static let domain = "dypnsapi.aliyuncs.com"
  private static var accessKeyId = {
    let encoded = "TFRBSTV0UUJzdTNvUUQ2TFFzeFFGbUdp"
    return encoded
  }()
  private static var accessKeySecret = {
    let encoded = "b0NuQkJCZGFvTEduaUs5dWJyUmlFYlVRSnNBM1ZC"
    return encoded
  }()
  private static let encoding = "UTF-8"
  private static let iso8601DateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
  private static let separator = "&"
  private static let algorithm = "HmacSHA1"
  
  private static func percentEncode(_ value: String?, withAllowedCharacters: CharacterSet = .urlHostAllowed) -> String {
    guard let value = value else { return "" }
    return value.addingPercentEncoding(withAllowedCharacters: withAllowedCharacters)?
      .replacingOccurrences(of: "+", with: "%20")
      .replacingOccurrences(of: "*", with: "%2A")
      .replacingOccurrences(of: "%7E", with: "~") ?? ""
  }
  
  static func encode(_ value: String?) -> String {
    return percentEncode(value)
  }
  
  private static func formatIso8601Date(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = iso8601DateFormat
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
  }
  
  static func concatQueryString(parameters: Dictionary<String, String?>?) -> String? {
    guard let parameters = parameters else { return nil }
    
    var urlBuilder = ""
    for (key, value) in parameters {
      urlBuilder += "\(encode(key))"
      if let value = value {
        urlBuilder += "=\(encode(value))"
      }
      urlBuilder += separator
    }
    
    if !parameters.isEmpty {
      urlBuilder.removeLast()
    }
    
    return urlBuilder
  }
  
  static func doRequest( parameters:inout [String: String]) throws -> String {

    let httpMethod = "POST"
    let sortedKeys = Array(parameters.keys).sorted()
    var sortedParams = OrderedDictionary<String, String?>()
    var stringToSign = "\(httpMethod)\(separator)\(percentEncode("/"))\(separator)"
    var canonicalizedQueryString = ""
    
    for key in sortedKeys {
      sortedParams[key] = parameters[key]
      canonicalizedQueryString += "\(separator)\(percentEncode(key))=\(percentEncode(parameters[key]))"
    }
    
    stringToSign += percentEncode(String(canonicalizedQueryString.dropFirst()), withAllowedCharacters: .afURLQueryAllowed)
    
    let stringTo = stringToSign
    let key = accessKeySecret + separator
    let show = stringTo.hmac(algorithm: .SHA1, key: key)
    
    parameters["Signature"] = show
    printlnDbg("stringTo: \(stringTo)")
    printlnDbg("show: \(show)")
    let url = concatQueryString(parameters: parameters)!
    let http_url = "https://\(domain)/?\(url)"
    printlnDbg("url: \(http_url)")
    let result = try sendRequest(http_url, httpMethod).replacing("\\", with: "")
    return result
  }
  
  static func sendRequest(_ urlParam: String, _ method: String) throws -> String {
    let url = urlParam.url!
    let semaphore = DispatchSemaphore(value: 0)
    var result = ""
    var exception = false
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.addValue("application/json;charset=GBK", forHTTPHeaderField: "Content-Type")
    
    let headers: HTTPHeaders = [.contentType("application/json;charset=GBK")]
    AF.request(urlParam, method: .post, encoding: JSONEncoding.default, headers: headers).response { response in
      switch response.result {
      case .success(let data):
        result = data!.utf8String
      case .failure:
        exception = true
      }
      semaphore.signal()
    }
    
    _ = semaphore.wait(timeout: .distantFuture)
    if exception {
      throw RuntimeError("error")
    }
    printlnDbg("result: \(result)")
    return result
  }
  
  static func checkVerifyCode(_ phoneNumber: String, _ code: String) throws {
      //这里传METHOD 切换为GET即将POST改为GET
    var parameters = HashMap<String, String>()
      //接口名Action,Version需要跟具体的api进行调整
    parameters["Action"] = "CheckSmsVerifyCode"
    parameters["Version"] = "2017-05-25"
    parameters["AccessKeyId"] = accessKeyId
    parameters["Timestamp"] = formatIso8601Date(Date()) //"2024-11-20T13:26:19Z"
    parameters["SignatureMethod"] = "HMAC-SHA1"
    parameters["SignatureVersion"] = "1.0"
    parameters["SignatureNonce"] = UUID().uuidString //"36D166E2-489D-440C-BB63-7A25C6858EA8"
    parameters["Format"] = "JSON"
    /*************---------您的入参在下面(api具体的业务入参)----------- */
    parameters["PhoneNumber"] = phoneNumber
    parameters["VerifyCode"] = code
    let result = try doRequest(parameters: &parameters)
    let response = try JSONDecoder().decode(VerifyResponse.self, from: result.utf8Data)
    if !response.success || response.model.VerifyResult != "PASS" {
      throw RuntimeError("error")
    }
  }
  
  static func requestSmsCode(phoneNumber: String) throws {
    var parameters = MutableMap<String, String>()
      //接口名Action,Version需要跟具体的api进行调整
    parameters["Action"] = "SendSmsVerifyCode"
    parameters["Version"] = "2017-05-25"
    parameters["AccessKeyId"] = accessKeyId
    parameters["Timestamp"] = formatIso8601Date(Date())
    parameters["SignatureMethod"] = "HMAC-SHA1"
    parameters["SignatureVersion"] = "1.0"
    parameters["SignatureNonce"] = UUID().uuidString
    parameters["Format"] = "JSON"
    /*************---------您的入参在下面(api具体的业务入参)----------- */
    parameters["PhoneNumber"] = phoneNumber
    parameters["SignName"] = signName
    parameters["TemplateCode"] = "SMS_294051308"
    parameters["TemplateParam"] = "{\"code\": \"##code##\"}"
    let result = try doRequest(parameters: &parameters)
    let response = try JSONDecoder().decode(RequestResponse.self, from: result.utf8Data)
    if !response.success {
      throw RuntimeError("error")
    }
  }
}


struct RuntimeError: LocalizedError {
  let description: String
  
  init(_ description: String) {
    self.description = description
  }
  
  var errorDescription: String? {
    description
  }
}

enum HMACAlgorithm {
  case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
  
  func toCCHmacAlgorithm() -> CCHmacAlgorithm {
    var result: Int = 0
    switch self {
    case .MD5:
      result = kCCHmacAlgMD5
    case .SHA1:
      result = kCCHmacAlgSHA1
    case .SHA224:
      result = kCCHmacAlgSHA224
    case .SHA256:
      result = kCCHmacAlgSHA256
    case .SHA384:
      result = kCCHmacAlgSHA384
    case .SHA512:
      result = kCCHmacAlgSHA512
    }
    return CCHmacAlgorithm(result)
  }
  
  func digestLength() -> Int {
    var result: CInt = 0
    switch self {
    case .MD5:
      result = CC_MD5_DIGEST_LENGTH
    case .SHA1:
      result = CC_SHA1_DIGEST_LENGTH
    case .SHA224:
      result = CC_SHA224_DIGEST_LENGTH
    case .SHA256:
      result = CC_SHA256_DIGEST_LENGTH
    case .SHA384:
      result = CC_SHA384_DIGEST_LENGTH
    case .SHA512:
      result = CC_SHA512_DIGEST_LENGTH
    }
    return Int(result)
  }
}

extension String {
  func hmac(algorithm: HMACAlgorithm, key: String) -> String {
    let cKey = key.cString(using: String.Encoding.utf8)
    let cData = self.cString(using: String.Encoding.utf8)
    var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
    CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
    let hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
    let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
    return String(hmacBase64)
  }
}
