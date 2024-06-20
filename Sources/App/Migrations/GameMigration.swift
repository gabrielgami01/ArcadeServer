import Vapor
import Fluent

struct GameMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Game.schema)
            .id()
            .field(.name, .string, .required)
            .field(.description, .string, .required)
            .field(.releaseDate, .date, .required)
            .field(.console, .uuid, .required, .references(Console.schema, .id))
            .field(.genre, .uuid, .required, .references(Genre.schema, .id))
            .field(.imageURL, .string)
            .field(.videoURL, .string)
            .field(.featured, .bool, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Game.schema)
            .delete()
    }
}
