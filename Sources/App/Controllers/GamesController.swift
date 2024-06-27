import Vapor
import Fluent

struct GamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "games")
        let jwtSecure = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        jwtSecure.get("byConsole", ":consoleID", use: getGamesByConsole)
        jwtSecure.get("byGenre", ":genreID", use: getGamesByGenre)
    }
    
    @Sendable func getGamesByConsole(req: Request) async throws -> [Game.GameResponse] {
        guard let consoleID = req.parameters.get("consoleID", as: UUID.self),
              let console = try await Console.find(consoleID, on: req.db) else {
            throw Abort(.notFound, reason: "Console not found")
        }
        
        let games = try await console.$games
            .query(on: req.db)
            .with(\.$console)
            .with(\.$genre)
            .all()
        
        return try Game.toGameResponse(games: games)
    }
    
    @Sendable func getGamesByGenre(req: Request) async throws -> [Game.GameResponse] {
        guard let genreID = req.parameters.get("genreID", as: UUID.self),
              let genre = try await Genre.find(genreID, on: req.db) else {
            throw Abort(.notFound, reason: "Genre not found")
        }
        
        let games = try await genre.$games
            .query(on: req.db)
            .with(\.$console)
            .with(\.$genre)
            .all()
        
        return try Game.toGameResponse(games: games)
    }
}
