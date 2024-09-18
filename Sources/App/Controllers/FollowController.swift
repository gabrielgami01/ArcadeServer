import Fluent
import Vapor

struct FollowController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "users")
        
        let follow = api.grouped(UserPayload.authenticator(), UserPayload.guardMiddleware())
        follow.get("listFollowing", use: getFollowing)
        follow.get("listFollowers", use: getFollowers)
        follow.post("follow", use: followUser)
        follow.delete("unfollow", ":userID", use: unfollowUser)
    }
    
    @Sendable func getFollowing(req: Request) async throws -> [UserConnections.Response] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        let usersFollow = try await user.$following
            .$pivots
            .query(on: req.db)
            .with(\.$followed)
            .all()
        
        return try UserConnections.toResponse(usersFollow, type: .followed)
    }
    
    @Sendable func getFollowers(req: Request) async throws -> [UserConnections.Response] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        let usersFollow = try await user.$followers
            .$pivots
            .query(on: req.db)
            .with(\.$follower)
            .all()
        
        return try UserConnections.toResponse(usersFollow, type: .follower)
    }
    
    @Sendable func followUser(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        let connectionDTO = try req.content.decode(ConnectionDTO.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        guard let otherUser = try await User.find(connectionDTO.userID, on: req.db) else {
            throw Abort(.notFound, reason: "Other user not found")
        }

        if try await user.$following.isAttached(to: otherUser, on: req.db) {
            throw Abort(.notFound, reason: "Already following this user")
        } else {
            try await user.$following.attach(otherUser, on: req.db)
        }
        
        return .created
    }
    
    @Sendable func unfollowUser(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        guard let otherUserID = req.parameters.get("userID", as: UUID.self),
              let otherUser = try await User.find(otherUserID, on: req.db) else {
            throw Abort(.notFound, reason: "Other user not found")
        }

        if try await user.$following.isAttached(to: otherUser, on: req.db) {
            try await user.$following.detach(otherUser, on: req.db)
        } else {
            throw Abort(.notFound, reason: "Not following this user")
        }
        
        return .ok
    }
}
