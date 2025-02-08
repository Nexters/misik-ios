//
//  
//  Created by Salty Kang in 2025
//  
	

import Foundation
import WebKit

class WebViewCommandSender {
    private let webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
    }
    
    /// Scan 결과를 웹뷰의 JavaScript 함수로 전달
    func sendScanResults(results: [[String: String]]) {
        callJavaScript(functionName: "receiveScanResult", params: results)
    }
    
    /// 생성된 리뷰를 웹뷰의 JavaScript 함수로 전달
    func sendGeneratedReview(review: String) {
        callJavaScript(functionName: "receiveGeneratedReview", params: ["result" : review])
    }
    
    /// JavaScript 함수 호출을 수행하는 메서드
    private func callJavaScript(functionName: String, params: Any) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: [.withoutEscapingSlashes]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("JSON 직렬화 실패")
            return
        }
        
        let jsCode = "window.response.\(functionName)('\(jsonString)');"
        
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("JavaScript 실행 오류: \(error.localizedDescription)")
                }
            }
        }
    }
}
