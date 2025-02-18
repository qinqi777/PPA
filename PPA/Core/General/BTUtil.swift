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
    
    private lazy var dateFmt: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }()
    
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    private var listeners: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    override private init() {}
    
    func addListener(_ listener: BTUtilListener) {
        if !listeners.contains(listener) {
//            print("\(getCurDate())  addListener添加监听器,\(listener)")
            listeners.add(listener)
        }
    }
    
    func removeListener(_ listener: BTUtilListener) {
        if listeners.contains(listener) {
//            print("\(getCurDate())  removeListener移除监听器,\(listener)")
            listeners.remove(listener)
        }
    }
    
    func startScaning() {
//        print("\(getCurDate())  ~~~~startScaning,已经开始的话不重复开始~~~")
        if btMgr.isScanning {
            return
        }
//        print("\(getCurDate())  ~~~~startScaning，真正开始扫描~~~")

        if btMgr.state == .poweredOn {
            //第一个参数nil就是扫描周围所有的外设
            btMgr.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func stopScaning() {
//        print("\(getCurDate())  ~~~~stopScaning~~~")
        btMgr.stopScan()
    }
    
    // shiva
    // 添加超时时间的实现
//    func connect(peripheral: CBPeripheral) {
//        MBProgressHUD.showAdded(to: kMainWindow, animated: true).label.text = "正在连接..."
//        self.peripheral = peripheral
//        btMgr.connect(peripheral, options: nil)
//
//        // 设置超时，比如 10 秒
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
//            guard let self = self else { return }
//            if self.peripheral?.state != .connected {
//                self.btMgr.cancelPeripheralConnection(peripheral)
//                MBProgressHUD.hide(for: kMainWindow, animated: true)
//                let alert = UIAlertController(title: "温馨提示", message: "连接超时，请重试", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
//                kMainWindow.rootViewController?.present(alert, animated: true)
//            }
//        }
//    }
    
    // 原始实现
    func connect(peripheral: CBPeripheral) {
//        print("\(getCurDate()) connect方法，准备开始连接设备同时关闭扫描咯~~~~。btMgr的状态:\(btMgr.state)")
        stopScaning()
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
//        print("\(getCurDate()) disconnect同时开始扫描咯。。。btMgr的状态:\(btMgr.state)")
        startScaning()
        btMgr.cancelPeripheralConnection(peripheral)
    }
    
    ///写数据
    func writeString(_ gpsStr: String) {
//        print("\(getCurDate()) writeString方法。btMgr的状态:\(btMgr.state)")
        //只有 characteristic.properties 有write的权限才可以写
        if let value = gpsStr.data(using: .utf8), let characteristic = characteristic, characteristic.properties.union(.write).rawValue != 0 {
            isWriting = true
            peripheral?.writeValue(value, for: characteristic, type: .withResponse)
        } else {
            print("该字段不可写！");
        }
    }
    // shiva
//    func writeString(_ gpsStr: String) {
//        guard let characteristic = characteristic, characteristic.properties.contains(.write) else {
//            print("该字段不可写！")
//            return
//        }
//
//        let data = gpsStr.data(using: .utf8)!
//        let mtu = 20  // iOS BLE 4.2 及以下最多20字节
//        var offset = 0
//
//        isWriting = true
//        var i = 0 ;
//        while offset < data.count {
//            i = i+1;
//            let chunkSize = min(mtu, data.count - offset)
//            let chunk = data.subdata(in: offset..<(offset + chunkSize))
//            let backToString = String(data: chunk, encoding: .utf8)
//            print("第 \(i)次写，内容为：\(backToString)")
//            peripheral?.writeValue(chunk, for: characteristic, type: .withResponse)
//            offset += chunkSize
//            Thread.sleep(forTimeInterval: 0.02)  // 避免短时间内发送过多数据
//        }
//    }
    
}

extension BTUtil {
    
    func sendLocation(_ location: CLLocation) {
//        print("\(getCurDate()) sendLocation方法中 isWriting=:\(isWriting)")
//        print("\(getCurDate()) 位置信息\(location.coordinate.longitude),\(location.coordinate.latitude )")

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
        str.append(crtTime)// 字段 1: UTC 时间（如 "HHmmss.00"）
        str.append(",A,")  // 字段 2: "A"（状态指示，A=有效，V=无效）
        //纬度Latitude
        str.append(sLat) // 字段 3: 纬度（格式 "ddmm.mmmmm"）
        str.append(",")
        str.append("N,") // 字段 4: "N"（纬度方向，N=北纬，S=南纬）
        //经度Longitude
        str.append(sLon) // 字段 5: 经度（格式 "dddmm.mmmmm"）
        str.append(",")
        str.append("E,")  // 字段 6: "E"（经度方向，E=东经，W=西经）

        str.append("0.01,,")// 字段 7: 地面速度（单位：节） 字段 8: 航向角（为空）
        str.append(crtDate()) // 字段 9: UTC 日期（格式 "ddMMyy"）  // formatUTC(System.currentTimeMillis(),"ddMMyy"));

        str.append(",,,A")// 字段 10: 磁偏角（为空）
        // 字段 11: 磁偏角方向（为空）
        // 字段 12: "A"（模式指示符，A=自主，D=差分）
        // *字段 13:*区分，校验和
        // End of GPSMC

        str1.append("GPGGA,");// 字段 0: "GPGGA"（语句类型，GPS 定位数据）
        str1.append(crtTime)   // 字段 1: UTC 时间（格式 "HHmmss.00"）//formatUTC(System.currentTimeMillis(),"HHmmss.00"))
        str1.append(",");

        //纬度Latitude
        str1.append(sLat)  // 字段 2: 纬度（格式 "ddmm.mmmmm"）
        str1.append(",")
        str1.append("N,") // 字段 3: "N"（纬度方向，N=北纬，S=南纬）

        //经度Longitude
        str1.append(sLon)  // 字段 4: 经度（格式 "dddmm.mmmmm"）
        str1.append(",")
        str1.append("E,") // 字段 5: "E"（经度方向，E=东经，W=西经）
        str1.append("1,") // 字段 6: GPS 状态（0=无定位，1=单点定位，2=差分定位）

        

        str1.append("05,1.48,");  // 卫星数
                                // 字段 7: 卫星数（若小于 5，则填 "5"）
                                // 字段 8: HDOP（水平精度因子）
        

        str1.append(String(format: "%.1f", location.altitude)) // 字段 9: 海拔高度（单位：米）
        str1.append(",M,,M,,");
                        // 字段 10: 高度单位（"M"=米）// 海拔
                        // 字段 11: 大地水准面高度（为空）
                        // 字段 12: 高度单位（"M"=米）
                        // 字段 13: 差分 GPS 数据时间（为空）
        
        let BCC = getBCC(str).uppercased()
        let BCC1 = getBCC(str1).uppercased()

        str.append("*")
        str.append(BCC)
        str.append("\r\n")
        
        str1.append("*") // 字段 14: 差分参考站 ID（为空）
        str1.append(BCC1)// 字段 15 *分割-:  BCC 校验值（不计入字段编号）
        str1.append("\r\n")
        
        let gpsStr = "$" + str + "$" + str1
        
//        print("当前系统时间: \(getCurDate())")
        
//        print("发送给设备的GpsStr：\(gpsStr)")
          
        writeString(gpsStr)
    }
    
    private func getCurDate()  -> String {
        // 获取当前系统时间
        let currentDate = Date()
        // 格式化时间输出
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // 设定日期格式
        formatter.timeZone = TimeZone.current         // 使用系统当前时区
        let dateString = formatter.string(from: currentDate)
        return dateString
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
        dateFmt.dateFormat = "HHmmss.00"
        return dateFmt.string(from: Date())
    }
    
    private func crtDate() -> String {
        dateFmt.dateFormat = "ddMMyy"
        return dateFmt.string(from: Date())
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
//        print("枚举状态说明~~")
//        print("unknown = 0")
//        print("resetting = 1")
//        print("unsupported = 2")
//        print("unauthorized = 3")
//        print("poweredOff = 4")
//        print("poweredOn = 5")

        
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
//            print("\(getCurDate()) 我要开始扫描咯~~~")
            startScaning()
            break
        @unknown default:
            break
        }
    }
    
    ///找到外设的委托
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, name.hasPrefix("Prazi") {
//            print("\(getCurDate()) didDiscover发现Prazi外设。btMgr的状态:\(btMgr.state) , advertisementData = \(advertisementData)")

            listeners.setRepresentation.forEach { elem in
                (elem as? BTUtilListener)?.btUtilDidDiscoverPeripheral(peripheral)
            }
        }
    }
    
    //连接外设成功的委托
//    func centralManager(_ central:CBCentralManager , didConnect peripheral: CBPeripheral){
//        let alert = UIAlertController(title: "温馨提示", message: "连接到名称为 \(peripheral.name ?? "-") 的设备成功。", preferredStyle: .alert);
//    }
    
    
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
//        print("\(getCurDate()) didFailToConnect外设连接失败的委托。btMgr的状态:\(btMgr.state)")
        startScaning()
        MBProgressHUD.hide(for: kMainWindow, animated: true)
        self.peripheral = nil
        let alert = UIAlertController(title: "温馨提示", message: "连接到名称为 \(peripheral.name ?? "-") 的设备失败，原因：\(error?.localizedDescription ?? "-")", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler:nil))
        kMainWindow.rootViewController?.present(alert, animated: true)
    }
    
    ///断开外设的委托
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
//        print("\(getCurDate()) didDisconnectPeripheral断开外设的委托。btMgr的状态:\(btMgr.state)")
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
//        print("\(getCurDate()) didDiscoverServices方法，扫描service。")

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
