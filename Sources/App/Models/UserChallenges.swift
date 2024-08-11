import Vapor
import Fluent

extension UserChallenges: @unchecked Sendable {}

final class UserChallenges: Model, Content {
    static let schema = "user_challenges"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    @Parent(key: .challenge) var challenge: Challenge
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, createdAt: Date? = nil, challenge: Challenge.IDValue, user: User.IDValue) {
        self.id = id
        self.createdAt = createdAt
        self.$challenge.id = challenge
        self.$user.id = user
    }
}

