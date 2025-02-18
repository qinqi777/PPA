//
//  ViewController.swift
//  PPA
//
//  Created by 秦琦 on 2024/12/13.
//  主页

import UIKit
import CoreBluetooth
import CoreLocation

class ViewController: UIViewController {
    
    
    private weak var tableView: UITableView!
    
    private var dataArr = [CBPeripheral]()
    ///状态管理
    private lazy var statusMgr: CLLocationManager = {
        let statusMgr = CLLocationManager()
        return statusMgr
    }()
    
    private lazy var noDataLab: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kRealValue(30)))
        label.font = .systemFont(ofSize: kRealValue(16))
        label.textColor = .lightGray
        label.textAlignment = .center
        label.text = "暂无可连接的设备"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.        
        let tableView = UITableView(frame: CGRect(x: 0, y: kNavBarHeight, width: kScreenWidth, height: kScreenHeight - kNavBarHeight), style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "TableViewReuse")
        view.addSubview(tableView)
        self.tableView = tableView
        
        tableView.tableFooterView = noDataLab
        
        BTUtil.shared.addListener(self)
        
        locationAuth()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BTUtil.shared.startScaning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BTUtil.shared.stopScaning()
    }

    deinit {
        BTUtil.shared.removeListener(self)
    }
    
    private func locationAuth() {
        if CLLocationManager.locationServicesEnabled() {
            if statusMgr.authorizationStatus == .notDetermined {
                statusMgr.requestAlwaysAuthorization()
            }
        }
    }

}

extension ViewController: BTUtilListener {
    
    func btUtilDidDiscoverPeripheral(_ peripheral: CBPeripheral) {
        if !dataArr.contains(peripheral) {
            dataArr.append(peripheral)
            if dataArr.count == 0 {
                tableView.tableFooterView = noDataLab
            } else {
                tableView.tableFooterView = nil
            }
            tableView.reloadData()
        }
    }
    
    func btUtilDidConnect() {
        if statusMgr.authorizationStatus == .authorizedAlways || statusMgr.authorizationStatus == .authorizedWhenInUse {
            let vc = DeviceViewController()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let alert = UIAlertController(title: "温馨提示", message: "无定位权限，请前往系统设置中开启", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler:nil))
            kMainWindow.rootViewController?.present(alert, animated: true)
        }
    }
    
    func btUtilDidDisconnect() {
        
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewReuse", for: indexPath) as! TableViewCell
        cell.peripheral = dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TableViewCell.cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        BTUtil.shared.connect(peripheral: dataArr[indexPath.row])
    }
    
}
