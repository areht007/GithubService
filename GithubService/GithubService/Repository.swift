//
//  Repository.swift
//  GithubOAuthClient
//
//  Created by Zhassulan Aimukhambetov on 10/22/19.
//  Copyright © 2019 Zhassulan Aimukhambetov. All rights reserved.
//

import Foundation

public struct Repository: Decodable {
    public private(set) var id: Int = -1
    public private(set) var owner = User()
    public var name: String?
    public var fullName: String?
    public private(set) var isPrivate: Bool = false
    public var repositoryDescription: String?
    public private(set) var isFork: Bool = false
    public var gitURL: String?
    public var sshURL: String?
    public var cloneURL: String?
    public var htmlURL: String?
    public private(set) var size: Int = -1
    public var lastPush: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case name
        case fullName = "full_name"
        case isPrivate = "private"
        case repositoryDescription = "description"
        case isFork = "fork"
        case gitURL = "git_url"
        case sshURL = "ssh_url"
        case cloneURL = "clone_url"
        case htmlURL = "html_url"
        case size
        case lastPush = "pushed_at"
    }
}

public struct User: Decodable {
    public internal(set) var id: Int = -1
    public var login: String?
    public var avatarURL: String?
    public var gravatarID: String?
    public var type: String?
    public var name: String?
    public var company: String?
    public var blog: String?
    public var location: String?
    public var email: String?
    public var numberOfPublicRepos: Int?
    public var numberOfPublicGists: Int?
    public var numberOfPrivateRepos: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarURL = "avatar_url"
        case gravatarID = "gravatar_id"
        case type
        case name
        case company
        case blog
        case location
        case email
        case numberOfPublicRepos = "public_repos"
        case numberOfPublicGists = "public_gists"
        case numberOfPrivateRepos = "total_private_repos"
    }
}
