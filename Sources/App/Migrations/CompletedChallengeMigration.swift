import Vapor
import Fluent

struct CompletedChallengeMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(CompletedChallenge.schema)
            .id()
            .field(.featured, .bool, .required)
            .field(.order, .int)
            .field(.completedAt, .datetime)
            .field(.challenge, .uuid, .required, .references(Challenge.schema, .id))
            .field(.user, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(CompletedChallenge.schema)
            .delete()
    }
}
