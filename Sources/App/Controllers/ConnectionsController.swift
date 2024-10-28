import Fluent
import Vapor

struct ConnectionsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "connections")
        
        let connections = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        connections.get("following", use: getFollowing)
        connections.get("followers", use: getFollowers)
        connections.post(":userID", use: followUser)
        connections.delete(":userID", use: unfollowUser)
    }
    
    @Sendable func getFollowing(req: Request) async throws -> [Connections.Response] {
        let user = try await getUser(req: req)
        
        let following = try await user.$following
            .$pivots
            .query(on: req.db)
            .with(\.$followed)
            .all()
                
        return try Connections.toResponse(following, type: .following)
    }
    
    @Sendable func getFollowers(req: Request) async throws -> [Connections.Response] {
        let user = try await getUser(req: req)
        
        let following = try await user.$followers
            .$pivots
            .query(on: req.db)
            .with(\.$follower)
            .all()
                
        return try Connections.toResponse(following, type: .follower)
    }
    
    @Sendable func followUser(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        guard let otherUserID = req.parameters.get("userID", as: UUID.self),
              let otherUser = try await User.find(otherUserID, on: req.db) else {
            throw Abort(.notFound, reason: "Other user not found")
        }
        
        if try await !user.$following.isAttached(to: otherUser, on: req.db) {
            try await user.$following.attach(otherUser, on: req.db)
            return .created
        } else {
            throw Abort(.notFound, reason: "Already following this user")
        }
    }
    
    @Sendable func unfollowUser(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
            
        guard let otherUserID = req.parameters.get("userID", as: UUID.self),
              let otherUser = try await User.find(otherUserID, on: req.db) else {
            throw Abort(.notFound, reason: "Other user not found")
        }

        if try await user.$following.isAttached(to: otherUser, on: req.db) {
            try await user.$following.detach(otherUser, on: req.db)
            return .ok
        } else {
            throw Abort(.notFound, reason: "Not following this user")
        }
    }
    
}
