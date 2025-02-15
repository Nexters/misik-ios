//
//  SceneDelegate.swift
//  Misik
//
//  Created by Haeseok Lee on 1/28/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        guard let url: URL = URL(string: Constant.webURLString) else { return }
        let rootViewController = WebViewController(url: url)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }

}

