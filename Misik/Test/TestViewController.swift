//
//  ViewController.swift
//  Misik
//
//  Created by Haeseok Lee on 1/28/25.
//

import UIKit
import PhotosUI
import CoreGraphics

final class TestViewController: UIViewController {
    
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
        .init(name: "WebView > Production", action: didTapWebViewProd),
        .init(name: "WebView > Debug", action: didTapWebViewDebug),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
}

private extension TestViewController {
    
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
        presentPHPickerViewController()
    }
    
    func didTapOCR(action: UIAction) {
        didTapCamera(action: action)
    }
    
    func didTapWebViewProd(action: UIAction) {
        let url = URL(string: "https://misik-web.vercel.app")!
        let vc = WebViewController(url: url)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    func didTapWebViewDebug(action: UIAction) {
        let vc = DebugWebViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    func presentImagePickerViewController(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("카메라를 사용할 수 없습니다.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func presentPHPickerViewController() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .any(of: [.images, .livePhotos])
        let picker = PHPickerViewController(configuration: configuration)
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        present(picker, animated: true, completion: nil)
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

private extension TestViewController {
    
    struct Feature {
        let name: String
        let action: ((UIAction) -> Void)?
    }
}


// MARK: - UIImagePickerControllerDelegate
extension TestViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self, let targetImage = info[.originalImage] as? UIImage else { return }
            presentOCRViewController(targetImage: targetImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension TestViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let selectedImage = image as? UIImage else { return }
                DispatchQueue.main.async {
                    self?.presentOCRViewController(targetImage: selectedImage)
                }
            }
        }
    }
}

// MARK: - OCRViewController.Delegate
extension TestViewController: OCRViewController.Delegate {
    
    func ocrViewController(_ controller: OCRViewController, didFinishOCR result: [String]) {
        print(result)
    }
    
    func ocrViewControllerDidDismiss() {
        print("didDismiss")
    }
}

#Preview {
    TestViewController()
}
