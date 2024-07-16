import Vapor
import Fluent

struct GamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "games")
        let games = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        games.get(use: getAllGames)
        games.get("byConsole", use: getGamesByConsole)
        games.get("featured", use: getFeaturedGames)
        games.get("search", use: searchGame)
        
        let favorites = games.grouped("favorites")
        favorites.group("") { game in
            game.get(use: getFavoriteGames)
            game.post(use: addFavoriteGame)
            game.delete(use: removeFavoriteGame)
        }
        favorites.get(":gameID", use: isFavoriteGame)
    }
    
    @Sendable func getAllGames(req: Request) async throws -> Page<Game.GameResponse> {
        let page = try await Game.query(on: req.db)
               .paginate(for: req)
           
        let gameResponses = try page.items.map { try $0.toGameResponse }
           
        return Page(items: gameResponses, metadata: page.metadata)
    }
    
    @Sendable func searchGame(req: Request) async throws -> Page<Game.GameResponse> {
        guard let gameName = req.query[String.self, at: "game"] else {
                throw Abort(.badRequest, reason: "Query parameter 'gameName' is required")
        }
        //Esto envuelve gameName con comodines %, lo que significa que cualquier juego cuyo nombre contenga gameName será coincidente.
        let searchPattern = "%\(gameName)%"

        let page = try await Game
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), searchPattern)
            .paginate(for: req)
        
        let gameResponses = try page.items.map { try $0.toGameResponse }
        
        return Page(items: gameResponses, metadata: page.metadata)
    }
    
    @Sendable func getGamesByConsole(req: Request) async throws -> Page<Game.GameResponse> {
        guard let consoleName = req.query[String.self, at: "console"],
              let console = Console(rawValue: consoleName) else {
                throw Abort(.badRequest, reason: "Query parameter 'consoleName' is required")
        }
        
        let page = try await Game
            .query(on: req.db)
            .filter(\.$console == console)
            .paginate(for: req)
           
        let gameResponses = try page.items.map { try $0.toGameResponse }
        
        return Page(items: gameResponses, metadata: page.metadata)
    }
    
    @Sendable func getFeaturedGames(req: Request) async throws -> [Game.GameResponse] {
        let games = try await Game
            .query(on: req.db)
            .filter(\.$featured == true)
            .all()
        
        return try Game.toGameResponse(games: games)
    }
    
    @Sendable func addFavoriteGame(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        let gameDTO = try req.content.decode(GameDTO.self)
        
        guard let game = try await Game.find(gameDTO.id, on: req.db),
              let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
                
        //try await user.$games.load(on: req.db)
        try await user.$gamesFavorites.attach(game, method: .ifNotExists, on: req.db)
        return .created
    }
    
    @Sendable func removeFavoriteGame(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        let gameDTO = try req.content.decode(GameDTO.self)
        
        guard let game = try await Game.find(gameDTO.id, on: req.db),
              let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        if try await game.$usersFavorites.isAttached(to: user, on: req.db) {
            try await game.$usersFavorites.detach(user, on: req.db)
            return .ok
        } else {
            throw Abort(.badRequest, reason: "The game is not favorited")
        }
        
    }
    
    @Sendable func getFavoriteGames(req: Request) async throws -> [Game.GameResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.badRequest, reason: "User not found")

        }
        
        let games = try await user.$gamesFavorites
            .query(on: req.db) 
            .all()
        
        return try Game.toGameResponse(games: games)
    }
    
    @Sendable func isFavoriteGame(req: Request) async throws -> Bool {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db),
              let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        return if try await game.$usersFavorites.isAttached(to: user, on: req.db) {
            true
        } else {
            false
        }
    }
}
