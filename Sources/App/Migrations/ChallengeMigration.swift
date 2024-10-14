import Vapor
import Fluent

struct ChallengeMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let type = try await database.enum("challenge_types").read()
        
        try await database.schema(Challenge.schema)
            .id()
            .field(.name, .string, .required)
            .field(.descriptionEn, .string, .required)
            .field(.descriptionEs, .string, .required)
            .field(.targetScore, .int, .required)
            .field(.type, type, .required, .custom("DEFAULT 'bronze'"))
            .field(.game, .uuid, .required, .references(Game.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Challenge.schema)
            .delete()
    }
}
