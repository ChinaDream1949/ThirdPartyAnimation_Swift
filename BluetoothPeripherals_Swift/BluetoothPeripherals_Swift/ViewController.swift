//
//  ViewController.swift
//  BluetoothPeripherals_Swift
//
//  Created by MR.Sahw on 2020/11/18.
//

import UIKit
import CoreBluetooth

let serviceUUID = CBUUID(string: "6F50B783-44A7-4654-AD31-3046A3345497")
let writeUUID = CBUUID(string: "5B8A6CA2-5993-4516-B76B-9F032A14D2EA")
let readUUID = CBUUID(string: "95314954-3CA6-476B-8C54-03C9635B2D6A")
let notifyUUID = CBUUID(string: "D85B7722-10C8-4453-A81A-ABE3DA4389AB")


class ViewController: UIViewController {

    @IBOutlet weak var writeLable: UILabel!
    @IBOutlet weak var readLable: UILabel!
    @IBOutlet weak var notifyLable: UILabel!
    
    var peripheralManager : CBPeripheralManager!
    var writeCharacteristics : CBMutableCharacteristic!
    var notifyCharacteristics : CBMutableCharacteristic!
    
    var timer : Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        readLable.text = "海尔空调"
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
}

extension ViewController : CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
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
            // 创建服务
            let service = CBMutableService(type: serviceUUID, primary: true)
            writeCharacteristics = CBMutableCharacteristic(type: writeUUID, properties: .write, value: nil, permissions: .writeable)
            let raadCharacteristics = CBMutableCharacteristic(type: readUUID, properties: .read, value: nil, permissions: .readable)
            notifyCharacteristics = CBMutableCharacteristic(type: notifyUUID, properties: .notify, value: nil, permissions: .readable)
            
            service.characteristics = [writeCharacteristics,raadCharacteristics,notifyCharacteristics]
            peripheralManager.add(service)
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[serviceUUID]])
        @unknown default:
            print("来自未来的错误")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("无法添加服务，原因是\(error.localizedDescription)")
        }
        print("添加服务成功")
    }
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("无法开始广播，原因是\(error.localizedDescription)")
        }
        print("开始广播...")
    }
    // 写
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let request = requests[0]
        if request.characteristic.properties.contains(.write) {
            writeCharacteristics.value = request.value
            writeLable.text = String(data: request.value!, encoding: .utf8)
            peripheral.respond(to: request, withResult: .success)
        }else{
            peripheral.respond(to: request, withResult: .writeNotPermitted)
        }
    }
    // 读
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.properties.contains(.read) {
            request.value = readLable.text!.data(using: .utf8)
            peripheral.respond(to: request, withResult: .success)
        }else{
            peripheral.respond(to: request, withResult: .readNotPermitted)
        }
    }
    // 实时
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        updateNotifyValue() // 有可能传输队列排满 无空间
    }
    // 传输队列有了空间后再次传输
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        updateNotifyValue()
    }
    // 取消订阅
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        timer?.invalidate()
    }
    
    func updateNotifyValue() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            let dateFormateter = DateFormatter()
            dateFormateter.dateFormat = "yyyy年MM月dd日 HH时mm分ss秒"
            let dateStr = dateFormateter.string(from: Date())
            self.notifyLable.text = dateStr
            self.peripheralManager.updateValue(dateStr.data(using: .utf8)!, for: self.notifyCharacteristics, onSubscribedCentrals: nil)
        }
    }
}
