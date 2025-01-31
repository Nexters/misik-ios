//
//  OCRProcessing.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import Foundation
import UIKit

protocol OCRProcessing: AnyObject {
    
    func process(_ image: UIImage) async throws -> [String]
}
