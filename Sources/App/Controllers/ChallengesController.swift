import Fluent
import Vapor

struct ChallengesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "challenges")
        let scores = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        scores.get(use: getAllChallenges)
        scores.get("byType", use: getChallengesByType)
    }
    
    @Sendable func getAllChallenges(req: Request) async throws -> Page<Challenge.ChallengeResponse> {
        let page = try await Challenge
            .query(on: req.db)
            .join(Game.self, on: \Challenge.$game.$id == \Game.$id)
            .sort(Game.self, \Game.$name)
            .with(\.$game)
            .paginate(for: req)
           
        let challengeResponses = try page.items.map { try $0.toChallengeResponse }
        
        return Page(items: challengeResponses, metadata: page.metadata)
    }
    
    @Sendable func getChallengesByType(req: Request) async throws ->  Page<Challenge.ChallengeResponse> {
        guard let typeName = req.query[String.self, at: "type"],
              let type = ChallengeType(rawValue: typeName) else {
                throw Abort(.badRequest, reason: "Query parameter 'typeName' is required")
        }
        
        let page = try await Challenge
            .query(on: req.db)
            .join(Game.self, on: \Challenge.$game.$id == \Game.$id)
            .sort(Game.self, \Game.$name)
            .with(\.$game)
            .filter(\.$type == type)
            .paginate(for: req)
           
        let challengesResponses = try page.items.map { try $0.toChallengeResponse }
        
        return Page(items: challengesResponses, metadata: page.metadata)
    }
    
    
}
