import Vapor
import Fluent

struct ScoreMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let state = try await database.enum("score_states").read()
        
        try await database.schema(Score.schema)
            .id()
            .field(.score, .int)
            .field(.state, state, .required, .custom("DEFAULT 'unverified'"))
            .field(.reviewed, .bool, .required, .custom("DEFAULT 'false'"))
            .field(.createdAt, .datetime)
            .field(.game, .uuid, .required, .references(Game.schema, .id))
            .field(.user, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Score.schema)
            .delete()
    }
}
