import Vapor
import Fluent

struct RankingsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "rankings")
        let rankings = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        
        rankings.get("list", ":gameID", use: getGameRanking)
    }
    
    @Sendable func getGameRanking(req: Request) async throws -> Page<Score.RankingScore> {
        //let payload = try req.auth.require(UserPayload.self)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let page = try await game.$usersScores
            .$pivots
            .query(on: req.db)
            .filter(\.$state == .verified)
            .sort(\.$score)
            .paginate(for: req)
        let rankingScoreResponse = try Score.toRankingScore(scores: page.items)
        
        return Page(items: rankingScoreResponse, metadata: page.metadata)
    }
}
