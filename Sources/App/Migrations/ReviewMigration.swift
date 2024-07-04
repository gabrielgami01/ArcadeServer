import Vapor
import Fluent

struct ReviewMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Review.schema)
            .id()
            .field(.title, .string, .required)
            .field(.comment, .string)
            .field(.rating, .int, .required)
            .field(.createdAt, .datetime)
            .field(.game, .uuid, .required, .references(Game.schema, .id))
            .field(.user, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Review.schema)
            .delete()
    }
}
