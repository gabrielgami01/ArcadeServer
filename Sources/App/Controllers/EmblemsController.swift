import Fluent
import Vapor

struct EmblemsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "emblems")
        
        let emblems = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        emblems.get("listActive", use: getActiveUserEmblems)
        emblems.get("listActive", ":userID", use: getUserEmblems)
        emblems.post("add", use: addEmblem)
        emblems.delete("delete", use: deleteEmblem)
    }
    
    @Sendable func getActiveUserEmblems(req: Request) async throws -> [Challenge.EmblemResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let emblems = try await user.$activeEmblems
            .query(on: req.db)
            .all()
        
        return try Challenge.toEmblemResponse(challenges: emblems)
    }
    
    @Sendable func getUserEmblems(req: Request) async throws -> [Challenge.EmblemResponse] {
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let emblems = try await user.$activeEmblems
            .query(on: req.db)
            .all()
        
        return try Challenge.toEmblemResponse(challenges: emblems)
    }
    
    @Sendable func addEmblem(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        let emblemDTO = try req.content.decode(CreateEmblemDTO.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db),
              let challenge = try await Challenge.find(emblemDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }
        
        try await user.$activeEmblems.attach(challenge, method: .ifNotExists, on: req.db)
        
        return .created
    }
    
    @Sendable func deleteEmblem(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        let emblemDTO = try req.content.decode(CreateEmblemDTO.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db),
              let challenge = try await Challenge.find(emblemDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }
        
        if try await user.$activeEmblems.isAttached(to: challenge, on: req.db) {
            try await user.$activeEmblems.detach(challenge, on: req.db)
        }
        
        return .ok
    }
    
}
