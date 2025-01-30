//
//  ViewController.swift
//  Misik
//
//  Created by Haeseok Lee on 1/28/25.
//

import UIKit

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
        .init(name: "Album", action: didTapAlbum)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
}

private extension ViewController {
    
    func setupUI() {
        
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
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("카메라를 사용할 수 없습니다.")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true, completion: nil)
    }
    
    func didTapAlbum(action: UIAction) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("앨범을 사용할 수 없습니다.")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true, completion: nil)
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
        picker.dismiss(animated: true)
        print(info[.originalImage] as? UIImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
