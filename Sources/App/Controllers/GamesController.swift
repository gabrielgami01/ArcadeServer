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
        guard let languageName = req.query[String.self, at: "lang"] else {
                throw Abort(.badRequest, reason: "Query parameter 'lang' is required")
        }
        
        let language = Language(rawValue: languageName) ?? Language.english
        
        let page = try await Game.query(on: req.db)
            .sort(\.$name)
            .paginate(for: req)
        
        let gameResponses = try Game.toResponse(games: page.items, lang: language)
           
        return Page(items: gameResponses, metadata: page.metadata)
    }
    
    @Sendable func searchGame(req: Request) async throws -> [Game.Response] {
        guard let languageName = req.query[String.self, at: "lang"] else {
                throw Abort(.badRequest, reason: "Query parameter 'lang' is required")
        }
        
        let language = Language(rawValue: languageName) ?? Language.english
        
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
        
        guard let languageName = req.query[String.self, at: "lang"] else {
                throw Abort(.badRequest, reason: "Query parameter 'lang' is required")
        }
        
        let language = Language(rawValue: languageName) ?? Language.english
        
        let page = try await Game
            .query(on: req.db)
            .filter(\.$console == console)
            .sort(\.$name)
            .paginate(for: req)
        
        let gameResponses = try Game.toResponse(games: page.items, lang: language)
        
        return Page(items: gameResponses, metadata: page.metadata)
    }
    
    @Sendable func getFeaturedGames(req: Request) async throws -> [Game.Response] {
        guard let languageName = req.query[String.self, at: "lang"] else {
                throw Abort(.badRequest, reason: "Query parameter 'lang' is required")
        }
        
        let language = Language(rawValue: languageName) ?? Language.english
        
        let games = try await Game
            .query(on: req.db)
            .filter(\.$featured == true)
            .sort(\.$name)
            .all()
        
        return try Game.toResponse(games: games, lang: language)
    }
    
    @Sendable func getFavoriteGames(req: Request) async throws -> [Game.Response] {
        guard let languageName = req.query[String.self, at: "lang"] else {
                throw Abort(.badRequest, reason: "Query parameter 'lang' is required")
        }
        
        let language = Language(rawValue: languageName) ?? Language.english
        
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.badRequest, reason: "User not found")
        }
        
        let games = try await user.$favoriteGames
            .query(on: req.db)
            .sort(FavoriteGame.self, \FavoriteGame.$createdAt)
            .all()
        
        return try Game.toResponse(games: games, lang: language)
    }
    
    @Sendable func isFavoriteGame(req: Request) async throws -> Bool {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.badRequest, reason: "User not found")
        }
        
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
        let payload = try req.auth.require(UserPayload.self)
        let favoriteDTO = try req.content.decode(FavoriteDTO.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.badRequest, reason: "User not found")
        }
        
        guard let game = try await Game.find(favoriteDTO.gameID, on: req.db) else {
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
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.badRequest, reason: "User not found")
        }
        
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
