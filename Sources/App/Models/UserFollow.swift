import Vapor
import Fluent

extension UserFollow: @unchecked Sendable {}

final class UserFollow: Model {
    static let schema = "user_follow"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    @Parent(key: .follower)var follower: User
    @Parent(key: .followed)var followed: User

    init() {}

    init(id: UUID? = nil, createdAt: Date? = nil, follower: User.IDValue, followed: User.IDValue) {
        self.id = id
        self.createdAt = createdAt
        self.$follower.id = follower
        self.$followed.id = followed
    }
}
