//
//  Characters.swift
//  iOSChinesePoemDict
//
//  Created by 肖李根 on 8/8/21.
//

import Foundation

 
let DUNHAO: Character = "、"
let SHUMING_LEFT: Character =  "《"
let SHUMING_RIGHT: Character = "》"
let KUOHAO2_RIGHT: Char = "】"
let KUOHAO2_LEFT: Char = "【"
let SHUMING2_LEFT: Char = "「"
let SHUMING2_RIGHT: Char = "」"
let JIANGEHAO_BAN: Character = "·"
let JIANGEHAO: Character = "•"
let WENHAO: Character = "？"
let WENHAO_BAN: Character = "?"
let TANHAO: Character = "！"
let TANHAO_BAN: Character = "!"
let MAOHAO: Character = "："
let MAOHAO_BAN: Character = ":"
let KUOHAO_LEFT: Character = "（"
let KUOHAO_RIGHT: Character = "）"
let KUOHAO_HALF_LEFT: Character = "("
let KUOHAO_HALF_RIGHT: Character = ")"
let DUIOU_LEFT: Character = "『"
let DUIOU_RIGHT: Character = "』"
let DIEYUN_LEFT: Character = "〖"
let DIEYUN_RIGHT: Character = "〗"

let SHIKUOHAO_LEFT: Character = "【"
let SHIKUOHAO_RIGHT: Character = "】"
let SHANG: Character = "上"
let QU: Character = "去"
let RU: Character = "入"
let PING: Character = "平"
let ZE: Character = "仄"
let ZHONG: Character = "中"
let JUHAO: Character = "。"
let JUHAO_BAN: Character = "."
let DOUHAO_BAN: Character = ","
let DOUHAO: Character = "，"
let FENHAO: Character = "；"
let FENHAO_BAN: Character = ";"
let RETURN_CHAR: Character = "\r"
let NEWLINE_CHAR: Character = "\n"
let SPACE_CHAR: Character = " "

let SHICI_SEPARATORS = [JUHAO, JUHAO_BAN, DOUHAO, DOUHAO_BAN, FENHAO, FENHAO_BAN, WENHAO, WENHAO_BAN,
                                           TANHAO, TANHAO_BAN, MAOHAO, MAOHAO_BAN, JIANGEHAO, JIANGEHAO_BAN]
let END_SEPARATORS = [JUHAO, JUHAO_BAN, WENHAO, WENHAO_BAN, TANHAO, TANHAO_BAN, NEWLINE_CHAR, RETURN_CHAR, MAOHAO_BAN, MAOHAO]

let SHICI_END_SEPARATORS = {
  var separators = END_SEPARATORS
  separators.add(SHUMING2_RIGHT)
  separators.add(DUIOU_RIGHT)
  separators.add(DIEYUN_RIGHT)
  separators.add(SHIKUOHAO_RIGHT)
  separators.add(FENHAO)
  separators.add(FENHAO_BAN)
  return separators
}()

let MID_SEPARATORS = [WENHAO, WENHAO_BAN, TANHAO, TANHAO_BAN, MAOHAO, MAOHAO_BAN ]
let QU_JU_SEPARATORS = [JUHAO, JUHAO_BAN, DOUHAO, DOUHAO_BAN, FENHAO, FENHAO_BAN, WENHAO, WENHAO_BAN,
                                           TANHAO, TANHAO_BAN, MAOHAO, MAOHAO_BAN, NEWLINE_CHAR]
