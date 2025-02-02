//
//  OCRViewModelTests.swift
//  MisikTests
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit
import Testing

@testable import Misik

@Suite("OCRViewModelTests")
final class OCRViewModelTests {

    var viewModel: OCRViewModel!
    var mockProcessor: MockOCRProcessor!
    
    init() async throws {
        mockProcessor = MockOCRProcessor()
        viewModel = OCRViewModel(targetImage: UIImage(), processor: mockProcessor)
    }
    
    deinit {
        viewModel = nil
        mockProcessor = nil
    }

    @Test func testOCRProcessingSuccess() async {
        // Given: Mock OCR Processor가 제공할 결과
        mockProcessor.mockResult = ["Test OCR Result"]
        
        // AsyncStream을 통해 viewDidLoad 이벤트 트리거
        let viewDidLoadStream = AsyncStream<Void> { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                continuation.yield(())
                continuation.finish()
            }
        }
        
        let input = OCRViewModelInput(viewDidLoad: viewDidLoadStream)
        let output = viewModel.transform(input: input)

        var isLoadingStates: [Bool] = []
        var ocrResults: [String] = []

        let task = Task {
            for await state in output.isLoading {
                isLoadingStates.append(state)
            }
        }

        let resultTask = Task {
            for await result in output.ocrResult {
                ocrResults.append(contentsOf: result)
            }
        }

        // OCR 처리가 완료될 때까지 대기
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1.0초 대기

        #expect(isLoadingStates == [true, false], "isLoading이 true -> false 순서로 변경되어야 합니다.")
        #expect(ocrResults == ["Test OCR Result"], "OCR 결과가 예상과 일치해야 합니다.")

        task.cancel()
        resultTask.cancel()
    }
    
    @Test func testOCRProcessingFailure() async {
        // Given: OCR 프로세서가 빈 결과를 반환하도록 설정
        mockProcessor.mockResult = []

        let viewDidLoadStream = AsyncStream<Void> { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                continuation.yield(())
                continuation.finish()
            }
        }

        let input = OCRViewModelInput(viewDidLoad: viewDidLoadStream)
        let output = viewModel.transform(input: input)

        var isLoadingStates: [Bool] = []
        var ocrResults: [String] = []

        let task = Task {
            for await state in output.isLoading {
                isLoadingStates.append(state)
            }
        }

        let resultTask = Task {
            for await result in output.ocrResult {
                ocrResults.append(contentsOf: result)
            }
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1.0초 대기

        #expect(isLoadingStates == [true, false], "isLoading이 true -> false 순서로 변경되어야 합니다.")
        #expect(ocrResults == [], "OCR 결과가 빈 문자열이어야 합니다.")

        task.cancel()
        resultTask.cancel()
    }
}
