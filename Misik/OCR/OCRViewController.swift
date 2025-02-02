//
//  OCRViewController.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit

final class OCRViewController: UIViewController {
    
    protocol Delegate: AnyObject {
        
        func ocrViewController(_ controller: OCRViewController, didFinishOCR result: [String])
    }
    
    weak var delegate: Delegate?
    
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
        view.contentMode = .scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let scanningView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "Scan"))
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var closeButtonView: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(named: "Btn_close")
        let button = UIButton(configuration: configuration)
        button.addAction(.init(handler: { [weak self] _ in
            self?.didTapCloseButton()
        }), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = .titleSm
        label.textColor = .textWhite
        label.text = "영수증을 인식 중입니다."
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let demoOCRResultLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .systemRed
        label.text = ""
        label.isHidden = true
        label.backgroundColor = .white?.withAlphaComponent(0.7)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
}

private extension OCRViewController {
    
    func setupUI() {
        view.backgroundColor = .white

        view.addSubview(imageView)
        view.addSubview(scanningView)
        view.addSubview(infoLabel)
        view.addSubview(closeButtonView)
        
        imageView.addSubview(demoOCRResultLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scanningView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            scanningView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            scanningView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -32),
            
            closeButtonView.widthAnchor.constraint(equalToConstant: 38),
            closeButtonView.heightAnchor.constraint(equalToConstant: 38),
            closeButtonView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButtonView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            infoLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            infoLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            demoOCRResultLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 30),
            demoOCRResultLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -30),
            demoOCRResultLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
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
                demoOCRResultLabel.text = result.joined(separator: "\n")
                delegate?.ocrViewController(self, didFinishOCR: result)
            }
        }.regist(&store, id: "Result")
        
        imageView.image = output.targetImage
    }
    
    func startLoading() {
        scanningView.isHidden = false
        infoLabel.isHidden = false
        demoOCRResultLabel.isHidden = true
    }
    
    func stopLoading() {
        scanningView.isHidden = true
        infoLabel.isHidden = true
        demoOCRResultLabel.isHidden = false
    }
    
    func didTapCloseButton() {
        dismiss(animated: true)
    }
}
