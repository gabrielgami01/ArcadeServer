import Vapor
import Fluent

extension User: @unchecked Sendable {}

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .username) var username: String
    @Field(key: .password) var password: String
    @Field(key: .email) var email: String
    @Field(key: .biography) var biography: String?
    @Field(key: .avatarURL) var avatarURL: String?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, username: String, password: String, email: String, biography: String? = nil, avatarURL: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.username = username
        self.password = password
        self.email = email
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
    }
}
