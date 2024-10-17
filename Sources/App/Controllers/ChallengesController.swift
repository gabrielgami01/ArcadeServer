import Fluent
import Vapor

struct ChallengesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "challenges")
        
        let challenges = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        challenges.get("list", use: getChallenges)
    }
    
    @Sendable func getChallenges(req: Request) async throws -> [Challenge.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        let challenges = try await Challenge
            .query(on: req.db)
            .join(Game.self, on: \Challenge.$game.$id == \Game.$id)
            .sort(Game.self, \Game.$name)
            .with(\.$game)
            .all()
        
        return try await Challenge.toResponse(challenges: challenges, for: user, lang: language, on: req.db)
    }
}
