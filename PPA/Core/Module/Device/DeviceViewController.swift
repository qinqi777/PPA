//
//  DeviceViewController.swift
//  PPA
//
//  Created by 秦琦 on 2024/12/13.
//  已连接的设备

import UIKit
import MAMapKit
import CoreBluetooth

class DeviceViewController: UIViewController {
    
    private weak var mapView: MAMapView?
    private var timer: Timer?
    private var location: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "GPS传输"
        view.backgroundColor = .white
        configureSubviews()
        BTUtil.shared.addListener(self)
    }
    
    deinit {
        stopSendLocation()
        BTUtil.shared.removeListener(self)
    }
    
    @objc private func gpsSwitchValueChanged(_ gpsSwitch: UISwitch) {
        if gpsSwitch.isOn {
            beginSendLocation()
        } else {
            stopSendLocation()
        }
    }
    
    @objc private func rightBtnClicked(_ btn: UIButton) {
        if let location = location {
            mapView?.setCenter(location.coordinate, animated: true)
        }
    }
    
    private func beginSendLocation() {
        stopSendLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if let location = self?.location {
                BTUtil.shared.sendLocation(location)
            }
        }
    }
    
    private func stopSendLocation() {
        if timer?.isValid == true {
            timer?.invalidate()
            timer = nil
        }
    }
    
}

extension DeviceViewController: BTUtilListener {
    
    func btUtilDidDiscoverPeripheral(_ peripheral: CBPeripheral) {
        
    }
    
    func btUtilDidConnect() {
        
    }
    
    func btUtilDidDisconnect() {
        navigationController?.popViewController(animated: true)
    }
    
}

extension DeviceViewController: MAMapViewDelegate {
    
    func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
        if location == nil {
            if let location = userLocation.location {
                mapView.setCenter(location.coordinate, animated: true)
            }
        }
        location = userLocation.location
    }
    
}

extension DeviceViewController {
    
    private func configureSubviews() {
        let gpsSwitch = UISwitch()
        gpsSwitch.addTarget(self, action: #selector(gpsSwitchValueChanged(_:)), for: .valueChanged)
        view.addSubview(gpsSwitch)
        gpsSwitch.mj_x = kRealValue(16)
        gpsSwitch.mj_y = kNavBarHeight + kRealValue(32)
        
        let rightBtn = UIButton(type: .system)
        rightBtn.frame = CGRect(x: kScreenWidth - kRealValue(80), y: gpsSwitch.mj_y, width: kRealValue(60), height: gpsSwitch.mj_h)
        rightBtn.titleLabel?.font = .systemFont(ofSize: kRealValue(14))
        rightBtn.setTitle("我的位置", for: .normal)
        rightBtn.contentHorizontalAlignment = .right
        rightBtn.addTarget(self, action: #selector(gpsSwitchValueChanged(_:)), for: .valueChanged)
        view.addSubview(rightBtn)
        
        let mapY = gpsSwitch.frame.maxY + kRealValue(24)
        let mapH = kScreenHeight - mapY
        let mapView = MAMapView(frame: CGRect(x: 0, y: mapY, width: kScreenWidth, height: mapH))
        mapView.delegate = self
        mapView.allowsBackgroundLocationUpdates = true
        mapView.showsUserLocation = true
        mapView.isShowTraffic = true
        mapView.setZoomLevel(13, animated: true)
        view.addSubview(mapView)
        self.mapView = mapView
    }
    
}
