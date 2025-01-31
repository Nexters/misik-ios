//
//  MockImageProcessor.swift
//  MisikTests
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit

@testable import Misik

final class MockOCRProcessor: OCRProcessing {
    var mockResult: [String] = ["Detected Text"]
    var delay: TimeInterval = 0.1

    func process(_ image: UIImage) async throws -> [String] {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return mockResult
    }
}
