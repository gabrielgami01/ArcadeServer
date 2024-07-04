import Vapor
import Fluent

struct GamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "games")
        let games = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        games.get(use: getAllGames)
        games.get("byConsole", ":consoleID", use: getGamesByConsole)
        games.get("byGenre", ":genreID", use: getGamesByGenre)
        games.get("featured", use: getFeaturedGames)
        games.get("search", use: searchGame)
        
        games.group("favorites") { game in
            game.get(use: getUserFavoriteGames)
            game.post(use: addFavoriteGame)
            game.delete(use: removeFavoriteGame)
        }
        
        games.group("reviews") { game in
            game.get(use: getUserFavoriteGames)
            game.post(use: addFavoriteGame)
            game.delete(use: removeFavoriteGame)
        }
    }
    
    @Sendable func getAllGames(req: Request) async throws -> [Game.GameResponse] {
        let games = try await Game
            .query(on: req.db)
            .with(\.$console)
            .with(\.$genre)
            .all()
        
        return try Game.toGameResponse(games: games)
    }
    
    @Sendable func searchGame(req: Request) async throws -> [Game.GameResponse] {
        guard let gameName = req.query[String.self, at: "gameName"] else {
                throw Abort(.badRequest, reason: "Query parameter 'gameName' is required")
            }
        //Esto envuelve gameName con comodines %, lo que significa que cualquier juego cuyo nombre contenga gameName será coincidente.
        let searchPattern = "%\(gameName)%"

        let games = try await Game
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), searchPattern)
            .with(\.$console)
            .with(\.$genre)
            .all()
        
        return try Game.toGameResponse(games: games)
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
    
    @Sendable func getFeaturedGames(req: Request) async throws -> [Game.GameResponse] {
        let games = try await Game
            .query(on: req.db)
            .filter(\.$featured == true)
            .with(\.$console)
            .with(\.$genre)
            .all()
        
        return try Game.toGameResponse(games: games)
    }
    
    
    @Sendable func addFavoriteGame(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        let gameDTO = try req.content.decode(FavoriteGameDTO.self)
        
        guard let game = try await Game.find(gameDTO.id, on: req.db),
              let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
                
        //try await user.$games.load(on: req.db)
        try await user.$gamesFavorites.attach(game, method: .ifNotExists, on: req.db)
        return .ok
    }
    
    @Sendable func removeFavoriteGame(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        let gameDTO = try req.content.decode(FavoriteGameDTO.self)
        
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
    
    @Sendable func getUserFavoriteGames(req: Request) async throws -> [Game.GameResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.badRequest, reason: "User not found")

        }
        
        let games = try await user.$gamesFavorites
            .query(on: req.db)
            .with(\.$console)
            .with(\.$genre)
            .all()
        
        return try Game.toGameResponse(games: games)
    }
}
