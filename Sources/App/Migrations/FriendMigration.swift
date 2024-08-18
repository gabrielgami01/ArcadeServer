import Vapor
import Fluent

struct FriendMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let state = try await database.enum("friendship_state").read()
        
        try await database.schema(Friend.schema)
            .id()
            .field(.state, state, .required, .custom("DEFAULT 'pending'"))
            .field(.createdAt, .datetime)
            .field(.userA, .uuid, .required, .references(User.schema, .id))
            .field(.userB, .uuid, .required, .references(User.schema, .id))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Friend.schema)
            .delete()
    }
}
