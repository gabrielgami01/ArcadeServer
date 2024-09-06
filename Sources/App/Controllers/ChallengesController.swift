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
}
