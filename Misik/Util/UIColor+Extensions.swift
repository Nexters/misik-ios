//
//  UIColor+Extensions.swift
//  Misik
//
//  Created by Haeseok Lee on 2/2/25.
//

import UIKit

extension UIColor {
    static let textWhite: UIColor = .init(hex: "#FFFFFF")!
    static let white: UIColor = .init(hex: "#FFFFFF")!
    static let black: UIColor = .init(hex: "#000000")!
    static let gray500: UIColor = .init(hex: "#000000")!.withAlphaComponent(0.25)
    static let gray600: UIColor = .init(hex: "#363642")!
}

extension UIColor {
    
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        guard hexSanitized.count == 6 || hexSanitized.count == 8 else {
            return nil
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r, g, b, a: CGFloat
        if hexSanitized.count == 6 {
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            b = CGFloat(rgb & 0xFF) / 255.0
            a = 1.0
        } else {
            r = CGFloat((rgb >> 24) & 0xFF) / 255.0
            g = CGFloat((rgb >> 16) & 0xFF) / 255.0
            b = CGFloat((rgb >> 8) & 0xFF) / 255.0
            a = CGFloat(rgb & 0xFF) / 255.0
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
