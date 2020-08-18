//
//  TrainCollectionViewCell.swift
//  plarailplus
//
//  Created by Ryota Ayaki on 2020/08/10.
//  Copyright © 2020 Ryota Ayaki. All rights reserved.
//

import UIKit

class TrainCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var button: UIButton!
    
    var train: Train?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateView(train: Train) {
        self.train = train
        imageView.image = UIImage(named: train.imageName)
        button.isHidden = train.bluetoothService.peripheral == nil
    }
    
    @IBAction func controlButtonClicked(_ sender: UIButton) {
        toggle()
    }
    
    func toggle() {
        button.isSelected = !button.isSelected
        if button.isSelected {
            start()
            button.setImage(UIImage(named: "stop"), for: .normal)
        } else {
            stop()
            button.setImage(UIImage(named: "start"), for: .normal)
        }
    }
}

private extension TrainCollectionViewCell {
    func start() {
        train?.bluetoothService.write(byteArray: kMabeeeStartByteArray)
    }
    
    func stop() {
        train?.bluetoothService.write(byteArray: kMabeeeStopByteArray)
    }
}
