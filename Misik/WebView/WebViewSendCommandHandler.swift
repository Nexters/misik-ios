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
    func sendScanResults(results: String) {
        // 에러일 경우, 기존 방식의 경우 빈 스트링을 내려주기로 했으나, "error" 로 내려주도록 변경됨.
        let params = results == "" ? "error" : results
        callJavaScript(functionName: "receiveScanResult", params: params)
    }
    
    /// 생성된 리뷰를 웹뷰의 JavaScript 함수로 전달
    func sendGeneratedReview(review: String) {
        // 에러일 경우, 기존 방식의 경우 빈 딕션어리를 내려주기로 했으나, "error" 로 내려주도록 변경됨.
        let checkedResult = review == "" ? "error" : review
        callJavaScript(functionName: "receiveGeneratedReview", params: ["result" : checkedResult])
    }
    
    /// 키보드 height 값을 웹뷰의 JavaScript 함수로 전달
    func sendKeyboardHeight(height: String) {
        callJavaScript(functionName: "receiveKeyboardHeight", params: ["height": height])
    }
    
    /// JavaScript 함수 호출을 수행하는 메서드
    private func callJavaScript(functionName: String, params: Any) {
        
        var paramsStr: String
        
        if let casted = params as? String {
            paramsStr = casted
        } else {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: [.withoutEscapingSlashes]),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("JSON 직렬화 실패")
                return
            }
            
            paramsStr = jsonString
        }
        paramsStr = paramsStr.replacingOccurrences(of: "'", with: "")
        let jsCode = "window.response.\(functionName)('\(paramsStr)');"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("JavaScript 실행 오류: \(error.localizedDescription)")
                }
            }
        }
    }
}
