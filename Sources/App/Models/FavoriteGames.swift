import Vapor
import Fluent

extension FavoriteGame: @unchecked Sendable {}

final class FavoriteGame: Model, Content {
    static let schema = "favorite_games"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.$game.id = game
        self.$user.id = user
    }
}
