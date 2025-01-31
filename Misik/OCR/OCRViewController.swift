//
//  OCRViewController.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit

final class OCRViewController: UIViewController {
    
    init(viewModel: any OCRViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        store.cancelAll()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let input = OCRViewModelInput(
            viewDidLoad: viewDidLoadStream
        )
        let output = viewModel.transform(input: input)
        bindUI(output)
        
        viewDidLoadContinuation?.yield(())
    }
    
    // MARK: Private
    private let viewModel: any OCRViewModelType
    
    private var viewDidLoadContinuation: AsyncStream<Void>.Continuation?
    private lazy var viewDidLoadStream: AsyncStream<Void> = .init {
        viewDidLoadContinuation = $0
    }
    
    private var store: TaskStore = .init()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        label.textColor = .black
        label.backgroundColor = .white.withAlphaComponent(0.5)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loading: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.isHidden = true
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}

private extension OCRViewController {
    
    func setupUI() {
        view.backgroundColor = .white
        view.addSubview(imageView)
        view.addSubview(resultLabel)
        view.addSubview(loading)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.3),
            imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            resultLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            resultLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            loading.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }
    
    func bindUI(_ output: OCRViewModelOutput) {
        Task {
            for await isLoading in output.isLoading {
                if isLoading {
                    startLoading()
                } else {
                    stopLoading()
                }
            }
        }.regist(&store, id: "Loading")
        
        Task {
            for await result in output.ocrResult {
                resultLabel.text = result
            }
        }.regist(&store, id: "Result")
        
        imageView.image = output.targetImage
    }
    
    func startLoading() {
        loading.isHidden = false
        loading.startAnimating()
    }
    
    func stopLoading() {
        loading.isHidden = true
        loading.stopAnimating()
    }
}
