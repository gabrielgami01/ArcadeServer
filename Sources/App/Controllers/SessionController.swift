import Vapor
import Fluent

struct SessionController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api","session")
        
        let session = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        session.post("start", use: startSession)
        session.put("end", ":sessionID", use: endSession)
        session.get("active", use: getActiveSession)
        session.get("list", ":gameID", use: getSessions)
        session.get("listFollowing", use: getFollowingActiveSessions)
    }
    
    @Sendable func startSession(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let gameDTO = try req.content.decode(GameDTO.self)
        guard let game = try await Game.find(gameDTO.gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        if let _ = try await user.$gamesSessions.$pivots
            .query(on: req.db)
            .filter(\.$status == .active)
            .first() {
            throw Abort(.conflict, reason: "An active session has already started.")
        }

        try await user.$gamesSessions.attach(game, on: req.db)
        return .created
    }
    
    @Sendable func endSession(req: Request) async throws -> HTTPStatus {
        guard let sessionID = req.parameters.get("sessionID", as: UUID.self),
              let session = try await Session.find(sessionID, on: req.db) else {
            throw Abort(.notFound, reason: "Session not found")
        }
        
        session.status = .finished
        try await session.update(on: req.db)
        
        return .ok
    }
    
    @Sendable func getActiveSession(req: Request) async throws -> Session.Response {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        guard let session = try await user.$gamesSessions
            .$pivots
            .query(on: req.db)
            .with(\.$game)
            .with(\.$user)
            .filter(\.$status == .active)
            .first() else {
            throw Abort(.noContent, reason: "No active game session found")
        }
        return try session.toResponse(lang: .english)
    }
    
    @Sendable func getSessions(req: Request) async throws -> [Session.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let sessions = try await user.$gamesSessions
            .$pivots
            .query(on: req.db)
            .with(\.$game)
            .with(\.$user)
            .filter(\.$game.$id == game.requireID())
            .filter(\.$status == .finished)
            .sort(\.$createdAt, .descending)
            .all()
        
        return try Session.toResponse(sessions: sessions, lang: language)
    }
    
    @Sendable func getFollowingActiveSessions(req: Request) async throws -> [Session.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        let activeSessions = try await Session
            .query(on: req.db)
            .join(UserConnections.self, on: \Session.$user.$id == \UserConnections.$followed.$id)
            .with(\.$game)
            .with(\.$user)
            .filter(UserConnections.self, \UserConnections.$follower.$id == user.requireID())
            .filter(\Session.$status == .active)
            .all()
        
        return try Session.toResponse(sessions: activeSessions, lang: language)
    }
}
