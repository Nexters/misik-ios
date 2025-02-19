//
//  
//  Created by Salty Kang in 2025
//  
	

import Foundation

/// 리뷰 관련 API 클라이언트
class ReviewAPIClient {
    
    /// API 기본 URL
    private let baseURL = URL(string: "https://api.misik.me/reviews")!
    private let marketingVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

    /// 영구적인 `device-id` (앱 삭제 후에도 유지됨)
    private let deviceID: String = {
        if let savedID = UserDefaults.standard.string(forKey: "device-id") {
            return savedID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "device-id")
            return newID
        }
    }()
    
    /// 공통 헤더 설정 (device-id와 Content-Type 포함)
    private var commonHeaders: [String: String] {
        return [
            "device-id": deviceID,
            "Content-Type": "application/json",
            "app-version": marketingVersion,
            "app-platform": "IOS"
        ]
    }
    
    /// OCR 텍스트 기반 리뷰 생성
    func createReview(ocrText: String, hashTag: [String], reviewStyle: String) async throws -> Int {
        var request = createReviewRequest(for: baseURL, httpMethod: "POST")
        
        let requestBody = ReviewRequest(ocrText: ocrText, hashTag: hashTag, reviewStyle: reviewStyle)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleResponse(data: data, response: response)
    }
    
    /// 리뷰 조회
    func fetchReview(id: String) async throws -> ReviewResponse {
        let reviewURL = baseURL.appendingPathComponent(id)
        let request = createReviewRequest(for: reviewURL, httpMethod: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleResponse(data: data, response: response)
    }
    
    /// OCR 파싱 요청 (POST)
    func parseOCRText(ocrText: String) async throws -> String {
        let ocrParsingURL = baseURL.appendingPathComponent("ocr-parsing")
        var request = createReviewRequest(for: ocrParsingURL, httpMethod: "POST")
        
        let requestBody = OCRParsingRequest(text: ocrText)
        request.httpBody = try JSONEncoder().encode(requestBody)
        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleResponse(data: data, response: response)
    }
    
    /// 웹뷰 URL 조회
    /// TODO: 도메인 분리
    func getWebViewURL() async throws -> GetWebViewURLResponse {
        let url = URL(string: "https://api.misik.me/webview/home")!
        let request = createReviewRequest(for: url, httpMethod: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        return try handleResponse(data: data, response: response)
    }
    
    /// 공통된 요청 헤더와 기본 설정
    private func createReviewRequest(for url: URL, httpMethod: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        // 공통 헤더 설정
        commonHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    /// HTTP 응답 처리
    private func handleResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
            case 200..<300:
                return try JSONDecoder().decode(T.self, from: data)
            default:
                throw try handleError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
            case 200..<300:
                guard let str = String(data: data, encoding: .utf8) else {
                    throw ReviewAPIError.invalidResponse
                }
                return str
            default:
                throw try handleError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> Int {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
            case 200..<300:
                guard let str = String(data: data, encoding: .utf8), let converted = Int(str) else {
                    throw ReviewAPIError.invalidResponse
                }
                return converted
            default:
                throw try handleError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    private func handleError(statusCode: Int, data: Data) throws -> ReviewAPIError {
        switch statusCode {
            case 400:
                throw ReviewAPIError.badRequest
            case 426:
                let res = try JSONDecoder().decode(ReviewUpdateRequiredErrorResponse.self, from: data)
                throw ReviewAPIError.updateRequired(urlStr: res.url)
            default:
                throw ReviewAPIError.unexpected(statusCode: statusCode, data: data)
        }
    }
}

/// 리뷰 생성 요청 모델
struct ReviewRequest: Codable {
    let ocrText: String
    let hashTag: [String]
    let reviewStyle: String
}

/// 리뷰 생성 응답 모델
struct ReviewCreateResponse: Codable {
    let id: String
}

/// 리뷰 조회 응답 모델
struct ReviewResponse: Codable {
    let isSuccess: Bool
    let id: String
    let review: String?
}

struct ReviewUpdateRequiredErrorResponse: Codable {
    let url: String
}

struct GetWebViewURLResponse: Codable {
    let url: String
}

/// API 오류 정의
enum ReviewAPIError: Error {
    case invalidResponse
    case badRequest
    case updateRequired(urlStr: String)
    case unexpected(statusCode: Int, data: Data?)
}

/// OCR 파싱 요청 모델
struct OCRParsingRequest: Codable {
    let text: String
}

/// OCR 파싱 응답 모델
struct OCRParsingResponse: Codable {
    let parsed: [[String : String]]
}


