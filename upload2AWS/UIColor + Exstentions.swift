//
//  Exstentions.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/25/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import UIKit
extension UIColor {
    static func RGB(_ redValue: CGFloat, greenValue: CGFloat, blueValue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: redValue/255.0, green: greenValue/255.0, blue: blueValue/255.0, alpha: alpha)
    }
}
