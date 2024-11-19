//
//  Filters.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/11/6.
//
import Collections

let STROKE_NANJIANZI = 254
let STROKE_OTHERS = 255  // 笔画数，偏旁部首

var NANJIANZI: String { "难检字".orCht("難檢字") }
let OTHERS: String = "其他"
var STROKE: String { "画".orCht("畫") }

  // 结构
let STRUCTURE_DICT = {
  var structures = OrderedDictionary<String, List<String>>()
  
  structures["口"] = Array.arrayOf("单一", "單一")
  structures["⿰"] = Array.arrayOf("左右")
  structures["⿱"] = Array.arrayOf("上下")
  structures["⿲"] = Array.arrayOf("左中右")
  structures["⿳"] = Array.arrayOf("上中下")
  structures["⿴"] = Array.arrayOf("全包围", "全包圍")
  structures["⿵"] = Array.arrayOf("上三包围", "上三包圍")
  structures["⿶"] = Array.arrayOf("下三包围", "下三包圍")
  structures["⿷"] = Array.arrayOf("左三包围", "左三包圍")
  structures["⿸"] = Array.arrayOf("左上包围", "左上包圍")
  structures["⿹"] = Array.arrayOf("右上包围", "右上包圍")
  structures["⿺"] = Array.arrayOf("左下包围", "左下包圍")
  structures["⿻"] = Array.arrayOf("镶嵌", "鑲嵌")
  structures["田"] = Array.arrayOf("田字")
  structures["品"] = Array.arrayOf("品字")
  return structures
}()

let STRUCTURE_CHS_CHT = {
  var map = [String: String]()
  for (k, v) in STRUCTURE_DICT {
    map[v[0]] = (v.size > 1) ? v[1] : v[0]
  }
  return map
}()


let STRUCTURE_CHT_CHS = {
  var map = [String: String]()
  for (k, v) in STRUCTURE_CHS_CHT {
    map[v] = k
  }
  return map
}()

extension Int {
  var radicalCountName: String {
    switch self {
    case STROKE_NANJIANZI: NANJIANZI
    case STROKE_OTHERS: OTHERS
    default:
      ChineseHelper.numberToChineseIndex(number: self) + STROKE
    }
  }
}

let RADICAL_DICT = {
  var map = OrderedDictionary<Int, List<String>>()
  map[1] = Array.listOf("丨","亅","丿","乛","一","乙","乚","丶")
  map[2] = Array.listOf("八","勹","匕","冫","卜","厂","刀","刂","儿","二",
                  "匚","阝","丷","几","卩","冂","力","冖","凵","人", "亻","入","十","厶","亠","匸","讠","廴","又")
  map[3] = Array.listOf("艹","屮","彳","巛","川","辶","寸","大","飞","干",
                  "工","弓","廾","广","己","彐","彑","巾","口","马", "门","宀","女","犭","山","彡","尸","饣","士","扌",
                  "氵","纟","巳","土","囗","兀","夕","小","忄","幺", "弋","尢","夂","子")
  map[4] = Array.listOf("贝","比","灬","长","车","歹","斗","厄","方","风",
                  "父","戈","卝","户","火","旡","见","斤","耂","毛", "木","肀","牛","牜","爿","片","攴","攵","气","欠",
                  "犬","日","氏","礻","手","殳","水","瓦","尣","王", "韦","文","毋","心","牙","爻","曰","月","爫","支", "止","爪")
  map[5] = Array.listOf("白","癶","歺","甘","瓜","禾","钅","立","龙","矛",
                  "皿","母","目","疒","鸟","皮","生","石","矢","示", "罒","田","玄","穴","疋","业","衤","用","玉")
  map[6] = Array.listOf("耒","艸","臣","虫","而","耳","缶","艮","虍","臼",
                  "米","齐","肉","色","舌","覀","页","先","行","血", "羊","聿","至","舟","衣","竹","自","羽","糸","糹")
  map[7] = Array.listOf("貝","采","镸","車","辰","赤","辵","豆","谷","見",
                  "角","克","里","卤","麦","身","豕","辛","言","邑", "酉","豸","走","足")
  map[8] = Array.listOf("青","靑","雨","齿","長","非","阜","金","釒","隶",
                  "門","靣","飠","鱼","隹")
  map[9] = Array.listOf("風","革","骨","鬼","韭","面","首","韋","香","頁", "音")
  map[10] = Array.listOf("髟","鬯","鬥","高","鬲","馬")
  map[11] = Array.listOf("黄","鹵","鹿","麻","麥","鳥","魚")
  map[12] = Array.listOf("鼎","黑","黽","黍","黹")
  map[13] = Array.listOf("鼓","鼠")
  map[14] = Array.listOf("鼻","齊")
  map[15] = Array.listOf("齒","龍","龠")
  map[STROKE_NANJIANZI] = Array.listOf(NANJIANZI)
  map[STROKE_OTHERS] = Array.listOf(OTHERS)
  return map
}()

let STROKE_CHS_CHT_PAIRS: [Char: Char] = [
  "钩": "鈎",
  "竖": "豎",
  "弯": "彎",
  "点": "點"
]

let STROKE_CHT_CHS_PAIRS = {
  var map = [Char: Char]()
  for (k, v) in STROKE_CHS_CHT_PAIRS {
    map[v] = k
  }
  return map
}()


let BASIC_HSTROKES = {
  var strokes = LinkedHashMap<Char, List<String>>()
  strokes["㇐"] = Array.arrayOf( "横", "heng", "h", "二" ) /* 二 */
  strokes["㇀"] = Array.arrayOf( "提", "ti", "t", "冰" ) /* 冰 */
  strokes["㇖"] = Array.arrayOf( "横钩", "henggou", "hg", "了" ) /* 了 */
  strokes["㇇"] = Array.arrayOf( "横撇", "hengpie", "hp", "又" ) /* 又 */
  strokes["㇕"] = Array.arrayOf( "横折", "hengzhe", "hz", "口" ) /* 口 */
  strokes["㇆"] = Array.arrayOf( "横折钩", "hengzhegou", "hzg", "羽" ) /* 羽 */
  strokes["㇊"] = Array.arrayOf( "横折提", "hengzheti", "hzt", "计" ) /* 计 */
  strokes["㇅"] = Array.arrayOf( "横折折", "hengzhezhe", "hzz", "凹" ) /* 凹 */
  strokes["㇍"] = Array.arrayOf( "横折弯", "hengzhewan", "hzw", "朵" ) /* 朵 */
  strokes["㇈"] = Array.arrayOf( "横折弯钩", "hengzhewangou", "hzwg", "几，風" ) /* 飞风 */
  strokes["㇠"] = Array.arrayOf( "横斜弯钩", "hengxiewangou", "hxwg", "乞" ) /* 乞 */
  strokes["㇎"] = Array.arrayOf( "横折折折", "hengzhezhezhe", "hzzz", "凸" ) /* 凸 */
  strokes["㇋"] = Array.arrayOf( "横折折撇", "hengzhezhepie", "hzzp", "及" ) /* 及 */
  strokes["㇌"] = Array.arrayOf( "横撇弯钩", "hengpiewangou", "hpwg", "除" ) /* 队 */
  strokes["㇡"] = Array.arrayOf( "横折折折钩", "hengzhezhezhegou", "hzzzg", "乃" ) /* 乃 */
  return strokes
}()

let BASIC_SSTROKES = {
  var strokes = LinkedHashMap<Char, List<String>>()
  strokes["㇑"] = Array.arrayOf( "竖", "shu", "s", "中" ) /* 中 */
  strokes["㇚"] = Array.arrayOf( "竖钩", "shugou", "sg", "求" ) /* 求 */
  strokes["㇙"] = Array.arrayOf( "竖提", "shuti", "st", "以" ) /* 以 */
  strokes["㇗"] = Array.arrayOf( "竖折", "shuzhe", "sz", "山" )    /* 山 */
  strokes["㇄"] = Array.arrayOf( "竖弯", "shuwan", "sw", "四、西" ) /* 四 西 */
  strokes["㇟"] = Array.arrayOf( "竖弯钩", "shuwangou", "swg", "己、孔" ) /* 己，乱，儿 */
  strokes["㇘"] = Array.arrayOf( "竖弯左", "shuwanzuo", "swz", "肅" ) /* 肅 */
  strokes["㇞"] = Array.arrayOf( "竖折折", "shuzhezhe", "szz", "鼎" ) /* 鼎 */
  strokes["㇉"] = Array.arrayOf( "竖折弯钩", "shuzhewangou", "szwg", "兮" ) /* 兮 */
  return strokes
}()


let BASIC_PSTROKES = {
  var strokes = LinkedHashMap<Char, List<String>>()
  strokes["㇒"] = Array.arrayOf( "撇", "pie", "p", "八" ) /* 八 */
  strokes["㇓"] = Array.arrayOf( "竖撇", "shupie", "sp", "几" ) /* 几 */
  strokes["㇢"] = Array.arrayOf( "撇钩", "piegou", "pg", "乄 " ) /* 乄  */
  strokes["㇜"] = Array.arrayOf( "撇折", "piezhe", "pz", "弘" ) /* 弘 */
  strokes["㇛"] = Array.arrayOf( "撇点", "piedian", "pd", "女" ) /* 女 */
  return strokes
}()

let BASIC_DSTROKES = {
  var strokes = LinkedHashMap<Char, List<String>>()
  strokes["㇔"] = Array.arrayOf( "点", "dian", "d", "丸，刃") /* 丸 刃 */
  strokes["㇏"] = Array.arrayOf( "捺", "na", "n", "大" ) /* 大 */
  strokes["㇝"] = Array.arrayOf( "提捺", "tina", "tn", "之，近" ) /* 之 */
  return strokes
}()

let BASIC_GSTROKES = {
  var strokes = LinkedHashMap<Char, List<String>>()
  strokes["㇂"] = Array.arrayOf( "斜钩", "xiegou", "xg", "戈" ) /* 戈 */
  strokes["㇃"] = Array.arrayOf( "扁斜钩", "bianxiegou", "bxg", "心" ) /* 心 */
  strokes["㇁"] = Array.arrayOf( "弯钩", "wangou", "wg", "狐，家") /* 狐家 */
  strokes["㇣"] = Array.arrayOf( "圈", "quan", "q", "〇" ) /* 〇 */
  return strokes
}()

let ALL_STROKES = [BASIC_HSTROKES, BASIC_SSTROKES, BASIC_PSTROKES, BASIC_DSTROKES, BASIC_GSTROKES]

let STROKE_ITEM_MAP = {
  var map = [String: String]()
  
  for strokes in ALL_STROKES {
    for (_, v) in strokes {
      let key = v[0]
      let value = v[2]
      let cht = key.toChtStroke()
      map[key] = value
      map[cht] = value
    }
  }
  
  return map
}()

extension OrderedDictionary {
  func containsKey(_ key: Key) -> Bool {
    self.keys.contains(key)
  }
}

extension Char {
  var this: Char {
    self
  }
  
  func toStrokeInit() -> String {
    for it in ALL_STROKES {
      if it.containsKey(self){
        return it[this]![2]
      }
    }
    return ""
  }
}

extension String {
  func toSearchStructure() -> String {
    STRUCTURE_CHT_CHS[this] ?? this
  }
  
  func toSearchStroke() -> String {
    STROKE_ITEM_MAP[this] ?? this
  }
  
  func toChsStroke() -> String {
    var sb = StringBuilder()
    for c in self {
      sb.append(STROKE_CHT_CHS_PAIRS[c] ?? c)
    }
    return sb
  }
  
  func toChtStroke() -> String {
    var sb = StringBuilder()
    for c in self {
      sb.append(STROKE_CHS_CHT_PAIRS[c] ?? c)
    }
    return sb
  }
}
