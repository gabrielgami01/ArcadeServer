import Vapor
import Foundation

struct FavoriteGamesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "favorites")
        
        let favorites = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        
        favorites.get(use: getFavoriteGames)
        favorites.get(":gameID", use: isFavoriteGame)
        favorites.post(":gameID", use: addFavoriteGame)
        favorites.delete(":gameID", use: deleteFavoriteGame)
    }
    
    @Sendable func getFavoriteGames(req: Request) async throws -> [Game.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        let games = try await user.$favoriteGames
            .query(on: req.db)
            .sort(FavoriteGame.self, \FavoriteGame.$createdAt, .descending)
            .all()
        
        return try Game.toResponse(games, lang: language)
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
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        if try await user.$favoriteGames.isAttached(to: game, on: req.db) {
            throw Abort(.conflict, reason: "Game already favorite")
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
        
        if try await user.$favoriteGames.isAttached(to: game, on: req.db) {
            try await user.$favoriteGames.detach(game, on: req.db)
            return .ok
        } else {
            throw Abort(.badRequest, reason: "Game not in favorites")
        }
    }
}
