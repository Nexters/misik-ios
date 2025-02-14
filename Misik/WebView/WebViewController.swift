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
    private let webViewURL: URL
    private let webViewContentController = WKUserContentController()
    private let reviewAPIClient = ReviewAPIClient()
    private lazy var webviewCommandSender: WebViewCommandSender = .init(webView: webView)
    
    
    init(wewbViewURL: URL) {
        self.webViewURL = wewbViewURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadWebView()
    }

    private func setupWebView() {
        WebViewReceivedCommand.register(in: webViewContentController, handler: self)

        let config = WKWebViewConfiguration()
        config.userContentController = webViewContentController

        webView = WKWebView(frame: .zero, configuration: config)
        view.addSubview(webView)
        
        // TODO: 웹뷰 Safe Area 적용 되면 변경하기
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    fileprivate func loadWebView() {
        webView.load(URLRequest(url: webViewURL))
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
        }
    }
}

// MARK: - DebugWebViewController
class DebugWebViewController: WebViewController {
    
    init() {
        super.init(wewbViewURL: URL(string: "https://misik-web.vercel.app")!)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadWebView() {
        webView.loadHTMLString(debug, baseURL: nil)
    }
}

extension DebugWebViewController {
    var debug: String {
                """
        <!DOCTYPE html>
        <html lang="ko">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>WebView Command Test</title>
            <script>
                // iOS에서 실행될 JavaScript 이벤트 수신기
                window.response = {
                    receiveGeneratedReview: function(review) {
                        console.log("📩 iOS에서 받은 리뷰:", review);
                        document.getElementById("reviewOutput").innerText = "받은 리뷰: " + review.result;
                    },
                    receiveScanResult: function(results) {
                        console.log("📩 iOS에서 받은 스캔 결과:", results);
                        document.getElementById("scanOutput").innerText = results;
                    }
                };

                function sendCommand(command, body = {}) {
                    if (window.webkit && window.webkit.messageHandlers[command]) {
                        window.webkit.messageHandlers[command].postMessage(body);
                        console.log("📤 iOS로 명령 전송:", command, body);
                    } else {
                        console.error("⚠️ iOS 핸들러가 등록되지 않음:", command);
                    }
                }
            </script>
        </head>
        <body>
            <h2>WebView Command Test</h2>
            
            <button onclick="sendCommand('openCamera')">📸 카메라 열기</button>
            <button onclick="sendCommand('openGallery')">🖼️ 갤러리 열기</button>
            <button onclick="sendCommand('share')">📤 공유하기</button>
            <button onclick="sendCommand('createReview', { ocrText: '품명 카야토스트+음료세트', hashTag: ['특별한 메뉴가 있어요'], reviewStyle: 'CUTE' })">📝 리뷰 생성</button>
            <button onclick="sendCommand('copy', { review: '복사할 내용' })">📋 복사하기</button>

            <h3>📨 iOS에서 받은 데이터</h3>
            <p id="reviewOutput">받은 리뷰: 없음</p>
            <p id="scanOutput">받은 스캔 결과: 없음</p>
        </body>
        </html>

        """
    }
}
