import Vapor
import Fluent

func getLanguage(req: Request) throws -> Language {
    guard let languageName = req.query[String.self, at: "lang"] else {
            throw Abort(.badRequest, reason: "Query parameter 'lang' is required")
    }
    
   return Language(rawValue: languageName) ?? Language.english
}

func getUser(req: Request) async throws -> User {
    let payload = try req.auth.require(UserPayload.self)
    
    guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
        throw Abort(.badRequest, reason: "User not found")
    }
    
    return user
}
