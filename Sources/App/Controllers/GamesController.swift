import Vapor
import Fluent

struct GamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "games")
        
        let games = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        games.get("list", use: getAllGames)
        games.get("byConsole", use: getGamesByConsole)
        games.get("featured", use: getFeaturedGames)
        games.get("search", use: searchGame)
        
        let favorites = games.grouped("favorites")
        favorites.get("list", use: getFavoriteGames)
        favorites.get("isFavorite", ":gameID", use: isFavoriteGame)
        favorites.post("add", use: addFavoriteGame)
        favorites.delete("delete", ":gameID", use: deleteFavoriteGame)
    }
    
    @Sendable func getAllGames(req: Request) async throws -> Page<Game.Response> {
        let language = try getLanguage(req: req)
        
        let page = try await Game.query(on: req.db)
            .sort(\.$name)
            .paginate(for: req)
        
        let gameResponses = try Game.toResponse(games: page.items, lang: language)
           
        return Page(items: gameResponses, metadata: page.metadata)
    }
    
    @Sendable func searchGame(req: Request) async throws -> [Game.Response] {
        let language = try getLanguage(req: req)
        
        guard let gameName = req.query[String.self, at: "game"] else {
                throw Abort(.badRequest, reason: "Query parameter 'gameName' is required")
        }

        let searchPattern = "%\(gameName)%"
        let games = try await Game
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), searchPattern)
            .sort(\.$name)
            .all()
    
        return try Game.toResponse(games: games, lang: language)
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
        
        let gameResponses = try Game.toResponse(games: page.items, lang: language)
        
        return Page(items: gameResponses, metadata: page.metadata)
    }
    
    @Sendable func getFeaturedGames(req: Request) async throws -> [Game.Response] {
        let language = try getLanguage(req: req)
        
        let games = try await Game
            .query(on: req.db)
            .filter(\.$featured == true)
            .sort(\.$name)
            .all()
        
        return try Game.toResponse(games: games, lang: language)
    }
    
    @Sendable func getFavoriteGames(req: Request) async throws -> [Game.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
         
        let games = try await user.$favoriteGames
            .query(on: req.db)
            .sort(FavoriteGame.self, \FavoriteGame.$createdAt)
            .all()
        
        return try Game.toResponse(games: games, lang: language)
    }
    
    @Sendable func isFavoriteGame(req: Request) async throws -> Bool {
        let user = try await getUser(req: req)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        return if try await game.$usersFavorites.isAttached(to: user, on: req.db) {
            true
        } else {
            false
        }
    }
    
    @Sendable func addFavoriteGame(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let gameDTO = try req.content.decode(GameDTO.self)
 
        guard let game = try await Game.find(gameDTO.gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        if try await user.$favoriteGames.isAttached(to: game, on: req.db) {
            throw Abort(.notFound, reason: "Game already favorite")
        } else {
            try await user.$favoriteGames.attach(game, on: req.db)
            return .created
        }
    }
    
    @Sendable func deleteFavoriteGame(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        if try await game.$usersFavorites.isAttached(to: user, on: req.db) {
            try await game.$usersFavorites.detach(user, on: req.db)
            return .ok
        } else {
            throw Abort(.badRequest, reason: "The game is not favorited")
        }   
    }
}
