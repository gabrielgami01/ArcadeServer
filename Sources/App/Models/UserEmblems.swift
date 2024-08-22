import Vapor
import Fluent

extension UserEmblems: @unchecked Sendable {}

final class UserEmblems: Model, Content {
    static let schema = "user_emblems"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: .challenge) var challenge: Challenge
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, challenge: Challenge.IDValue, user: User.IDValue) {
        self.id = id
        self.$challenge.id = challenge
        self.$user.id = user
    }
}
