//
//  GithubAPI.swift
//  GithubOAuthClient
//
//  Created by Zhassulan Aimukhambetov on 10/22/19.
//  Copyright © 2019 Zhassulan Aimukhambetov. All rights reserved.
//

import Foundation
import UIKit
import SwiftKeychainWrapper

public struct AccessTokenResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope = "scope"
    }
}

enum GithubScope: String {
    case user
    case repo
}

public class GithubAPI {
    
    static let authorizationURL = "https://github.com/login/oauth/authorize"
    static let accessTokenURL = "https://github.com/login/oauth/access_token"
    
    private var redirectURL = "githubclient://login.page"
    private var clientID: String?
    private var clientSecret: String?
    private var accessToken: String? = KeychainWrapper.standard.string(forKey: "token")
    
    static let shared: GithubAPI = GithubAPI()
    private init() {}
    
    class func configure(clientID: String, clientSecret: String, redirectURL: String) {
        shared.clientID = clientID
        shared.clientSecret = clientSecret
        shared.redirectURL = redirectURL
    }
    
    func requestAuthCode(scopes: [GithubScope]) throws {
        
        guard
            let clientID = self.clientID,
            let _ = self.clientSecret
            else {
                throw NSError(domain: "Client ID/Client Secret not set", code: 1, userInfo: nil)
        }
        let clientIDQuery = URLQueryItem(name: "client_id", value: clientID)
        let redirectURLQuery = URLQueryItem(name: "redirect_uri", value: self.redirectURL)
        
        let scopeQuery: URLQueryItem  = URLQueryItem(name: "scope", value: scopes.compactMap { $0.rawValue }.joined(separator: " "))
        
        var components = URLComponents(url: URL(string: GithubAPI.authorizationURL)!, resolvingAgainstBaseURL: true)
        components?.queryItems = [clientIDQuery, redirectURLQuery, scopeQuery]
        
        UIApplication.shared.open(components!.url!, options: [:], completionHandler: nil)
    }
    
    func requestToken(code: String?) {
        var request = URLRequest(url: URL(string: GithubAPI.accessTokenURL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let clientIDQuery = URLQueryItem(name: "client_id", value: self.clientID)
        let clientSecretQuery = URLQueryItem(name: "client_secret", value: self.clientSecret)
        let codeQuery = URLQueryItem(name: "code", value: code)
        let redirectURIQuery = URLQueryItem(name: "redirect_uri", value: self.redirectURL)
        
        var components = URLComponents(string: GithubAPI.accessTokenURL)
        components?.queryItems = [clientIDQuery, clientSecretQuery, codeQuery, redirectURIQuery]
        
        request.url = components?.url
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    return
                } else {
                    if let data = data {
                        do {
                            let model = try JSONDecoder().decode(AccessTokenResponse.self, from: data)
                            KeychainWrapper.standard.set(model.accessToken, forKey: "token")
                            self.accessToken = KeychainWrapper.standard.string(forKey: "token")
                        } catch let err {
                            print(err.localizedDescription)
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    func handleOpenUrl(url: URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            for queryItem in components.queryItems! {
                if queryItem.name == "code" {
                    if let accessCode = queryItem.value {
                        requestToken(code: accessCode)
                    }
                }
            }
        }
    }
    
    //MARK: Public functions
    
    public func printToken(complition: (String?) -> ()) {
        complition(KeychainWrapper.standard.string(forKey: "token"))
    }
    
    public func login() {
        if KeychainWrapper.standard.string(forKey: "token") == nil {
            do {
                try GithubAPI.shared.requestAuthCode(scopes: [.user, .repo])
            }
            catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            print("User already login")
        }
    }
    
    public func logout() {
        if KeychainWrapper.standard.string(forKey: "token") != nil {
            KeychainWrapper.standard.removeObject(forKey: "token")
        }
        accessToken = KeychainWrapper.standard.string(forKey: "token")
    }
    
    public func getAllRepositories(completion: @escaping ([Repository]) -> ()) {
        if accessToken != nil {
            if var components = URLComponents(string: "https://api.github.com/user/repos") {
                components.queryItems = [URLQueryItem(name: "access_token", value: self.accessToken!)]
                if let url = components.url {
                    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                        if let data = data {
                            do {
                                let repositories = try JSONDecoder().decode([Repository].self, from: data)
                                completion(repositories)
                            } catch let error {
                                print(error.localizedDescription)
                            }
                        }
                    }
                    task.resume()
                }
            }
        } else {
            print("User logout")
        }
    }
    
    public func getStarredRepositories(completion: @escaping ([Repository]) -> ()) {
        if accessToken != nil {
            var components = URLComponents(string: "https://api.github.com/user/starred")!
            components.queryItems = [URLQueryItem(name: "access_token", value: self.accessToken!)]
            if let url = components.url {
                let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let data = data {
                        do {
                            let starredRepositories = try JSONDecoder().decode([Repository].self, from: data)
                            completion(starredRepositories)
                        } catch let error {
                            print(error.localizedDescription)
                        }
                    }
                }
                task.resume()
            }
        } else {
            print("User logout")
        }
    }
}

