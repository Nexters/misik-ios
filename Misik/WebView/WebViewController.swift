//
//  
//  Created by Salty Kang in 2025
//  
	

import UIKit
import PhotosUI
import WebKit
import SwiftUI

class WebViewController: UIViewController {
    fileprivate var webView: WKWebView!
    private let webViewContentController = WKUserContentController()
    private let reviewAPIClient = ReviewAPIClient()
    private lazy var webviewCommandSender: WebViewCommandSender = .init(webView: webView)
    private var store: TaskStore = .init()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupWebViewURL()
    }

    private func setupWebView() {
        WebViewReceivedCommand.register(in: webViewContentController, handler: self)

        let config = WKWebViewConfiguration()
        config.userContentController = webViewContentController

        webView = WKWebView(frame: view.bounds, configuration: config)
        view.addSubview(webView)
    }
    
    private func setupWebViewURL() {
        Task {
            do {
                let urlResponse = try await reviewAPIClient.getWebViewURL()
                guard let url = URL(string: urlResponse.url) else {
                    print("URL이 잘못 내려오고 있습니다")
                    return
                }
                self.loadWebView(url: url)
            } catch let error as ReviewAPIError {
                if case let .updateRequired(urlStr) = error {
                    showForceUpdateAlert(updateURL: urlStr)
                }
            }
            
        }
    }
    
    fileprivate func loadWebView(url: URL) {
        webView.load(URLRequest(url: url))
    }

    /// 강제 업데이트 알럿 띄우기
    private func showForceUpdateAlert(updateURL: String) {
        let alert = UIAlertController(
            title: nil,
            message: "원활한 서비스 이용을 위해 업데이트가 필요해요",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "앱스토어로 이동", style: .default, handler: { _ in
            if let url = URL(string: updateURL) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        self.present(alert, animated: true)
    }

}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let command = WebViewReceivedCommand.from(message: message) else { return }
        
        switch command {
            case .openCamera:
                presentImagePickerViewController()
            case .openGallery:
                presentPHPickerViewController()
            case .share:
                // TODO: 앱스토어 URL 전달받기
                let activityVC = UIActivityViewController(activityItems: ["Nexters 미식 스튜디오! 앱 오픈까지 많은 관심 부탁드립니닷"], applicationActivities: nil)
                present(activityVC, animated: true, completion: nil)
            case .createReview(let body):
                Task {
                    do {
                        let id = try await reviewAPIClient.createReview(
                            ocrText: body["ocrText"] as? String ?? "",
                            hashTag: body["hashTag"] as? [String] ?? [],
                            reviewStyle: body["reviewStyle"] as? String ?? ""
                        )
                        
                        let generated = try await reviewAPIClient.fetchReview(id: "\(id)")
                        webviewCommandSender.sendGeneratedReview(review: generated.review ?? "")
                    } catch {
                        webviewCommandSender.sendGeneratedReview(review: "")
                    }
                }
                
            case .copy(let body):
                UIPasteboard.general.string = body["review"] as? String ?? ""
        }
    }
}

// MARK: - Navigation
extension WebViewController {
    func presentImagePickerViewController() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("카메라를 사용할 수 없습니다.")
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true)
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

// MARK: - UIImagePickerControllerDelegate
extension WebViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
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

// MARK: - PHPickerViewControllerDelegate
extension WebViewController: PHPickerViewControllerDelegate {
    
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

// MARK: - OCRViewController
extension WebViewController: OCRViewController.Delegate {
    func ocrViewController(_ controller: OCRViewController, didFinishOCR result: [String]) {
        Task {
            guard let polished = try? await reviewAPIClient.parseOCRText(ocrText: result.joined(separator: "\n")) else {
                webviewCommandSender.sendScanResults(results: .init())
                return
            }
            
            webviewCommandSender.sendScanResults(results: polished)
            dismiss(animated: true)
        }.regist(&store, id: .parseAndSendOCRResult)
    }
    
    func ocrViewControllerDidDismiss() {
        store.cancel(id: .parseAndSendOCRResult)
    }
}

private extension TaskStore.TaskID {
    static let parseAndSendOCRResult: String = "ParseAndSendOCRResult"
}
