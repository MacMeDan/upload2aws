//
//  ChindrOverlay.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/31/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import UIKit
import Koloda

class ChindrOverlayView: OverlayView {
    
    override init(frame: CGRect) {
       super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var overlayImageView: UIImageView! = {
        [unowned self] in
        
        var imageView = UIImageView(frame: self.bounds)
        self.addSubview(imageView)
        
        return imageView
        }()
    
    override var overlayState: SwipeResultDirection? {
        didSet {
            switch overlayState {
            case .left? :
                overlayImageView.image = #imageLiteral(resourceName: "overlay_skip")
            case .right? :
                overlayImageView.image = #imageLiteral(resourceName: "overlay_like")
            default:
                overlayImageView.image = nil
            }
        }
    }
    
}
