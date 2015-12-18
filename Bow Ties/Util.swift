//
//  Util.swift
//  Bow Ties
//
//  Created by 丁丁 on 15/12/15.
//  Copyright © 2015年 Razeware. All rights reserved.
//

import UIKit
class Util: NSObject {
    
    override init() {
        
    }
    func stringIsFirstNum(str:String) -> Bool {
        
        return stringIsCurrentStr(str, numbers: "012345\\b")
    }
    
    func stringIsDot(str:String) -> Bool {
        return stringIsCurrentStr(str, numbers: ".\\b")
    }
    
    func stringIsBasicNums(str:String) -> Bool {
        return stringIsCurrentStr(str, numbers: "0123456789\\b")
    }
    
    func stringIsCurrentStr(str:String,numbers:String) -> Bool {
        let cs = NSCharacterSet.init(charactersInString: numbers).invertedSet
        let filtered = str.componentsSeparatedByCharactersInSet(cs).joinWithSeparator("")
        let isBasic = (str == filtered)
        return isBasic;
    }
    
    
}
