import Fluent
import Vapor

struct EmblemsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "emblems")
        
        let emblems = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        emblems.get("listActive", use: getActiveUserEmblems)
        emblems.get("listActive", ":userID", use: getUserEmblems)
        emblems.post("add", use: addEmblem)
        emblems.delete("update", "emblemID", use: updateEmblem)
    }
    
    @Sendable func getActiveUserEmblems(req: Request) async throws -> [UserEmblems.Response] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let emblems = try await user.$activeEmblems
            .$pivots
            .query(on: req.db)
            .all()
        
        return try UserEmblems.toResponse(userEmblems: emblems)
    }
    
    @Sendable func getUserEmblems(req: Request) async throws -> [UserEmblems.Response] {
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let emblems = try await user.$activeEmblems
            .$pivots
            .query(on: req.db)
            .sort(\.$createdAt)
            .all()
        
        return try UserEmblems.toResponse(userEmblems: emblems)
    }
    
    @Sendable func addEmblem(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        let emblemDTO = try req.content.decode(EmblemDTO.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        guard let challenge = try await Challenge.find(emblemDTO.challengeID, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }
        
        if try await user.$activeEmblems.isAttached(to: challenge, on: req.db) {
            throw Abort(.notFound, reason: "Emblem already on use")
        } else {
            try await user.$activeEmblems.attach(challenge, on: req.db)
            return .created
        }
    }
    
    @Sendable func updateEmblem(req: Request) async throws -> HTTPStatus {
        let emblemDTO = try req.content.decode(EmblemDTO.self)
        
        guard let emblemID = req.parameters.get("emblemID", as: UUID.self),
              let emblem = try await UserEmblems.find(emblemID, on: req.db) else {
            throw Abort(.notFound, reason: "Emblem not found")
        }
        
        guard let challenge = try await Challenge.find(emblemDTO.challengeID, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }
        
        emblem.challenge = challenge
        try await emblem.update(on: req.db)
        
        return .created
    }
    
    
}
