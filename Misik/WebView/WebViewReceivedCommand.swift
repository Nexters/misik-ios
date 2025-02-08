//
//  
//  Created by Salty Kang in 2025
//  
	

import Foundation
import WebKit

// MARK: - WebViewReceivedCommand
enum WebViewReceivedCommand {
    case openCamera
    case openGallery
    case share
    case createReview(body: [String: Any?])
    case copy(body: [String: Any?])

    private static let commandNames: [String] = ["openCamera", "openGallery", "share", "createReview", "copy"]

    static func register(
        in userContentController: WKUserContentController,
        handler: WKScriptMessageHandler
    ) {
        commandNames.forEach { userContentController.add(handler, name: $0) }
    }

    static func from(message: WKScriptMessage) -> WebViewReceivedCommand? {
        let body = message.body as? [String: Any?] ?? [:]
        switch message.name {
        case "openCamera": return .openCamera
        case "openGallery": return .openGallery
        case "share": return .share
        case "createReview": return .createReview(body: body)
        case "copy": return .copy(body: body)
        default: return nil
        }
    }
}
