import Fluent
import Vapor

struct BadgesController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "badges")
        
        let badges = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        badges.get(use: getBadges)
        badges.get(":userID",use: getUserFeaturedBadges)
        badges.patch("highlight", use: highlightBadge)
        badges.patch("unhighlight", ":badgeID", use: unhighlightBadge)
    }
    
    @Sendable func getBadges(req: Request) async throws -> [Badge.Response] {
        let user = try await getUser(req: req)
        
        let badges = try await user.$badges
            .$pivots
            .query(on: req.db)
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
            .sort(\.$order)
            .all()
        
        return try Badge.toResponse(badges)
    }
    
    @Sendable func getFeaturedBadges(req: Request) async throws -> [Badge.Response] {
        let user = try await getUser(req: req)
        
        let badges = try await user.$badges
            .$pivots
            .query(on: req.db)
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
            .filter(\.$featured == true)
            .sort(\.$order)
            .all()
        
        return try Badge.toResponse(badges)
    }
    
    @Sendable func getUserFeaturedBadges(req: Request) async throws -> [Badge.Response] {
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let badges = try await user.$badges
            .$pivots
            .query(on: req.db)
            .with(\.$challenge) { challenge in
                challenge.with(\.$game)
            }
            .filter(\.$featured == true)
            .sort(\.$order)
            .all()
        
        return try Badge.toResponse(badges)
    }
    
    @Sendable func highlightBadge(req: Request) async throws -> HTTPStatus {
        let badgeDTO = try req.content.decode(BadgeDTO.self)
        guard let badge = try await Badge.find(badgeDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not completed by the user")
        }
        
        if !badge.featured {
            badge.featured = true
            badge.order = badgeDTO.order
            try await badge.update(on: req.db)
            
            return .ok
        } else {
            throw Abort(.notFound, reason: "Badge already featured")
        }
    }
    
    @Sendable func unhighlightBadge(req: Request) async throws -> HTTPStatus {
        guard let badgeID = req.parameters.get("badgeID", as: UUID.self),
              let badge = try await Badge.find(badgeID, on: req.db) else {
            throw Abort(.notFound, reason: "Challenge not completed by the user")
        }
        
        if badge.featured {
            badge.featured = false
            badge.order = nil
            try await badge.update(on: req.db)
            
            return .ok
        } else {
            throw Abort(.notFound, reason: "Badge isn't featured")
        }
    }
    
    
}
