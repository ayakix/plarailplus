//
//  ViewController.swift
//  plarailplus
//
//  Created by Ryota Ayaki on 2020/08/09.
//  Copyright © 2020 Ryota Ayaki. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var trains: [Train] = []
    private var hayabusa: BluetoothService!
    private var komachi: BluetoothService!
    private var layout = UICollectionViewFlowLayout()
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        initTrains()
    }
    
    @objc func checkBluetoothService(_ t: Timer) {
        collectionView.reloadData()
        if trains.allSatisfy({ $0.bluetoothService.peripheral != nil }) {
            timer?.invalidate()
            timer = nil
        }
    }
    
    @IBAction private func refreshButtonClicked(_ sender: UIButton) {
        initTrains()
    }
}

private extension ViewController {
    func initTrains() {
        if trains.count > 0 {
            trains.forEach {
                $0.bluetoothService.stopScan()
            }
        }
        trains = [
            Train(peripheralName: kHayabusaPeripheralName, imageName: "hayabusa", bluetoothService: BluetoothService()),
            Train(peripheralName: kKomachiPeripheralName, imageName: "komachi", bluetoothService: BluetoothService())
        ]
        trains.forEach {
            $0.bluetoothService.setupBluetoothService(peripheralName: $0.peripheralName)
        }
        collectionView.reloadData()
        
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(checkBluetoothService(_:)),
            userInfo: nil,
            repeats: true
        )
    }
    
    func initView() {
        collectionView.delegate = self
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = collectionView.frame.width / 25
        collectionView?.collectionViewLayout = layout
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trains.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrainCollectionViewCell", for: indexPath) as? TrainCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.updateView(train: trains[indexPath.row])
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.frame.size.width - layout.minimumInteritemSpacing * CGFloat(trains.count - 1)) / CGFloat(trains.count))
        return CGSize(width: width, height: collectionView.frame.size.height)
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {}
}
