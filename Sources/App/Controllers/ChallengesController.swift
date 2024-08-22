import Fluent
import Vapor

struct ChallengesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "challenges")
        
        let challenges = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        challenges.get("list", use: getAllChallenges)
        challenges.get("byType", use: getChallengesByType)
        challenges.get("listCompleted", use: getCompletedChallenges)
        challenges.get("isCompleted", ":challengeID", use: isChallengeCompleted)
        
        let emblems = challenges.grouped("emblems")
        emblems.get("listActive", use: getUserEmblems)
        emblems.post("add", use: addEmblem)
        emblems.delete("delete", use: deleteEmblem)
    }
    
    @Sendable func getAllChallenges(req: Request) async throws -> [Challenge.ChallengeResponse] {
        let challenges = try await Challenge
            .query(on: req.db)
            .join(Game.self, on: \Challenge.$game.$id == \Game.$id)
            .sort(Game.self, \Game.$name)
            .with(\.$game)
            .all()
        
        return try Challenge.toChallengeResponse(challenges: challenges)
    }
    
    @Sendable func getChallengesByType(req: Request) async throws ->  [Challenge.ChallengeResponse] {
        guard let typeName = req.query[String.self, at: "type"],
              let type = ChallengeType(rawValue: typeName) else {
                throw Abort(.badRequest, reason: "Query parameter 'typeName' is required")
        }
        
        let challenges = try await Challenge
            .query(on: req.db)
            .join(Game.self, on: \Challenge.$game.$id == \Game.$id)
            .sort(Game.self, \Game.$name)
            .with(\.$game)
            .filter(\.$type == type)
            .all()
        
        return try Challenge.toChallengeResponse(challenges: challenges)
    }
    
    @Sendable func isChallengeCompleted(req: Request) async throws -> Bool {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db),
              let challengeID = req.parameters.get("challengeID", as: UUID.self),
              let challenge = try await Challenge.find(challengeID, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }
        
        return if try await challenge.$users.isAttached(to: user, on: req.db) {
            true
        } else {
            false
        }
    }
    
    @Sendable func getCompletedChallenges(req: Request) async throws -> [Challenge.ChallengeResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let challenges = try await user.$completedChallenges
            .query(on: req.db)
            .with(\.$game)
            .all()
        
        return try Challenge.toChallengeResponse(challenges: challenges)
    }
    
    @Sendable func getUserEmblems(req: Request) async throws -> [Challenge.EmblemResponse] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
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
