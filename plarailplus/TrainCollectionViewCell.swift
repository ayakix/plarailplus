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
    
    @IBAction private func controlButtonClicked(_ sender: UIButton) {
        guard let train = train else {
            return
        }
        
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            train.bluetoothService.start()
            sender.setImage(UIImage(named: "stop"), for: .normal)
        } else {
            train.bluetoothService.stop()
            sender.setImage(UIImage(named: "start"), for: .normal)
        }
    }
}
