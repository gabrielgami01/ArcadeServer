import Vapor
import Fluent

struct SessionController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api","sessions")
        
        let session = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        session.get(":gameID", use: getGameSessions)
        session.get("active", use: getActiveSession)
        session.get("following", use: getFollowingActiveSessions)
        session.post(":gameID", use: startSession)
        session.patch(":sessionID", use: finishSession)
    }
    
    @Sendable func getActiveSession(req: Request) async throws -> Session.Response {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        guard let activeSession = try await user.$sessions
            .query(on: req.db)
            .with(\.$game)
            .with(\.$user)
            .filter(\.$status == .active)
            .first() else {
            throw Abort(.notFound, reason: "No active session found.")
        }
        
        return try activeSession.toResponse(lang: language)
    }
    
    @Sendable func getGameSessions(req: Request) async throws -> [Session.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        let sessions = try await user.$sessions
            .query(on: req.db)
            .with(\.$game)
            .with(\.$user)
            .filter(\.$game.$id == game.requireID())
            .filter(\.$status == .finished)
            .sort(\.$startedAt, .descending)
            .all()
        
        return try Session.toResponse(sessions, lang: language)
    }
    
    @Sendable func getFollowingActiveSessions(req: Request) async throws -> [Session.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        let activeSessions = try await Session
            .query(on: req.db)
            .join(Connections.self, on: \Session.$user.$id == \Connections.$followed.$id)
            .with(\.$game)
            .with(\.$user)
            .filter(Connections.self, \Connections.$follower.$id == user.requireID())
            .filter(\Session.$status == .active)
            .all()
        
        return try Session.toResponse(activeSessions, lang: language)
    }
    
    @Sendable func startSession(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
                
        guard let gameID = req.parameters.get("gameID", as: UUID.self),
              let game = try await Game.find(gameID, on: req.db) else {
            throw Abort(.notFound, reason: "Game not found")
        }
        
        if let _ = try await user.$sessions
            .query(on: req.db)
            .filter(\.$status == .active)
            .first() {
            throw Abort(.badRequest, reason: "User already has an active session.")
        }
        
        let session = try Session(status: .active, game: game.requireID(), user: user.requireID())
        try await session.create(on: req.db)
        
        return .created
    }
    
    @Sendable func finishSession(req: Request) async throws -> HTTPStatus {
        guard let sessionID = req.parameters.get("sessionID", as: UUID.self),
              let session = try await Session.find(sessionID, on: req.db) else {
            throw Abort(.notFound, reason: "Session not found")
        }
        
        session.status = .finished
        try await session.update(on: req.db)
        
        return .ok
    }
}
