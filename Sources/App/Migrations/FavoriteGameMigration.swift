import Vapor
import Fluent

struct FavoriteGameMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(FavoriteGame.schema)
            .id()
            .field(.createdAt, .datetime)
            .field(.game, .uuid, .required, .references(Game.schema, .id))
            .field(.user, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(FavoriteGame.schema)
            .delete()
    }
}
