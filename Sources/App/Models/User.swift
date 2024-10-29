import Vapor
import Fluent

extension User: @unchecked Sendable {}

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .username) var username: String
    @Field(key: .password) var password: String
    @Field(key: .email) var email: String
    @Field(key: .fullName) var fullName: String
    @Field(key: .about) var about: String?
    @Field(key: .avatar) var avatar: Data?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Children(for: \.$user) var reviews: [Review]
    @Children(for: \.$user) var scores: [Score]
    @Children(for: \.$user) var sessions: [Session]
    
    @Siblings(through: FavoriteGame.self, from: \.$user, to: \.$game) var favoriteGames: [Game]
    @Siblings(through: Badge.self, from: \.$user, to: \.$challenge) var badges: [Challenge]
    @Siblings(through: Connections.self, from: \.$followed, to: \.$follower) var followers: [User]
    @Siblings(through: Connections.self, from: \.$follower, to: \.$followed) var following: [User]
    
    init() {}
    
    init(id: UUID? = nil, username: String, password: String, email: String, fullName: String, about: String? = nil, avatar: Data? = nil, createdAt: Date? = nil) {
        self.id = id
        self.username = username
        self.password = password
        self.email = email
        self.fullName = fullName
        self.about = about
        self.avatar = avatar
        self.createdAt = createdAt
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> {
        \User.$username
    }
    
    static var passwordHashKey: KeyPath<User, Field<String>> {
        \User.$password
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify("\(self.username)@\(password)", created: self.password)
    }
}

extension User: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...) && .alphanumeric)
        validations.add("username", as: String.self, is: .count(6...))
    }
}

extension User: ModelSessionAuthenticatable, ModelCredentialsAuthenticatable {}

extension User {
    struct Response: Content {
        let id: UUID
        let email: String
        let username: String
        let fullName: String
        let about: String?
        let avatarImage: Data?
    }
    
    var toResponse: Response {
        get throws {
            try Response(id: requireID(),
                             email: email,
                             username: username,
                             fullName: fullName,
                             about: about,
                             avatarImage: avatar)
        }
    }
    
    static func toResponse(users: [User]) throws -> [Response] {
        var responses = [Response]()
        
        for user in users {
            let response = try user.toResponse
            responses.append(response)
        }
        
        return responses
    }
}
