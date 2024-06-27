import Vapor
import Fluent

struct MastersMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Console.schema)
            .id()
            .field(.name, .string, .required)
            .create()
        
        try await database.schema(Genre.schema)
            .id()
            .field(.name, .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Console.schema)
            .delete()
        
        try await database.schema(Genre.schema)
            .delete()
    }
}

