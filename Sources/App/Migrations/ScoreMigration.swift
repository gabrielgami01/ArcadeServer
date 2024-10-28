import Vapor
import Fluent

struct ScoreMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let status = try await database.enum("score_status").read()
        
        try await database.schema(Score.schema)
            .id()
            .field(.value, .int)
            .field(.status, status, .required, .custom("DEFAULT 'unverified'"))
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
