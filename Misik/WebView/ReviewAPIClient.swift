//
//  
//  Created by Salty Kang in 2025
//  
	

import Foundation

/// 리뷰 관련 API 클라이언트
class ReviewAPIClient {
    
    /// API 기본 URL
    private let baseURL = URL(string: "https://api.misik.me/reviews")!
    
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
            "Content-Type": "application/json"
        ]
    }
    
    /// OCR 텍스트 기반 리뷰 생성
    func createReview(ocrText: String, hashTag: [String], reviewStyle: String) async throws -> Int {
        var request = createReviewRequest(for: baseURL, httpMethod: "POST")
        
        let requestBody = ReviewRequest(ocrText: ocrText, hashTag: hashTag, reviewStyle: reviewStyle)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        print(String(data: request.httpBody!, encoding: .utf8))
        
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
    func parseOCRText(ocrText: String) async throws -> OCRParsingResponse {
        let ocrParsingURL = baseURL.appendingPathComponent("ocr-parsing")
        var request = createReviewRequest(for: ocrParsingURL, httpMethod: "POST")
        
        let requestBody = OCRParsingRequest(text: ocrText)
        
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
        
        
        do {
            switch httpResponse.statusCode {
                case 200..<300:
                    print("\(httpResponse.url) \nAPI Success \(String(data: data, encoding: .utf8))")
                    return try JSONDecoder().decode(T.self, from: data)
                case 400:
                    let errorResponse = try JSONDecoder().decode(ReviewErrorResponse.self, from: data)
                    throw ReviewAPIError.badRequest(message: errorResponse.message)
                default:
                    throw ReviewAPIError.unexpected(statusCode: httpResponse.statusCode)
            }
        } catch {
            print("\(httpResponse.url) \nAPI ERROR \(error) \(String(data: data, encoding: .utf8))")
            throw error
        }
    }
    
    private func handleResponse(data: Data, response: URLResponse) throws -> Int {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReviewAPIError.invalidResponse
        }
        
        do {
            switch httpResponse.statusCode {
                case 200..<300:
                    print("\(httpResponse.url) \nAPI Success \(String(data: data, encoding: .utf8))")
                    guard let str = String(data: data, encoding: .utf8), let converted = Int(str) else {
                        throw ReviewAPIError.badRequest(message: "ID가 잘못 내려왔습니다")
                    }
                    
                    return converted
                    
                case 400:
                    let errorResponse = try JSONDecoder().decode(ReviewErrorResponse.self, from: data)
                    throw ReviewAPIError.badRequest(message: errorResponse.message)
                default:
                    throw ReviewAPIError.unexpected(statusCode: httpResponse.statusCode)
            }
        } catch {
            print("\(httpResponse.url) \nAPI ERROR \(error) \(String(data: data, encoding: .utf8))")
            throw error
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

/// 오류 응답 모델
struct ReviewErrorResponse: Codable {
    let message: String
}

/// API 오류 정의
enum ReviewAPIError: Error {
    case invalidResponse
    case badRequest(message: String)
    case unexpected(statusCode: Int)
}

/// OCR 파싱 요청 모델
struct OCRParsingRequest: Codable {
    let text: String
}

/// OCR 파싱 응답 모델
struct OCRParsingResponse: Codable {
    let parsed: [[String : String]]
}
