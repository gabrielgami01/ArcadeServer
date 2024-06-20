import Vapor
import Fluent

struct ConsoleMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Console.schema)
            .id()
            .field(.name, .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Console.schema)
            .delete()
    }
}
