import Vapor
import Fluent

struct GameMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let console = try await database.enum("consoles").read()
        let genre = try await database.enum("genres").read()
        
        try await database.schema(Game.schema)
            .id()
            .field(.name, .string, .required)
            .field(.description, .string, .required)
            .field(.console, console, .required, .custom("DEFAULT 'Arcade'"))
            .field(.genre, genre, .required, .custom("DEFAULT 'Arcade'"))
            .field(.releaseDate, .date, .required)
            .field(.featured, .bool, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Game.schema)
            .delete()
    }
}
