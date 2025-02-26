//
//  OCRViewModel.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit
import CoreGraphics
import Combine

// MARK: - OCRViewModelType
protocol OCRViewModelType: AnyObject {

    func transform(input: OCRViewModelInput) -> OCRViewModelOutput
}

// MARK: - OCRViewModelInput
struct OCRViewModelInput {
    let viewDidLoad: AsyncStream<Void>
}

// MARK: - OCRViewModelOutput
struct OCRViewModelOutput {
    let isLoading: AsyncStream<Bool>
    let targetImage: UIImage
    let ocrResult: AsyncStream<[String]>
}

// MARK: - OCRViewModel
final class OCRViewModel: OCRViewModelType {
    
    init(targetImage: UIImage, processor: OCRProcessing) {
        self.targetImage = targetImage
        self.processor = processor
    }
    
    deinit {
        store.cancelAll()
    }
    
    func transform(input: OCRViewModelInput) -> OCRViewModelOutput {
        transform(viewDidLoad: input.viewDidLoad)
        return OCRViewModelOutput(
            isLoading: isLoadingStream,
            targetImage: targetImage,
            ocrResult: ocrResultStream
        )
    }
    
    // MARK: Private
    private let processor: OCRProcessing
    private let targetImage: UIImage
    private var store: TaskStore = .init()
    
    private var isLoadingContinuation: AsyncStream<Bool>.Continuation?
    private lazy var isLoadingStream: AsyncStream<Bool> = .init {
        isLoadingContinuation = $0
    }
    
    private var ocrResultContinuation: AsyncStream<[String]>.Continuation?
    private lazy var ocrResultStream: AsyncStream<[String]> = .init {
        ocrResultContinuation = $0
    }
}

private extension OCRViewModel {
    
    func transform(viewDidLoad: AsyncStream<Void>) {
        Task { [weak self] in
            for await _ in viewDidLoad {
                guard let self else { return }
                isLoadingContinuation?.yield(true)
                let result = (try? await processor.process(targetImage)) ?? []
                ocrResultContinuation?.yield(result)
                isLoadingContinuation?.yield(false)
            }
        }
        .regist(&store)
    }
}
