import Vapor
import Fluent

struct UserMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field(.username, .string, .required)
            .unique(on: .username)
            .field(.password, .string, .required)
            .field(.email, .string, .required)
            .unique(on: .email)
            .field(.fullName, .string, .required)
            .field(.about, .string)
            .field(.avatar, .data)
            .field(.createdAt, .datetime)
            .create()
        
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(User.schema)
            .delete()
    }
}
