//
//  HistoryData.swift
//  PPA
//
//  Created by 秦琦 on 2024/12/13.
//

import UIKit

class HistoryData {
    
    var fileName: String?
    var urlStr: String?
    var methodNames: [String]?
    
}

class HistoryFrame {
    
    var data: HistoryData
    
    private(set) var titleFrame: CGRect
    private(set) var contentFrame: CGRect
    private(set) var cellHeight: CGFloat
    
    private(set) var titleFont: UIFont
    private(set) var contentFont: UIFont
    
    private(set) var titleStr: String
    private(set) var contentStr: String
    
    init(_ data: HistoryData) {
        self.data = data
        
        let titleX = kRealValue(16), titleY = kRealValue(12)
        let titleW = kScreenWidth - 2 * titleX
        
        titleFont = UIFont.systemFont(ofSize: kRealValue(14))
        titleStr = "URL：" + (data.urlStr ?? "无")
        let titleH = ceil((titleStr as NSString).boundingRect(with: CGSize(width: titleW, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: titleFont], context: nil).size.height)
        titleFrame = CGRectMake(titleX, titleY, titleW, titleH)
        
        contentFont = UIFont.systemFont(ofSize: kRealValue(14))
        contentStr = "调用Native的方法名："
        if let arr = data.methodNames, arr.count > 0 {
            for (i, name) in arr.enumerated() {
                if i != 0 {
                    contentStr += "、"
                }
                contentStr += name
            }
        } else {
            contentStr += "无"
        }
        let contentH = ceil((contentStr as NSString).boundingRect(with: CGSize(width: titleW, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: contentFont], context: nil).size.height)
        contentFrame = CGRectMake(titleX, CGRectGetMaxY(titleFrame) + kRealValue(8), titleW, contentH)
        
        cellHeight = CGRectGetMaxY(contentFrame) + titleY
        
    }
    
    
    
}
