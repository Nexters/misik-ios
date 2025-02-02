//
//  ViewController.swift
//  Misik
//
//  Created by Haeseok Lee on 1/28/25.
//

import UIKit
import CoreGraphics

class ViewController: UIViewController {
    
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        view.alignment = .top
        view.distribution = .fill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var features: [Feature] = [
        .init(name: "Camera", action: didTapCamera),
        .init(name: "Album", action: didTapAlbum),
        .init(name: "OCR", action: didTapOCR),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
}

private extension ViewController {
    
    func setupUI() {
        view.backgroundColor = .white
        
        features.map { feature in
            var configuration = UIButton.Configuration.filled()
            configuration.title = feature.name
            configuration.baseBackgroundColor = .orange
            configuration.cornerStyle = .small
            
            let button = UIButton(configuration: configuration)
            button.addAction(.init(handler: (feature.action) ?? { _ in }), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }.forEach {
            stackView.addArrangedSubview($0)
        }
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
        ])
        
    }
    
    func didTapCamera(action: UIAction) {
        presentImagePickerViewController(sourceType: .camera)
    }
    
    func didTapAlbum(action: UIAction) {
        presentImagePickerViewController(sourceType: .photoLibrary)
    }
    
    func didTapOCR(action: UIAction) {
        didTapCamera(action: action)
    }
    
    func presentImagePickerViewController(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("\(sourceType == .camera ? "카메라" : "앨범"))를 사용할 수 없습니다.")
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true)
    }
    
    func presentOCRViewController(targetImage: UIImage) {
        let ocrViewController = OCRViewController(
            viewModel: OCRViewModel(
                targetImage: targetImage,
                processor: OCRVisionProcessor()
            )
        )
        ocrViewController.modalPresentationStyle = .fullScreen
        ocrViewController.delegate = self
        present(ocrViewController, animated: true)
    }
}

private extension ViewController {
    
    struct Feature {
        let name: String
        let action: ((UIAction) -> Void)?
    }
}


// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: { [weak self] in
            guard let self, let targetImage = info[.originalImage] as? UIImage else { return }
            presentOCRViewController(targetImage: targetImage)
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - OCRViewController
extension ViewController: OCRViewController.Delegate {
    
    func ocrViewController(_ controller: OCRViewController, didFinishOCR result: [String]) {
        print(result)
    }
}
