//
//  ViewController.swift
//  ThirdPartyAnimation_Swift
//
//  Created by MR.Sahw on 2020/11/17.
//

import UIKit
import CoreBluetooth

let heartRateUUID = [CBUUID(string: "6F50B783-44A7-4654-AD31-3046A3345497")]
let controPointCharacteristicUUID = CBUUID(string: "5B8A6CA2-5993-4516-B76B-9F032A14D2EA")
let sensortLoctionCharacteristicUUID = CBUUID(string: "95314954-3CA6-476B-8C54-03C9635B2D6A")
let measurmentCharacteristicUUID = CBUUID(string: "D85B7722-10C8-4453-A81A-ABE3DA4389AB")

class ViewController: UIViewController {

    @IBOutlet weak var writeCharacterisTextField: UITextField!
    @IBOutlet weak var sensorLoctionLable: UILabel!
    @IBOutlet weak var hartRateLable: UILabel!
    
    var contralManger : CBCentralManager!
    var heartRateperipheral    : CBPeripheral!
    var contropiontCharacteristic : CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 创建中心设备管理器
        contralManger = CBCentralManager(delegate: self, queue: nil)
    }

    @IBAction func write(_ sender: Any) {
        guard let contropiontCharacteristic = contropiontCharacteristic else {return}
        heartRateperipheral.writeValue(writeCharacterisTextField.text!.data(using: .utf8)!, for: contropiontCharacteristic, type: .withResponse)
    }
    
}

extension ViewController : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("未知")
        case .resetting:
            print("蓝牙重置中")
        case .unsupported:
            print("本机不支持BLE")
        case .unauthorized:
            print("未授权")
        case .poweredOff:
            print("蓝牙未开启")
        case .poweredOn:
            print("蓝牙开启")
            central.scanForPeripherals(withServices: heartRateUUID)
        @unknown default:
            print("来自未来的错误")
        }
    }
    // 上一步扫描完成后 发现外设
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        heartRateperipheral = peripheral // 需要定义一个全局变量 CBPeripheral 并且将peripheral付给 heartRateperipheral，不然系统不会将peripheral引用 那么接下来的钩子函数执行的peripheral就不是真正的peripheral了
        // 停止扫描
        central.stopScan()
        central.connect(peripheral)
    }
    
    // 连接成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(heartRateUUID)
    }
    // 连接失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败")
    }
    // 连接断开
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.connect(peripheral)
    }
}

extension ViewController : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("没有找到服务，原因是\(error.localizedDescription)")
        }
        guard let service = peripheral.services?.first else {return}
        peripheral.discoverCharacteristics([controPointCharacteristicUUID,
                                            sensortLoctionCharacteristicUUID,
                                            measurmentCharacteristicUUID],
                                           for: service)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("没有找到特征，原因是\(error.localizedDescription)")
        }
        
        guard let characteristics = service.characteristics else {return}
        for characteristic in characteristics
        {
            if characteristic.properties.contains(.write)
            {
                peripheral.writeValue("100".data(using: .utf8)!, for: characteristic, type: .withResponse)
                contropiontCharacteristic = characteristic
            }
            if characteristic.properties.contains(.read)
            {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify)// 实时数据
            {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
    }
    
    // 写入--触发函数
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("写入失败，原因是\(error.localizedDescription)")
            return
        }
        print("写入成功")
    }
    // 读取--触发函数
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("读取失败失败，原因是\(error.localizedDescription)")
            return
        }
        switch characteristic.uuid {
        case sensortLoctionCharacteristicUUID:
            sensorLoctionLable.text = String(data: characteristic.value! , encoding: .utf8)
        case measurmentCharacteristicUUID:
//            guard let heartRate = Int(String(data: characteristic.value! , encoding: .utf8)!) else {return}
            hartRateLable.text = String(data: characteristic.value! , encoding: .utf8)!
        default:
            break
        }
        print("读取成功")
    }
}
