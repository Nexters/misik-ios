//
//  OCRViewController.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit
import Lottie

final class OCRViewController: UIViewController {
    
    protocol Delegate: AnyObject {
        
        func ocrViewController(_ controller: OCRViewController, didFinishOCR result: [String])
        func ocrViewControllerDidDismiss()
    }
    
    weak var delegate: Delegate?
    
    init(viewModel: any OCRViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGradient()
        
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
    
    private let scanningView: LottieAnimationView = {
        let view = LottieAnimationView(animation: LottieAnimation.named("scan"))
        view.isHidden = true
        view.loopMode = .loop
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
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var gradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
}

private extension OCRViewController {
    
    func setupUI() {
        view.backgroundColor = .white

        view.addSubview(imageView)
        view.addSubview(scanningView)
        view.addSubview(gradientView)
        view.addSubview(closeButtonView)
        view.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scanningView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            scanningView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            scanningView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            scanningView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            closeButtonView.widthAnchor.constraint(equalToConstant: 38),
            closeButtonView.heightAnchor.constraint(equalToConstant: 38),
            closeButtonView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButtonView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            gradientView.widthAnchor.constraint(equalTo: view.widthAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 103),
            
            infoLabel.widthAnchor.constraint(equalTo: gradientView.widthAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor),
            infoLabel.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 20),
        ])
    }
    
    func setupGradient() {
        gradientView.layoutIfNeeded()
        gradientView.setGradient(color1: .clear, color2: .gray600)
    }
    
    func bindUI(_ output: OCRViewModelOutput) {
        Task {
            for await isLoading in output.isLoading {
                if isLoading {
                    startLoading()
                }
            }
        }.regist(&store)
        
        Task {
            for await result in output.ocrResult {
                delegate?.ocrViewController(self, didFinishOCR: result)
            }
        }.regist(&store)
        
        imageView.image = output.targetImage
    }
    
    func startLoading() {
        scanningView.isHidden = false
        scanningView.play()
        infoLabel.isHidden = false
    }
    
    func didTapCloseButton() {
        clear()
        dismiss()
    }
    
    func clear() {
        viewModel.clear()
        store.cancelAll()
    }
    
    func dismiss() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.ocrViewControllerDidDismiss()
        }
    }
}

private extension UIView{
    
    func setGradient(color1: UIColor, color2: UIColor){
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [color1.cgColor, color2.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.frame = bounds
        layer.addSublayer(gradient)
    }
}
