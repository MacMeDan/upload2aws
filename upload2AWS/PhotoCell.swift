//
//  PhotoCell.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/25/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        imageView.frame = rect
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
