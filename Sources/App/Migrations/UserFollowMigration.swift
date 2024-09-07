import Vapor
import Fluent

struct UserFollowMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserFollow.schema)
            .id()
            .field(.createdAt, .datetime)
            .field(.follower, .uuid, .required, .references(User.schema, .id))
            .field(.followed, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(UserFollow.schema)
            .delete()
    }
}
