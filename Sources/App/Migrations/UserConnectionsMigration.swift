import Vapor
import Fluent

struct UserConnectionsMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserConnections.schema)
            .id()
            .field(.createdAt, .datetime)
            .field(.follower, .uuid, .required, .references(User.schema, .id))
            .field(.followed, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(UserConnections.schema)
            .delete()
    }
}