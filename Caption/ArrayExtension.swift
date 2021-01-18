//
//  ArrayExtension.swift
//  Caption
//
//  Created by Qian on 2021/1/18.
//

import Foundation

extension Array {
    
    /*
     let numbers = Array(1...12)
     let result = numbers.chunked(into: 5)
     print(result) // [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12]]
     */
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    /*
     用序号 [ 1, 4, 5 ] 切分数组
     ["a","b","c","d","e","f","g","h"] -> [["a","b"],["c","d","e"],["f"],["g","h"]]
     */
    func chunked(by indexes: [Array.Index]) -> [[Element]] {
        guard count > 0 else {
            return [[Element]]()
        }
        
        // 删除 indexes 中不合法的序号（负数、超出范围），然后递增排序
        let safeIndexes = indexes.filter { $0 >= 0 && $0 < count }.sorted(by:<)
        
        var array = self
        var chunked = safeIndexes.map { (separtor) -> [Element] in
            let right = separtor - (self.count - array.count)
            let sub = Array(array[...right])
            array.removeSubrange(...right)
            return sub
        }
        chunked.append(array)
        
        return chunked
    }
    
}
