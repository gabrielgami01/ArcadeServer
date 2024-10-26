import Vapor
import Fluent

struct SessionMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let status = try await database.enum("session_status").read()
        
        try await database.schema(Session.schema)
            .id()
            .field(.status, status, .required, .custom("DEFAULT 'active'"))
            .field(.createdAt, .datetime)
            .field(.finishedAt, .datetime)
            .field(.game, .uuid, .required, .references(Game.schema, .id))
            .field(.user, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Session.schema)
            .delete()
    }
}
