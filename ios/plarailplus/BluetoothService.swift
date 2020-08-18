//
//  BluetoothService.swift
//  plarailplus
//
//  Created by Ryota Ayaki on 2020/08/09.
//  Copyright © 2020 Ryota Ayaki. All rights reserved.
//

import CoreBluetooth

protocol BluetoothServiceDelegate: class {
    func didUpdateValueFor(_ characteristic: CBCharacteristic)
}

final class BluetoothService: NSObject {
    private var peripheralName: String?
    /// 対象のキャラクタリスティック
    private var writeCharacteristic: CBCharacteristic? = nil
    private var centralManager: CBCentralManager
    private var peripheralManager: CBPeripheralManager
    /// 接続先の機器
    var peripheral: CBPeripheral? = nil
    var serviceUUID: String!
    var characteristicUUID: String!
    
    var delegate: BluetoothServiceDelegate?

    override init() {
        self.centralManager = CBCentralManager()
        self.peripheralManager = CBPeripheralManager()
    }

    // MARK: - Public Methods

    /// Bluetooth接続のセットアップ
    func setupBluetoothService(peripheralName: String, serviceUUID: String, characteristicUUID: String, delegate: BluetoothServiceDelegate? = nil) {
        self.peripheralName = peripheralName
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        self.delegate = delegate
    }

    /// スキャン開始
    func startScan() {
        print("スキャン開始")
        if self.centralManager.isScanning == false {
//            let services = [CBUUID(string: serviceUUID)]
//            self.centralManager.scanForPeripherals(withServices: services, options: nil)
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    /// スキャン停止
    func stopScan() {
        if self.centralManager.isScanning {
            self.centralManager.stopScan()
        }
    }

    /// 機器に接続
    func connectPeripheral() {
        guard let peripheral = self.peripheral else {
            // 失敗処理
            return
        }
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func write(byteArray: [UInt8]) {
        guard let writeCharacteristic = writeCharacteristic else {
            return
        }
        let data = Data(byteArray)
        self.peripheral?.writeValue(data as Data, for: writeCharacteristic, type: .withResponse)
    }
}

extension BluetoothService: CBCentralManagerDelegate {
    /// Bluetoothのステータスを取得する(CBCentralManagerの状態が変わる度に呼び出される)
    ///
    /// - Parameter central: CBCentralManager
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("Bluetooth PoweredOff")
            break
        case .poweredOn:
            print("Bluetooth poweredOn")
            startScan()
            break
        case .resetting:
            print("Bluetooth resetting")
            break
        case .unauthorized:
            print("Bluetooth unauthorized")
            break
        case .unknown:
            print("Bluetooth unknown")
            break
        case .unsupported:
            print("Bluetooth unsupported")
            break
        @unknown default:
            print("Bluetooth unknown")
            break
        }
    }

    /// スキャン結果取得
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    ///   - advertisementData: アドバタイズしたデータを含む辞書型
    ///   - RSSI: 周辺機器の現在の受信信号強度インジケータ（RSSI）（デシベル単位）
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 対象機器のみ保持する
        if let name = peripheral.name, name.contains(peripheralName!) {
            // 対象機器のみ保持する
            self.peripheral = peripheral
            // 機器に接続
            print("機器に接続：\(String(describing: peripheral.name))")
            self.centralManager.connect(peripheral, options: nil)
        }
    }

    /// 接続成功時
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("接続成功")
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        // 指定のサービスを探索
        if let peripheral = self.peripheral {
            peripheral.discoverServices([CBUUID(string: serviceUUID)])
        }
        // スキャン停止処理
        self.stopScan()
    }

    /// 接続失敗時
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    ///   - error: Error
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("接続失敗：\(String(describing: error))")
    }

    /// 接続切断時
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    ///   - error: Error
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("接続切断：\(String(describing: error))")
    }

}

extension BluetoothService: CBPeripheralDelegate {
    /// キャラクタリスティック探索時(機器接続直後に呼ばれる)
    ///
    /// - Parameters:
    ///   - peripheral: CBPeripheral
    ///   - error: Error
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            // スキャン停止処理
            self.stopScan()
            // 失敗処理
            return
        }

        if let peripheralServices = peripheral.services {
            for service in peripheralServices where service.uuid == CBUUID(string: serviceUUID) {
                print("キャラクタリスティック探索")
                // キャラクタリスティック探索開始
                let characteristicUUIDArray: [CBUUID] = [CBUUID(string: characteristicUUID)]
                peripheral.discoverCharacteristics(characteristicUUIDArray, for: service)
            }
        }
    }
}

extension BluetoothService: CBPeripheralManagerDelegate {

    /// 端末のBluetooth設定を取得(BluetoothServiceの使用開始時、端末のBluetooth設定変更時に呼ばれる)
    ///
    /// - Parameter peripheral: CBPeripheralManager
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            // サービスを登録
            let service = CBMutableService(type: CBUUID(string: serviceUUID), primary: true)
            self.peripheralManager.add(service)
        }
    }

    /// キャラクタリスティック発見時(機器接続直後に呼ばれる)
    ///
    /// - Parameters:
    ///   - peripheral: CBPeripheral
    ///   - service: CBService
    ///   - error: Error
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            // スキャン停止処理
            self.stopScan()
            print("キャラクタリスティック発見時：\(String(describing: error))")
            // エラー処理
            return
        }
        guard let serviceCharacteristics = service.characteristics else {
            // スキャン停止処理
            self.stopScan()
            // エラー処理
            return
        }
        // キャラクタリスティック別の処理
        for characteristic in serviceCharacteristics {
            if characteristic.uuid == CBUUID(string: characteristicUUID) {
                if characteristic.properties.contains(.write) {
                    // データ書き込み用のキャラクタリスティックを保持
                    self.writeCharacteristic = characteristic
                    print("書き込み用キャラクタリスティックを保持：\(characteristic.uuid)")
                }
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("通知用キャラクタリスティックを監視：\(characteristic.uuid)")
                }
            }
        }
    }

    /// キャラクタリスティックにデータ書き込み時(コマンド送信時に呼ばれる)
    ///
    /// - Parameters:
    ///   - peripheral: CBPeripheral
    ///   - characteristic: CBCharacteristic
    ///   - error: Error
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("キャラクタリスティックデータ書き込み時エラー：\(String(describing: error))")
            // 失敗処理
            return
        }
        // 読み込み開始
        peripheral.readValue(for: characteristic)
    }

    /// キャラクタリスティック値取得・変更時(コマンド送信後、受信時に呼ばれる)
    ///
    /// - Parameters:
    ///   - peripheral: CBPeripheral
    ///   - characteristic: CBCharacteristic
    ///   - error: Error
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("キャラクタリスティック値取得・変更時エラー：\(String(describing: error))")
            // 失敗処理
            return
        }
        
        delegate?.didUpdateValueFor(characteristic)
    }
}
