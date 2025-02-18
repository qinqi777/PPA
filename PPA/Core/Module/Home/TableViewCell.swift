//
//  TableViewCell.swift
//  PPA
//
//  Created by 秦琦 on 2024/12/13.
//

import UIKit
import CoreBluetooth

class TableViewCell: UITableViewCell {
    
    static let cellHeight = kRealValue(48)
    
    var peripheral: CBPeripheral? {
        didSet {
            titleLab.text = peripheral?.name
        }
    }
    
    private weak var titleLab: UILabel!
    private weak var contentLab: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let titleX = kRealValue(16)
        let titleW = kScreenWidth - 2 * titleX
        let titleLab = UILabel(frame: CGRect(x: titleX, y: 0, width: titleW, height: TableViewCell.cellHeight))
        titleLab.font = UIFont.systemFont(ofSize: kRealValue(14))
        titleLab.textColor = .black
        contentView.addSubview(titleLab)
        self.titleLab = titleLab
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

