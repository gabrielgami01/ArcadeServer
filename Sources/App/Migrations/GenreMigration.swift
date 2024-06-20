import Vapor
import Fluent

struct GenreMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Genre.schema)
            .id()
            .field(.name, .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Genre.schema)
            .delete()
    }
}
