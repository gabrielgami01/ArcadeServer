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
    @Field(key: .avatarImage) var avatarImage: Data?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Siblings(through: FavoriteGame.self, from: \.$user, to: \.$game) var gamesFavorites: [Game]
    @Siblings(through: UserChallenges.self, from: \.$user, to: \.$challenge) var completedChallenges: [Challenge]
    @Siblings(through: Review.self, from: \.$user, to: \.$game) var gamesReviews: [Game]
    @Siblings(through: Score.self, from: \.$user, to: \.$game) var gamesScores: [Game]
    @Siblings(through: UserEmblems.self, from: \.$user, to: \.$challenge) var activeEmblems: [Challenge]
    @Siblings(through: UserConnections.self, from: \.$follower, to: \.$followed) var following: [User]
    @Siblings(through: UserConnections.self, from: \.$followed, to: \.$follower) var followers: [User]
    
    init() {}
    
    init(id: UUID? = nil, username: String, password: String, email: String, fullName: String, about: String? = nil, avatarImage: Data? = nil, createdAt: Date? = nil) {
        self.id = id
        self.username = username
        self.password = password
        self.email = email
        self.fullName = fullName
        self.about = about
        self.avatarImage = avatarImage
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
                             avatarImage: avatarImage)
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
