//
//  KotlinBridge.swift
//  iOSMifuShufa
//
//  Created by lulixue on 2024/10/30.
//


func printlnDbg(_ any: Any...) {
#if DEBUG
  print(any)
#endif
}

func println(_ any: Any...) {
  print(any)
}
