//
//  UIImage+Extensions.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit
import CoreGraphics

extension UIImage {
    
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:               return .up
        case .down:             return .down
        case .left:             return .left
        case .right:            return .right
        case .upMirrored:       return .upMirrored
        case .downMirrored:     return .downMirrored
        case .leftMirrored:     return .leftMirrored
        case .rightMirrored:    return .rightMirrored
        @unknown default:       return .up
        }
    }
}
