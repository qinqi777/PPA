//
//  BTUtil.swift
//  PPA
//
//  Created by 秦琦 on 2024/12/24.
//  蓝牙工具

import UIKit
import CoreBluetooth
import CoreLocation

protocol BTUtilListener: NSObject {
    func btUtilDidDiscoverPeripheral(_ peripheral: CBPeripheral)
    func btUtilDidConnect()
    func btUtilDidDisconnect()
}

class BTUtil: NSObject {
    
    ///单例
    static let shared = BTUtil()
    
    var isWriting = false
    
    private lazy var btMgr: CBCentralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    private var listeners: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    override private init() {}
    
    func addListener(_ listener: BTUtilListener) {
        if !listeners.contains(listener) {
            listeners.add(listener)
        }
    }
    
    func removeListener(_ listener: BTUtilListener) {
        if listeners.contains(listener) {
            listeners.remove(listener)
        }
    }
    
    func startScaning() {
        if btMgr.isScanning {
            return
        }
        if btMgr.state == .poweredOn {
            //第一个参数nil就是扫描周围所有的外设
            btMgr.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func stopScaning() {
        btMgr.stopScan()
    }
    
    func connect(peripheral: CBPeripheral) {
        if self.peripheral == peripheral {
            listeners.setRepresentation.forEach { elem in
                (elem as? BTUtilListener)?.btUtilDidConnect()
            }
        } else {
            MBProgressHUD.showAdded(to: kMainWindow, animated: true).label.text = "正在连接..."
            self.peripheral = peripheral
            btMgr.connect(peripheral, options: nil)
        }
    }
    
    ///断开连接
    func disconnect(peripheral: CBPeripheral) {
        btMgr.cancelPeripheralConnection(peripheral)
    }
    
    ///写数据
    func writeString(_ gpsStr: String) {
        //只有 characteristic.properties 有write的权限才可以写
        if let value = gpsStr.data(using: .utf8), let characteristic = characteristic, characteristic.properties.union(.write).rawValue != 0 {
            isWriting = true
            peripheral?.writeValue(value, for: characteristic, type: .withResponse)
        } else {
            print("该字段不可写！");
        }
    }
    
}

extension BTUtil {
    
    func sendLocation(_ location: CLLocation) {
        if isWriting {
            return
        }
        var str = "", str1 = ""
        let sLat: String, sLon: String
        
        if location.coordinate.latitude >= 0 {
            sLat = D2DDm(location.coordinate.latitude)
        } else {
            sLat = "-" + D2DDm(location.coordinate.latitude * -1)
        }
        if location.coordinate.longitude >= 0 {
            sLon = D2DDDm(location.coordinate.longitude)
        } else {
            sLon = "-" + D2DDDm(location.coordinate.longitude * -1)
        }
        let crtTime = crtTime()
        
        str.append("GPRMC,")
        str.append(crtTime)
        str.append(",A,")
        //纬度Latitude
        str.append(sLat)
        str.append(",")
        str.append("N,")
        //经度Longitude
        str.append(sLon)
        str.append(",")
        str.append("E,")

        str.append("0.066,,")
        str.append(crtDate())   // formatUTC(System.currentTimeMillis(),"ddMMyy"));

        str.append(",,,A")   // End of GPSMC

        str1.append("GPGGA,");
        str1.append(crtTime)  //formatUTC(System.currentTimeMillis(),"HHmmss.00"))
        str1.append(",");

        //纬度Latitude
        str1.append(sLat)
        str1.append(",")
        str1.append("N,")
        //经度Longitude
        str1.append(sLon)
        str1.append(",")
        str1.append("E,")
        str1.append("1,")

        str1.append("05,1.48,");  // 卫星数

        str1.append(String(format: "%.1f", location.altitude))
        str1.append(",M,,M,,");     // 海拔
        
        let BCC = getBCC(str).uppercased()
        let BCC1 = getBCC(str1).uppercased()

        str.append("*")
        str.append(BCC)
        str.append("\r\n")
        
        str1.append("*")
        str1.append(BCC1)
        str1.append("\r\n")
        
        let gpsStr = "$" + str + "$" + str1
        
        print("最终的GpsStr：\(gpsStr)")
          
        writeString(gpsStr)
    }

    private func D2DDm(_ value: Double) -> String {
        let d = Int(value)
        let m = (value - Double(d)) * 60
        let sm = String(format: "%08.5f", m)
        return String(format: "%02d", d) + sm
    }
    
    private func D2DDDm(_ value: Double) -> String {
        let d = Int(value)
        let m = (value - Double(d)) * 60
        let sm = String(format: "%08.5f", m)
        return String(format: "%03d", d) + sm
    }
    
    private func crtTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmmss.00"
        return dateFormatter.string(from: Date())
    }
    
    private func crtDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMyy"
        return dateFormatter.string(from: Date())
    }
    
    private func getBCC(_ str: String) -> String {
        let strBytes = Array(str.utf8)
        var bcc = 0;
        for aByte in strBytes {
            bcc ^= Int(aByte)
        }
        return String(format: "%x", bcc)
    }
    
}

extension BTUtil: CBCentralManagerDelegate {
    
    ///主设备状态改变的委托，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("update state: unknown")
            break
        case .resetting:
            print("update state: resetting")
            break
        case .unsupported:
            print("update state: unsupported")
            break
        case .unauthorized:
            print("update state: unauthorized")
            break
        case .poweredOff:
            print("update state: poweredOff")
            break
        case .poweredOn:
            print("update state: poweredOn")
            startScaning()
            break
        @unknown default:
            break
        }
    }
    
    ///找到外设的委托
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, name.hasPrefix("Prazi") {
            listeners.setRepresentation.forEach { elem in
                (elem as? BTUtilListener)?.btUtilDidDiscoverPeripheral(peripheral)
            }
        }
    }
    
    //连接外设成功的委托
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MBProgressHUD.hide(for: kMainWindow, animated: true)
        MBProgressHUD.showAdded(to: kMainWindow, animated: true).label.text = "连接成功，正在扫描服务"
        //设置的peripheral委托CBPeripheralDelegate
        peripheral.delegate = self
        //扫描外设Services
        peripheral.discoverServices(nil)
    }
    
    ///外设连接失败的委托
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        MBProgressHUD.hide(for: kMainWindow, animated: true)
        self.peripheral = nil
        let alert = UIAlertController(title: "温馨提示", message: "连接到名称为 \(peripheral.name ?? "-") 的设备失败，原因：\(error?.localizedDescription ?? "-")", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler:nil))
        kMainWindow.rootViewController?.present(alert, animated: true)
    }
    
    ///断开外设的委托
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        MBProgressHUD.hide(for: kMainWindow, animated: true)
        self.peripheral = nil
        self.characteristic = nil
        listeners.setRepresentation.forEach { elem in
            (elem as? BTUtilListener)?.btUtilDidDisconnect()
        }
        let alert = UIAlertController(title: "温馨提示", message: "外设 \(peripheral.name ?? "-") 断开连接: \(error?.localizedDescription ?? "-")", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler:nil))
        kMainWindow.rootViewController?.present(alert, animated: true)
    }
    
}

extension BTUtil: CBPeripheralDelegate {
    
    ///扫描到Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        MBProgressHUD.hide(for: kMainWindow, animated: true)
        if let error = error {
            let alert = UIAlertController(title: "温馨提示", message: "扫描服务出错，原因：\(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler:nil))
            kMainWindow.rootViewController?.present(alert, animated: true)
            return
        }
        MBProgressHUD.showAdded(to: kMainWindow, animated: true).label.text = "正在扫描特征"
        peripheral.services?.forEach({ service in
            //扫描每个service的Characteristics
            peripheral.discoverCharacteristics(nil, for: service)
        })
    }
    
    ///扫描到Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        MBProgressHUD.hide(for: kMainWindow, animated: true)
        if let error = error {
            let alert = UIAlertController(title: "温馨提示", message: "扫描特征出错，原因：\(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler:nil))
            kMainWindow.rootViewController?.present(alert, animated: true)
            return
        }
        service.characteristics?.forEach({ characteristic in
            peripheral.readValue(for: characteristic)
            peripheral.discoverDescriptors(for: characteristic)
            if characteristic.uuid.uuidString == "FFF2" {
                self.characteristic = characteristic
//                peripheral.setNotifyValue(true, for: characteristic)
                listeners.setRepresentation.forEach { elem in
                    (elem as? BTUtilListener)?.btUtilDidConnect()
                }
            }
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        isWriting = false
        if let error = error {
            print(">>>didWriteValueFor characteristics \(characteristic.uuid) with error: \(error.localizedDescription)")
            return
        }
        print("didWriteValue - success")
    }
    
}
