//
//  DataManager.swift
//  PPA
//
//  Created by 秦琦 on 2024/12/13.
//

import Foundation

class DataManager {
    
    static var rootPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/history"
    }
    
    class func getList(completion: (([HistoryData]) -> ())) {
        var result = [HistoryData]()
        FileManager.default.subpaths(atPath: rootPath)?.forEach({ fileName in
            let filePath = rootPath + "/" + fileName
            if let fileData = NSData(contentsOfFile: filePath) as? Data, let dict = try? JSONSerialization.jsonObject(with: fileData) as? [String: Any] {
                let data = HistoryData()
                data.urlStr = dict["urlStr"] as? String
                data.methodNames = dict["methodNames"] as? [String]
                data.fileName = dict["fileName"] as? String
                result.append(data)
            }
        })
        completion(result)
    }
    
    class func addHistory(_ data: HistoryData) {
        if !FileManager.default.fileExists(atPath: rootPath) {
            try? FileManager.default.createDirectory(atPath: rootPath, withIntermediateDirectories: true)
        }
        let fileName = String(Int(Date().timeIntervalSince1970 * 1000)) + ".data"
        data.fileName = fileName
        
        var dict = [String: Any]()
        dict["urlStr"] = data.urlStr
        dict["methodNames"] = data.methodNames
        dict["fileName"] = data.fileName
        
        if let fileData = try? JSONSerialization.data(withJSONObject: dict) {
            let filePath = rootPath + "/" + fileName
            let url = URL(fileURLWithPath: filePath)
            try? fileData.write(to: url)
        }
    }
    
    class func deleteHistory(_ data: HistoryData) {
        guard let fileName = data.fileName else {
            return
        }
        let filePath = rootPath + "/" + fileName
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        }
    }
    
}
