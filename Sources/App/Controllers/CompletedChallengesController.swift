import Fluent
import Vapor

struct CompletedChallengesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "completedChallenges")
        
        let completedChallenges = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        completedChallenges.get(use: getCompletedChallenges)
        completedChallenges.get("featured",use: getFeaturedChallenges)
        completedChallenges.get("featured",":userID",use: getUserFeaturedChallenges)
        completedChallenges.patch("highlight", use: highlightChallenge)
        completedChallenges.patch("unhighlight", ":completedChallengeID", use: unhighlightChallenge)
    }
    
    @Sendable func getCompletedChallenges(req: Request) async throws -> [CompletedChallenge.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        let challenges = try await user.$completedChallenges
            .$pivots
            .query(on: req.db)
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
            .sort(\.$order)
            .all()
        
        return try CompletedChallenge.toResponse(challenges, lang: language)
    }
    
    @Sendable func getFeaturedChallenges(req: Request) async throws -> [CompletedChallenge.Response] {
        let user = try await getUser(req: req)
        
        let language = try getLanguage(req: req)
        
        let challenges = try await user.$completedChallenges
            .$pivots
            .query(on: req.db)
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
            .filter(\.$featured == true)
            .sort(\.$order)
            .all()
        
        return try CompletedChallenge.toResponse(challenges, lang: language)
    }
    
    @Sendable func getUserFeaturedChallenges(req: Request) async throws -> [CompletedChallenge.Response] {
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let language = try getLanguage(req: req)
        
        let challenges = try await user.$completedChallenges
            .$pivots
            .query(on: req.db)
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
            .filter(\.$featured == true)
            .sort(\.$order)
            .all()
        
        return try CompletedChallenge.toResponse(challenges, lang: language)
    }
    
    @Sendable func highlightChallenge(req: Request) async throws -> HTTPStatus {
        let challengeDTO = try req.content.decode(CompletedChallengeDTO.self)
        guard let _ = try await Challenge.find(challengeDTO.challengeID, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not found")
        }
        
        guard let completedChallenge = try await CompletedChallenge
            .query(on: req.db)
            .filter(\.$challenge.$id == challengeDTO.challengeID)
            .first() else {
            throw Abort(.notFound, reason: "Challenge not completed by the user")
        }
        
        if !completedChallenge.featured {
            completedChallenge.featured = true
            completedChallenge.order = challengeDTO.order
            try await completedChallenge.update(on: req.db)
            
            return .ok
        } else {
            throw Abort(.notFound, reason: "Challenge already featured")
        }
    }
    
    @Sendable func unhighlightChallenge(req: Request) async throws -> HTTPStatus {
        guard let completedChallengeID = req.parameters.get("completedChallengeID", as: UUID.self),
              let completedChallenge = try await CompletedChallenge.find(completedChallengeID, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not completed by the user")
        }
        
        if completedChallenge.featured {
            completedChallenge.featured = false
            completedChallenge.order = nil
            try await completedChallenge.update(on: req.db)
            
            return .ok
        } else {
            throw Abort(.notFound, reason: "Challenge isn't featured")
        }
    }
    
    
}
