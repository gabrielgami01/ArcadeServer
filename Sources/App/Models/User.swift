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
    @Field(key: .biography) var biography: String?
    @Field(key: .avatarURL) var avatarURL: String?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Siblings(through: FavoriteGame.self, from: \.$user, to: \.$game) var gamesFavorites: [Game]
    @Siblings(through: UserChallenges.self, from: \.$user, to: \.$challenge) var completedChallenges: [Challenge]
    @Siblings(through: Review.self, from: \.$user, to: \.$game) var gamesReviews: [Game]
    @Siblings(through: Score.self, from: \.$user, to: \.$game) var gamesScores: [Game]
    
    init() {}
    
    init(id: UUID? = nil, username: String, password: String, email: String, fullName: String, biography: String? = nil, avatarURL: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.username = username
        self.password = password
        self.email = email
        self.fullName = fullName
        self.biography = biography
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password
    
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
    struct UserResponse: Content {
        let id: UUID
        let email: String
        let username: String
        let fullName: String
        let biography: String?
    }
    
    var toUserResponse: UserResponse {
        get throws {
            try UserResponse(id: requireID(),
                        email: email,
                        username: username,
                        fullName: fullName,
                        biography: biography)
        }
    }
    
    static func toUserResponse(users: [User]) throws -> [UserResponse] {
        var usersResponse = [UserResponse]()
        
        for user in users {
            let userResponse = try user.toUserResponse
            usersResponse.append(userResponse)
        }
        
        return usersResponse
    }
}
