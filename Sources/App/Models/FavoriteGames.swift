import Vapor
import Fluent

extension FavoriteGame: @unchecked Sendable {}

final class FavoriteGame: Model, Content {
    static let schema = "favorite_games"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, createdAt: Date? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.createdAt = createdAt
        self.$game.id = game
        self.$user.id = user
    }
}
