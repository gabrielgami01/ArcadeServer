import Fluent
import Vapor

struct ChallengesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "challenges")
        
        let challenges = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        challenges.get("list", use: getChallenges)
    }
    
    @Sendable func getChallenges(req: Request) async throws -> [Challenge.Response] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.badRequest, reason: "User not found")
        }
        
        guard let languageName = req.query[String.self, at: "lang"] else {
                throw Abort(.badRequest, reason: "Query parameter 'lang' is required")
        }
        
        let language = Language(rawValue: languageName) ?? Language.english
        
        let challenges = try await Challenge
            .query(on: req.db)
            .join(Game.self, on: \Challenge.$game.$id == \Game.$id)
            .sort(Game.self, \Game.$name)
            .with(\.$game)
            .all()
        
        return try await Challenge.toResponse(challenges: challenges, for: user, lang: language, on: req.db)
    }
}
