import Vapor
import Fluent

struct GamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "games")
        
        let games = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        games.get(use: getGamesList)
        games.get("byConsole", use: getGamesByConsole)
        games.get("byName", use: getGamesByName)
        games.get("featured", use: getFeaturedGames)
    }
    
    @Sendable func getGamesList(req: Request) async throws -> Page<Game.Response> {
        let language = try getLanguage(req: req)
        
        let page = try await Game
            .query(on: req.db)
            .sort(\.$name)
            .paginate(for: req)
        
        let responses = try Game.toResponse(page.items, lang: language)
        
        return Page(items: responses, metadata: page.metadata)
    }
    
    @Sendable func getGamesByConsole(req: Request) async throws -> Page<Game.Response> {
        guard let consoleName = req.query[String.self, at: "console"],
              let console = Console(rawValue: consoleName) else {
            throw Abort(.badRequest, reason: "Query parameter 'consoleName' is required")
        }
        
        let language = try getLanguage(req: req)
        
        let page = try await Game
            .query(on: req.db)
            .filter(\.$console == console)
            .sort(\.$name)
            .paginate(for: req)
        
        let responses = try Game.toResponse(page.items, lang: language)
        
        return Page(items: responses, metadata: page.metadata)
    }
    
    @Sendable func getGamesByName(req: Request) async throws -> [Game.Response] {
        guard let name = req.query[String.self, at: "name"] else {
                throw Abort(.badRequest, reason: "Query parameter 'name' is required")
        }
        
        let language = try getLanguage(req: req)

        let searchPattern = "%\(name)%"
        let games = try await Game
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), searchPattern)
            .sort(\.$name)
            .all()
        
        return try Game.toResponse(games, lang: language)
    }
    
    @Sendable func getFeaturedGames(req: Request) async throws -> [Game.Response] {
        let language = try getLanguage(req: req)
        
        let games = try await Game
            .query(on: req.db)
            .filter(\.$featured == true)
            .sort(\.$name)
            .all()
        
        return try Game.toResponse(games, lang: language)
    }
}
