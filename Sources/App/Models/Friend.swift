import Vapor
import Fluent

extension Friend: @unchecked Sendable {}

final class Friend: Model, Content {
    static let schema = "friends"
    
    @ID(key: .id) var id: UUID?
    @Enum(key: .state) var state: FriendshipState
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    
    @Parent(key: .userA) var userA: User
    @Parent(key: .userB) var userB: User
    
    init() {}
    
    init(id: UUID? = nil, state: FriendshipState, createdAt: Date? = nil, userA: User.IDValue, userB: User.IDValue) {
        self.id = id
        self.state = state
        self.createdAt = createdAt
        self.$userA.id = userA
        self.$userB.id = userB
    }
}

