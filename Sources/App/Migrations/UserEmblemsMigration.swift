import Vapor
import Fluent

struct UserEmblemsMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserEmblems.schema)
            .id()
            .field(.createdAt, .datetime)
            .field(.challenge, .uuid, .required, .references(Challenge.schema, .id))
            .field(.user, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(UserEmblems.schema)
            .delete()
    }
}
