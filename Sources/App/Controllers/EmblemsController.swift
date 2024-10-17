import Fluent
import Vapor

struct EmblemsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "emblems")
        
        let emblems = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        emblems.get("listActive", use: getActiveUserEmblems)
        emblems.get("listActive", ":userID", use: getUserEmblems)
        emblems.post("add", use: addEmblem)
        emblems.delete("delete", ":challengeID", use: deleteEmblem)
    }
    
    @Sendable func getActiveUserEmblems(req: Request) async throws -> [UserEmblems.Response] {
        let user = try await getUser(req: req)
        
        let emblems = try await user.$activeEmblems
            .$pivots
            .query(on: req.db)
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
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
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
            .sort(\.$createdAt)
            .all()
        
        return try UserEmblems.toResponse(userEmblems: emblems)
    }
    
    @Sendable func addEmblem(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let emblemDTO = try req.content.decode(EmblemDTO.self)      
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
    
    @Sendable func deleteEmblem(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        guard let challengeID = req.parameters.get("challengeID", as: UUID.self),
              let challenge = try await Challenge.find(challengeID, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }
        
        if try await user.$activeEmblems.isAttached(to: challenge, on: req.db) {
            try await user.$activeEmblems.detach(challenge, on: req.db)
            return .ok
        } else {
            throw Abort(.notFound, reason: "Emblem not found")
        }
    }
    
    
}
